package com.moemoment.app

import android.app.Activity
import app.tauri.annotation.Command
import app.tauri.annotation.InvokeArg
import app.tauri.annotation.TauriPlugin
import app.tauri.plugin.Invoke
import app.tauri.plugin.Plugin

@InvokeArg
class ScheduleArgs {
    var id: Int = 0
    var title: String? = null
    var body: String? = null
    var at: Long = 0
}

@InvokeArg
class CancelArgs {
    var id: Int = 0
}

@InvokeArg
class NotifyArgs {
    var id: Int = 0
    var title: String? = null
    var body: String? = null
}

/**
 * 系统闹钟提醒插件。
 *
 * Rust 侧通过 `run_mobile_plugin("schedule" | "cancel" | "cancelAll", payload)` 调用，
 * 真正的持久化与调度逻辑在 [ReminderStore]。
 */
@TauriPlugin
class ReminderPlugin(private val activity: Activity) : Plugin(activity) {

    @Command
    fun schedule(invoke: Invoke) {
        val args = invoke.parseArgs(ScheduleArgs::class.java)
        val now = System.currentTimeMillis()

        if (args.id <= 0) {
            invoke.reject("提醒 id 非法")
            return
        }
        if (args.at <= now) {
            // 已经过点：交给应用内的前台轮询立即补发，这里不排闹钟
            invoke.resolve()
            return
        }

        ReminderStore.schedule(
            activity.applicationContext,
            PendingReminder(
                id = args.id,
                title = args.title ?: "美瞳提醒",
                body = args.body ?: "",
                at = args.at,
            ),
        )
        invoke.resolve()
    }

    /** 立即发一条通知（应用在前台、由 Rust 侧的轮询触发时使用） */
    @Command
    fun notify(invoke: Invoke) {
        val args = invoke.parseArgs(NotifyArgs::class.java)
        NotificationHelper.show(
            activity.applicationContext,
            if (args.id > 0) args.id else System.currentTimeMillis().toInt(),
            args.title ?: "美瞳提醒",
            args.body ?: "",
        )
        invoke.resolve()
    }

    @Command
    fun cancel(invoke: Invoke) {
        val args = invoke.parseArgs(CancelArgs::class.java)
        ReminderStore.cancel(activity.applicationContext, args.id)
        invoke.resolve()
    }

    @Command
    fun cancelAll(invoke: Invoke) {
        val context = activity.applicationContext
        ReminderStore.all(context).forEach { ReminderStore.cancel(context, it.id) }
        ReminderStore.clear(context)
        invoke.resolve()
    }
}
