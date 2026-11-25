package com.moemoment.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationManagerCompat

/** 系统闹钟到点后触发的广播接收器：此时应用可能不在前台，直接由系统弹通知。 */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", -1)
        if (id < 0) return

        val reminder = ReminderStore.all(context).firstOrNull { it.id == id }
        // 已触发过就清掉计划，避免下次重启被重复安排
        ReminderStore.remove(context, id)

        NotificationHelper.show(
            context,
            id,
            reminder?.title ?: "美瞳提醒",
            reminder?.body ?: "有新的到期提醒，打开应用查看详情。",
        )
    }
}

/** 设备重启后恢复未触发的提醒。 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }

        val now = System.currentTimeMillis()
        ReminderStore.all(context).forEach { reminder ->
            if (reminder.at > now) {
                ReminderStore.schedule(context, reminder)
            } else {
                ReminderStore.remove(context, reminder.id)
            }
        }
    }
}

object NotificationHelper {
    private const val CHANNEL_ID = "moemoment_reminders"
    private const val CHANNEL_NAME = "到期提醒"

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
            description = "美瞳与护理液的到期提醒"
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    fun show(context: Context, id: Int, title: String, body: String) {
        val manager = NotificationManagerCompat.from(context)
        // 用户没给通知权限时静默跳过，不抛异常
        if (!manager.areNotificationsEnabled()) return

        ensureChannel(context)

        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val contentIntent = launch?.let {
            PendingIntent.getActivity(
                context,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.mm_pink))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setGroup(CHANNEL_ID)
            .setAutoCancel(true)
            .apply { if (contentIntent != null) setContentIntent(contentIntent) }
            .build()

        try {
            manager.notify(id, notification)
        } catch (_: SecurityException) {
            // 权限在运行期被撤销
        }
    }
}
