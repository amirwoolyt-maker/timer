package ir.studypath.rahyar

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.IBinder
import org.json.JSONObject

/** One persisted deadline, independent of Flutter, process lifetime, or the screen. */
object StudyTimerScheduler {
    private const val RUNNING_NOTIFICATION = 502
    const val RINGING_NOTIFICATION = 503
    const val CURRENT = "studyTimer"
    const val RINGING = "ringingStudyTimer"

    private fun operation(context: Context) = PendingIntent.getBroadcast(
        context, 0,
        Intent(context, StudyTimerReceiver::class.java)
            .setData(Uri.parse("rahyar://study-timer/deadline")),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun save(context: Context, id: String, at: Long, title: String): Boolean {
        require(id.isNotBlank())
        if (at <= System.currentTimeMillis()) return false
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED) return false
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= 31 && !manager.canScheduleExactAlarms()) return false
        val record = JSONObject().put("id", id).put("at", at).put("title", title)
        val prefs = AlarmScheduler.preferences(context)
        val previous = prefs.getString(CURRENT, null)
        return try {
            prefs.edit().putString(CURRENT, record.toString()).commit()
            // This is an explicit, user-visible alarm-clock countdown. Unlike
            // allowWhileIdle, alarm-clock delivery is not deferred by Doze quotas.
            manager.setAlarmClock(AlarmManager.AlarmClockInfo(at, openIntent(context)), operation(context))
            try { showCountdown(context, record) } catch (_: Exception) { /* The deadline is still scheduled. */ }
            true
        } catch (_: Exception) {
            val editor = prefs.edit()
            if (previous == null) editor.remove(CURRENT) else editor.putString(CURRENT, previous)
            editor.commit()
            false
        }
    }

    private fun showCountdown(context: Context, record: JSONObject) {
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = "rahyar_study_running"
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channel, "زمان‌سنج مطالعه", NotificationManager.IMPORTANCE_LOW)
                .apply { setSound(null, null) })
        }
        val open = openIntent(context)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channel) else Notification.Builder(context)
        builder.setSmallIcon(R.mipmap.ic_launcher).setContentTitle("زمان‌سنج راهیار")
            .setContentText("زمان‌سنج با خاموش‌شدن صفحه ادامه دارد")
            .setWhen(record.getLong("at")).setUsesChronometer(true)
            .setOngoing(true).setOnlyAlertOnce(true).setContentIntent(open)
            .setCategory(Notification.CATEGORY_PROGRESS)
        if (Build.VERSION.SDK_INT >= 24) builder.setChronometerCountDown(true)
        manager.notify(RUNNING_NOTIFICATION, builder.build())
    }

    fun openIntent(context: Context): PendingIntent = PendingIntent.getActivity(
        context, 8,
        Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun cancel(context: Context, id: String, dismissRinging: Boolean = true) {
        val prefs = AlarmScheduler.preferences(context)
        val current = prefs.getString(CURRENT, null)?.let { JSONObject(it) }
        if (current?.optString("id") == id) {
            prefs.edit().remove(CURRENT).commit()
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(operation(context))
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(RUNNING_NOTIFICATION)
        }
        val ringing = prefs.getString(RINGING, null)?.let { JSONObject(it) }
        if (dismissRinging && ringing?.optString("id") == id) {
            prefs.edit().remove(RINGING).commit()
            context.stopService(Intent(context, StudyTimerRingingService::class.java))
        }
    }

    fun restore(context: Context) {
        val prefs = AlarmScheduler.preferences(context)
        val encoded = prefs.getString(CURRENT, null) ?: return
        try {
            val record = JSONObject(encoded)
            if (record.getLong("at") > System.currentTimeMillis()) {
                save(context, record.getString("id"), record.getLong("at"), record.optString("title", "مطالعه"))
            } else {
                // Do not start mediaPlayback FGS from BOOT_COMPLETED on Android 15+.
                // The persisted deadline is reconciled by Flutter on the next launch.
                prefs.edit().remove(CURRENT).apply()
            }
        } catch (_: Exception) { prefs.edit().remove(CURRENT).apply() }
    }

    fun fire(context: Context, expectedId: String? = null): Boolean {
        val prefs = AlarmScheduler.preferences(context)
        if (expectedId != null && prefs.getString(RINGING, null)?.let { JSONObject(it).optString("id") } == expectedId) return true
        val encoded = prefs.getString(CURRENT, null) ?: return false
        val record = try { JSONObject(encoded) } catch (_: Exception) { return false }
        if (expectedId != null && record.optString("id") != expectedId) return false
        // Ignore a stale broadcast delivered after a pause/resume replaced the deadline.
        if (record.optLong("at") > System.currentTimeMillis() + 1_000L) return false
        prefs.edit().remove(CURRENT).putString(RINGING, encoded).commit()
        val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notifications.cancel(RUNNING_NOTIFICATION)
        if (prefs.contains("previousFilter") && notifications.isNotificationPolicyAccessGranted) {
            try {
                notifications.setInterruptionFilter(prefs.getInt("previousFilter", NotificationManager.INTERRUPTION_FILTER_ALL))
                prefs.edit().remove("previousFilter").apply()
            } catch (_: Exception) { }
        }
        val service = Intent(context, StudyTimerRingingService::class.java)
        if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(service) else context.startService(service)
        return true
    }
}

class StudyTimerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) { StudyTimerScheduler.fire(context) }
}

class StudyTimerRingingService : Service() {
    private var player: LoopingAlarmPlayer? = null
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = AlarmScheduler.preferences(this)
        val encoded = prefs.getString(StudyTimerScheduler.RINGING, null)
        if (encoded == null) { stopSelf(); return START_NOT_STICKY }
        if (intent?.action == "stop") {
            prefs.edit().remove(StudyTimerScheduler.RINGING).commit()
            stopSelf()
            return START_NOT_STICKY
        }
        val record = try { JSONObject(encoded) } catch (_: Exception) { stopSelf(); return START_NOT_STICKY }
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = "rahyar_study_finished"
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channel, "پایان مطالعه و استراحت", NotificationManager.IMPORTANCE_HIGH)
                .apply { setSound(null, null); lockscreenVisibility = Notification.VISIBILITY_PUBLIC })
        }
        val stop = PendingIntent.getService(this, 9,
            Intent(this, StudyTimerRingingService::class.java).setAction("stop"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channel) else Notification.Builder(this)
        val notification = builder.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(record.optString("title", "زمان تمام شد"))
            .setContentText("زمان تمام شد؛ برای قطع صدا دکمهٔ زیر را بزن.")
            .setCategory(Notification.CATEGORY_ALARM).setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true).setContentIntent(StudyTimerScheduler.openIntent(this))
            .addAction(Notification.Action.Builder(null, "قطع صدا", stop).build())
            .build()
        startForeground(StudyTimerScheduler.RINGING_NOTIFICATION, notification)
        if (player == null) {
            player = LoopingAlarmPlayer(applicationContext) { message ->
                prefs.edit().putString("studyTimerError", message).apply()
            }.also { it.start() }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        player?.stop()
        player = null
        super.onDestroy()
    }
}
