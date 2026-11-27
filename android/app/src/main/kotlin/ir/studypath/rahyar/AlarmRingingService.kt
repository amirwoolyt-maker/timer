package ir.studypath.rahyar

import android.app.Service
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.IBinder
import org.json.JSONObject
import android.net.Uri
import android.os.Handler
import android.os.Looper

class AlarmRingingService : Service() {
    private var player: LoopingAlarmPlayer? = null
    private var currentAlarmId: String? = null
    private var isPreview = false
    private val handler = Handler(Looper.getMainLooper())
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getStringExtra("alarmId") ?: AlarmScheduler.preferences(this).getString("activeAlarm", null)
        if (id == null) { stopSelf(); return START_NOT_STICKY }
        val preview = intent?.getBooleanExtra("preview", false) == true
        val prefs = AlarmScheduler.preferences(this)
        if (preview && prefs.getString("activeAlarm", null) != null) {
            prefs.edit().remove("previewAlarm").apply()
            if (currentAlarmId == null) stopSelf(startId)
            return if (isPreview) START_NOT_STICKY else START_STICKY
        }
        if (preview || currentAlarmId != id || isPreview != preview) {
            stopPlayback()
            currentAlarmId = id
            isPreview = preview
        }
        prefs.edit().remove("activeAlarmError").apply()
        if (preview) {
            prefs.edit().putString("previewAlarm", id).apply()
        } else {
            prefs.edit().putString("activeAlarm", id).remove("previewAlarm").apply()
        }
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = "rahyar_alarm"
        if (Build.VERSION.SDK_INT >= 26) {
            val notificationChannel = NotificationChannel(channel, "زنگ هوشمند راهیار", NotificationManager.IMPORTANCE_HIGH)
            notificationChannel.setSound(null, null)
            notificationChannel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            manager.createNotificationChannel(notificationChannel)
        }
        val open = PendingIntent.getActivity(this, 7, Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val record = prefs.getString("alarm:$id", "{}") ?: "{}"
        val label = if (preview) "پیش‌نمایش صدای زنگ" else try {
            JSONObject(record).optString("label", "بیدار شو!")
        } catch (_: Exception) { "بیدار شو!" }
        val notification = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channel) else Notification.Builder(this))
            .setSmallIcon(R.mipmap.ic_launcher).setContentTitle(label)
            .setContentText(if (preview) "پیش‌نمایش تا ۳۰ ثانیه پخش می‌شود." else "برای خاموش کردن زنگ، چالش را در راهیار حل کن.")
            .setCategory(if (preview) Notification.CATEGORY_SERVICE else Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(!preview).setContentIntent(open)
            .apply { if (!preview) setFullScreenIntent(open, true) }
            .build()
        startForeground(501, notification)
        if (player == null) {
            try {
                val custom = prefs.getString("sound:$id", null)
                val nextPlayer = LoopingAlarmPlayer(applicationContext) { message ->
                    prefs.edit().putString("activeAlarmError", message).apply()
                }
                player = nextPlayer
                val played = nextPlayer.start(
                    custom?.let { Uri.parse(it) },
                    prefs.getLong("soundStart:$id", 0L).coerceIn(0L, Int.MAX_VALUE.toLong()).toInt(),
                )
                if (played) prefs.edit().remove("activeAlarmError").apply()
                else if (preview) stopSelf(startId)
            } catch (error: Exception) {
                player?.stop()
                player = null
                prefs.edit().putString(
                    "activeAlarmError",
                    error.message ?: "فایل صدای زنگ پخش نشد.",
                ).apply()
                if (preview) stopSelf(startId)
            }
        }
        if (preview) {
            handler.postDelayed({
                if (isPreview && currentAlarmId == id) stopSelf(startId)
            }, 30_000)
            return START_NOT_STICKY
        }
        return START_STICKY
    }
    override fun onDestroy() {
        stopPlayback()
        if (isPreview) {
            val prefs = AlarmScheduler.preferences(this)
            if (prefs.getString("previewAlarm", null) == currentAlarmId) {
                prefs.edit().remove("previewAlarm").apply()
            }
        }
        super.onDestroy()
    }

    private fun stopPlayback() {
        handler.removeCallbacksAndMessages(null)
        player?.stop()
        player = null
    }
}
