package ir.studypath.rahyar

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock

/** A real native loop: the Dart isolate and display do not need to stay awake. */
internal class LoopingAlarmPlayer(
    private val context: Context,
    private val onError: (String) -> Unit,
) {
    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var startMs = 0
    private var endMs = 0
    private var seeking = false
    private var seekStartedAt = 0L
    private var stopped = false

    private val clipLoop = object : Runnable {
        override fun run() {
            if (stopped) return
            try {
                val active = player
                if (seeking && SystemClock.elapsedRealtime() - seekStartedAt > 1_500L) seeking = false
                if (active != null && !seeking) {
                    val position = active.currentPosition
                    // setLooping also covers the physical end of short files, while
                    // this check repeats a selected 30-second section of a long file.
                    if (position < startMs || position >= (endMs - 80).coerceAtLeast(startMs + 1)) {
                        seeking = true
                        seekStartedAt = SystemClock.elapsedRealtime()
                        active.seekTo(startMs)
                    } else if (!active.isPlaying) {
                        active.start()
                    }
                }
            } catch (_: Exception) {
                recover()
            }
            if (!stopped) handler.postDelayed(this, 100)
        }
    }

    fun start(custom: Uri? = null, requestedStartMs: Int = 0): Boolean {
        stopped = false
        val opened = if (custom == null) openDefault() else {
            open(custom, requestedStartMs, clip = true) || run {
                openDefault()
            }
        }
        handler.post(clipLoop)
        if (!opened) {
            onError("صدای زنگ در دسترس نیست؛ صدای پیش‌فرض دستگاه را بررسی کن.")
            handler.postDelayed({ if (!stopped && player == null) recover() }, 5_000)
        }
        return opened
    }

    private fun openDefault(): Boolean {
        val candidates = listOfNotNull(
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
        ).distinct()
        return candidates.any { open(it, 0, clip = false) }
    }

    private fun open(uri: Uri, requestedStartMs: Int, clip: Boolean): Boolean {
        releasePlayer()
        val next = MediaPlayer()
        player = next
        return try {
            next.setAudioAttributes(
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build(),
            )
            next.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
            next.setDataSource(context, uri)
            next.setVolume(1f, 1f)
            next.isLooping = true
            next.setOnSeekCompleteListener { ready ->
                seeking = false
                if (!stopped && player === ready) {
                    try { if (!ready.isPlaying) ready.start() } catch (_: Exception) { recover() }
                }
            }
            next.setOnErrorListener { failed, _, _ ->
                // Release/recreate outside MediaPlayer's callback dispatch.
                handler.post { if (player === failed) recover() }
                true
            }
            next.prepare()
            val duration = next.duration.coerceAtLeast(1)
            startMs = if (clip) requestedStartMs.coerceIn(0, (duration - 1).coerceAtLeast(0)) else 0
            endMs = if (clip) (startMs + 30_000).coerceAtMost(duration) else duration
            seeking = startMs > 0
            if (seeking) { seekStartedAt = SystemClock.elapsedRealtime(); next.seekTo(startMs) }
            next.start()
            true
        } catch (_: Exception) {
            releasePlayer()
            false
        }
    }

    private fun recover() {
        if (stopped) return
        // A removed or unreadable custom recording must not silence a real alarm.
        if (openDefault()) { onError(""); return }
        onError("پخش صدای زنگ متوقف شد؛ صدای دستگاه را بررسی کن.")
        handler.postDelayed({ if (!stopped && player == null) recover() }, 5_000)
    }

    private fun releasePlayer() {
        seeking = false
        try { player?.stop() } catch (_: Exception) { }
        try { player?.release() } catch (_: Exception) { }
        player = null
    }

    fun stop() {
        stopped = true
        handler.removeCallbacksAndMessages(null)
        releasePlayer()
    }
}
