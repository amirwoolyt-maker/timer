package ir.studypath.rahyar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import org.json.JSONObject
import java.util.Calendar

object AlarmScheduler {
    fun preferences(context: Context) = context.getSharedPreferences("rahyar_alarms", Context.MODE_PRIVATE)

    private fun pending(context: Context, id: String) = PendingIntent.getBroadcast(context, 0,
        Intent(context, AlarmReceiver::class.java).setData(Uri.parse("rahyar://alarm/$id")).putExtra("alarmId", id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    fun save(context: Context, id: String, hour: Int, minute: Int, label: String): Boolean {
        require(id.isNotBlank() && hour in 0..23 && minute in 0..59)
        val prefs = preferences(context)
        val key = "alarm:$id"
        val previous = prefs.getString(key, null)
        val record = JSONObject().put("id", id).put("hour", hour).put("minute", minute).put("label", label)
        prefs.edit().putString(key, record.toString()).apply()
        val scheduled = try { schedule(context, record) } catch (_: Exception) { false }
        if (scheduled) return true
        val rollback = prefs.edit()
        if (previous == null) rollback.remove(key) else rollback.putString(key, previous)
        rollback.apply()
        return false
    }

    fun schedule(context: Context, record: JSONObject): Boolean {
        val id = record.getString("id")
        val whenToRing = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, record.getInt("hour")); set(Calendar.MINUTE, record.getInt("minute"))
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DATE, 1)
        }.timeInMillis
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val operation = pending(context, id)
        val exact = Build.VERSION.SDK_INT < 31 || manager.canScheduleExactAlarms()
        if (!exact) return false
        val show = PendingIntent.getActivity(
            context,
            id.hashCode(),
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        manager.setAlarmClock(AlarmManager.AlarmClockInfo(whenToRing, show), operation)
        return true
    }

    fun cancel(context: Context, id: String) {
        unschedule(context, id)
        clearSound(context, id)
    }

    fun unschedule(context: Context, id: String) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pending(context, id))
        preferences(context).edit().remove("alarm:$id").apply()
    }

    fun clearSound(context: Context, id: String) {
        val prefs = preferences(context)
        val soundName = prefs.getString("sound:$id", null)
        if (!soundName.isNullOrBlank()) {
            val uri = Uri.parse(soundName)
            val file = if (uri.scheme == "file") {
                uri.path?.let { java.io.File(it) }
            } else if (!soundName.contains('/') && !soundName.contains('\\')) {
                context.getFileStreamPath(soundName)
            } else null
            if (file != null && file.canonicalFile.parentFile == context.filesDir.canonicalFile) {
                file.delete()
            }
        }
        prefs.edit()
            .remove("sound:$id")
            .remove("soundDuration:$id")
            .remove("soundStart:$id")
            .apply()
    }

    fun restore(context: Context) {
        for ((key, value) in preferences(context).all) {
            if (key.startsWith("alarm:") && value is String) {
                try { schedule(context, JSONObject(value)) } catch (_: Exception) { }
            }
        }
    }
}
