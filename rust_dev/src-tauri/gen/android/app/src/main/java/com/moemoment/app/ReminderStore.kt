package com.moemoment.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

/** 一条待触发的提醒 */
data class PendingReminder(
    val id: Int,
    val title: String,
    val body: String,
    /** 触发时刻（UTC 毫秒） */
    val at: Long,
)

/**
 * 提醒的持久化与系统闹钟调度。
 *
 * 计划同时写入 SharedPreferences，设备重启后由 [BootReceiver] 恢复，
 * 不依赖应用先被打开一次。
 */
object ReminderStore {
    private const val PREFS = "mm_reminders"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(context: Context, reminder: PendingReminder) {
        val json = JSONObject().apply {
            put("id", reminder.id)
            put("title", reminder.title)
            put("body", reminder.body)
            put("at", reminder.at)
        }
        prefs(context).edit().putString(reminder.id.toString(), json.toString()).apply()
    }

    fun remove(context: Context, id: Int) {
        prefs(context).edit().remove(id.toString()).apply()
    }

    fun clear(context: Context) {
        prefs(context).edit().clear().apply()
    }

    fun all(context: Context): List<PendingReminder> =
        prefs(context).all.values.mapNotNull { raw ->
            runCatching {
                val json = JSONObject(raw as String)
                PendingReminder(
                    id = json.getInt("id"),
                    title = json.optString("title"),
                    body = json.optString("body"),
                    at = json.getLong("at"),
                )
            }.getOrNull()
        }

    private fun broadcast(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra("id", id)
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** 交给系统闹钟。缺少「精确闹钟」权限时退化为非精确调度，不抛异常。 */
    fun schedule(context: Context, reminder: PendingReminder) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = broadcast(context, reminder.id)
        val exactAllowed =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) manager.canScheduleExactAlarms() else true

        try {
            if (exactAllowed) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, reminder.at, pending)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, reminder.at, pending)
            }
        } catch (_: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, reminder.at, pending)
        }

        save(context, reminder)
    }

    fun cancel(context: Context, id: Int) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(broadcast(context, id))
        remove(context, id)
    }
}
