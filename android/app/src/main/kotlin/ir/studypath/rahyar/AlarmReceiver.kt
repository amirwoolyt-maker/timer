package ir.studypath.rahyar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("alarmId") ?: return
        val record = AlarmScheduler.preferences(context).getString("alarm:$id", null) ?: return
        AlarmScheduler.preferences(context).edit().putString("activeAlarm", id).apply()
        val service = Intent(context, AlarmRingingService::class.java).putExtra("alarmId", id)
        if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(service) else context.startService(service)
        AlarmScheduler.schedule(context, JSONObject(record))
    }
}

class AlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            AlarmScheduler.restore(context)
            TaskScheduler.restore(context)
        }
    }
}
