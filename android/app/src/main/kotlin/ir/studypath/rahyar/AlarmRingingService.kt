package ir.studypath.rahyar

import android.app.Service
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import org.json.JSONObject
import android.net.Uri
import android.os.Handler
import android.os.Looper

class AlarmRingingService : Service() {
    private var player: MediaPlayer? = null
    private var currentAlarmId: String? = null
    private var isPreview = false
    private var clipStartMs = 0
    private var clipEndMs = 30_000
    private val handler = Handler(Looper.getMainLooper())
    private val clipLoop = object : Runnable {
        override fun run() {
            try {
                val active = player
                if (active != null && active.isPlaying && active.currentPosition >= clipEndMs - 100) {
                    active.seekTo(clipStartMs)
                    if (!active.isPlaying) active.start()
                }
            } catch (_: Exception) { }
            handler.postDelayed(this, 250)
        }
    }
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
                val uri = custom?.let { Uri.parse(it) } ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: error("No alarm tone is available on this device")
                clipStartMs = prefs.getLong("soundStart:$id", 0L).toInt().coerceAtLeast(0)
                val duration = prefs.getLong("soundDuration:$id", 30_000L).toInt().coerceAtLeast(1)
                clipStartMs = clipStartMs.coerceAtMost((duration - 1).coerceAtLeast(0))
                clipEndMs = (clipStartMs + 30_000).coerceAtMost(duration).coerceAtLeast(clipStartMs + 1)
                val nextPlayer = MediaPlayer()
                player = nextPlayer
                nextPlayer.apply {
                    setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
                    setDataSource(applicationContext, uri)
                    setVolume(1f, 1f)
                    isLooping = false
                    setWakeMode(applicationContext, android.os.PowerManager.PARTIAL_WAKE_LOCK)
                    setOnCompletionListener { completed ->
                        try {
                            completed.seekTo(clipStartMs)
                            completed.start()
                        } catch (_: Exception) { }
                    }
                    setOnErrorListener { _, what, extra ->
                        prefs.edit().putString("activeAlarmError", "صدای زنگ پخش نشد ($what/$extra)").apply()
                        if (isPreview) stopSelf(startId)
                        true
                    }
                    prepare()
                    seekTo(clipStartMs)
                    start()
                }
                prefs.edit().remove("activeAlarmError").apply()
                handler.post(clipLoop)
            } catch (error: Exception) {
                player?.release()
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
        try { player?.stop() } catch (_: Exception) { }
        player?.release()
        player = null
    }
}
