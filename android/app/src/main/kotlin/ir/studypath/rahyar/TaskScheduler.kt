package ir.studypath.rahyar

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import org.json.JSONObject

object TaskScheduler {
    private fun pending(context: Context, id: String) = PendingIntent.getBroadcast(context, 0,
        Intent(context, TaskReminderReceiver::class.java).setData(Uri.parse("rahyar://task/$id")).putExtra("taskId", id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun save(context: Context, id: String, title: String, body: String, at: Long): Boolean {
        cancel(context, id)
        if (at <= System.currentTimeMillis()) return false
        val record = JSONObject().put("id", id).put("title", title).put("body", body).put("at", at)
        AlarmScheduler.preferences(context).edit().putString("task:$id", record.toString()).apply()
        schedule(context, record)
        return true
    }
    private fun schedule(context: Context, record: JSONObject) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val at = record.getLong("at")
        if (at <= System.currentTimeMillis()) return
        if (Build.VERSION.SDK_INT < 31 || manager.canScheduleExactAlarms()) manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context, record.getString("id")))
        else manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context, record.getString("id")))
    }
    fun cancel(context: Context, id: String) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pending(context, id))
        AlarmScheduler.preferences(context).edit().remove("task:$id").apply()
    }
    fun restore(context: Context) {
        for ((key, value) in AlarmScheduler.preferences(context).all) if (key.startsWith("task:") && value is String) {
            try { schedule(context, JSONObject(value)) } catch (_: Exception) { }
        }
    }
}

class TaskReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("taskId") ?: return
        val encoded = AlarmScheduler.preferences(context).getString("task:$id", null) ?: return
        val task = JSONObject(encoded)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) return
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel("rahyar_tasks", "یادآوری کارها", NotificationManager.IMPORTANCE_HIGH))
        val open = PendingIntent.getActivity(context, id.hashCode(), Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notice = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, "rahyar_tasks") else Notification.Builder(context))
            .setSmallIcon(R.mipmap.ic_launcher).setContentTitle(task.getString("title"))
            .setContentText(task.optString("body", "زمان انجام کار رسیده است"))
            .setAutoCancel(true).setContentIntent(open).setCategory(Notification.CATEGORY_REMINDER).build()
        manager.notify(id.hashCode(), notice)
        TaskScheduler.cancel(context, id)
    }
}
