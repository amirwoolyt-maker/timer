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
    private val handler = Handler(Looper.getMainLooper())
    private val clipLoop = object : Runnable {
        override fun run() {
            try { if ((player?.currentPosition ?: 0) >= 30000) player?.seekTo(0) } catch (_: Exception) { }
            handler.postDelayed(this, 200)
        }
    }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getStringExtra("alarmId") ?: AlarmScheduler.preferences(this).getString("activeAlarm", null)
        if (id == null) { stopSelf(); return START_NOT_STICKY }
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
        val record = AlarmScheduler.preferences(this).getString("alarm:$id", "{}") ?: "{}"
        val label = try { JSONObject(record).optString("label", "بیدار شو!") } catch (_: Exception) { "بیدار شو!" }
        val notification = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channel) else Notification.Builder(this))
            .setSmallIcon(R.mipmap.ic_launcher).setContentTitle(label)
            .setContentText("برای خاموش کردن زنگ، چالش را در راهیار حل کن.")
            .setCategory(Notification.CATEGORY_ALARM).setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true).setContentIntent(open).setFullScreenIntent(open, true).build()
        startForeground(501, notification)
        if (player == null) {
            try {
                val custom = AlarmScheduler.preferences(this).getString("sound:$id", null)
                val uri = custom?.let { Uri.parse(it) } ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                player = MediaPlayer().apply {
                    setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
                    setDataSource(applicationContext, uri)
                    isLooping = true
                    setWakeMode(applicationContext, android.os.PowerManager.PARTIAL_WAKE_LOCK)
                    prepare(); start()
                }
                handler.post(clipLoop)
            } catch (_: Exception) { player?.release(); player = null }
        }
        return START_STICKY
    }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        player?.stop(); player?.release(); player = null
        super.onDestroy()
    }
}
