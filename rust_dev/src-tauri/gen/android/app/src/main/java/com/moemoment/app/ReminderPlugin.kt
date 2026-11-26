package com.moemoment.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
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
class InstallApkArgs {
    var path: String? = null
}

@InvokeArg
class ShareFileArgs {
    var path: String? = null
    var mime: String? = null
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

    /**
     * 拉起系统安装器安装已下载的 APK。
     * Android 8+ 要求本应用持有「安装未知应用」授权，系统会自动引导用户去开。
     */
    @Command
    fun installApk(invoke: Invoke) {
        val args = invoke.parseArgs(InstallApkArgs::class.java)
        val context = activity.applicationContext
        try {
            val raw = args.path ?: throw IllegalArgumentException("缺少 APK 路径")
            val file = java.io.File(raw)
            if (!file.exists() || file.length() == 0L) {
                throw IllegalArgumentException("安装包不存在或为空：${file.name}")
            }
            val uri: Uri = if (android.os.Build.VERSION.SDK_INT >= 24) {
                FileProvider.getUriForFile(context, context.packageName + ".fileprovider", file)
            } else {
                Uri.fromFile(file)
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                        or Intent.FLAG_ACTIVITY_NEW_TASK
                )
            }
            context.startActivity(intent)
            invoke.resolve()
        } catch (err: Exception) {
            invoke.reject(err.message ?: "无法启动安装程序")
        }
    }

    /** 把导出的备份文件交给系统分享面板（微信 / QQ / 保存到文件等）。 */
    @Command
    fun shareFile(invoke: Invoke) {
        val args = invoke.parseArgs(ShareFileArgs::class.java)
        val context = activity.applicationContext
        try {
            val raw = args.path ?: throw IllegalArgumentException("缺少文件路径")
            val file = java.io.File(raw)
            if (!file.exists()) {
                throw IllegalArgumentException("文件不存在：${file.name}")
            }
            val uri: Uri = if (android.os.Build.VERSION.SDK_INT >= 24) {
                FileProvider.getUriForFile(context, context.packageName + ".fileprovider", file)
            } else {
                Uri.fromFile(file)
            }
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = args.mime ?: "application/zip"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(intent, "分享备份文件"))
            invoke.resolve()
        } catch (err: Exception) {
            invoke.reject(err.message ?: "无法打开分享面板")
        }
    }

    @Command
    fun cancelAll(invoke: Invoke) {
        val context = activity.applicationContext
        ReminderStore.all(context).forEach { ReminderStore.cancel(context, it.id) }
        ReminderStore.clear(context)
        invoke.resolve()
    }
}
