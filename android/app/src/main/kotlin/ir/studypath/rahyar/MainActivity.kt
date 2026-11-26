package ir.studypath.rahyar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.MediaStore
import android.app.Activity

class MainActivity : FlutterActivity() {
    private var soundResult: MethodChannel.Result? = null
    private var soundAlarmId: String? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rahyar/platform")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "scheduleAlarm" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            result.success(AlarmScheduler.save(this, id, call.argument<Int>("hour") ?: 0,
                                call.argument<Int>("minute") ?: 0, call.argument<String>("label") ?: "راهیار"))
                        }
                        "cancelAlarm" -> {
                            AlarmScheduler.cancel(this, call.argument<String>("id") ?: "")
                            result.success(null)
                        }
                        "scheduleTask" -> {
                            result.success(TaskScheduler.save(this, call.argument<String>("id") ?: error("Missing task ID"), call.argument<String>("title") ?: "راهیار", call.argument<String>("body") ?: "", call.argument<Number>("at")?.toLong() ?: 0L))
                        }
                        "cancelTask" -> {
                            TaskScheduler.cancel(this, call.argument<String>("id") ?: "")
                            result.success(null)
                        }
                        "pendingAlarmId" -> result.success(AlarmScheduler.preferences(this).getString("activeAlarm", null))
                        "stopAlarm" -> {
                            val id = call.argument<String>("id")
                            val prefs = AlarmScheduler.preferences(this)
                            if (prefs.getString("activeAlarm", null) == id) {
                                stopService(Intent(this, AlarmRingingService::class.java))
                                prefs.edit().remove("activeAlarm").apply()
                            }
                            result.success(null)
                        }
                        "requestAlarmPermissions" -> {
                            if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 410)
                            }
                            val manager = getSystemService(ALARM_SERVICE) as AlarmManager
                            val exact = Build.VERSION.SDK_INT < 31 || manager.canScheduleExactAlarms()
                            if (!exact) startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")))
                            result.success(exact)
                        }
                        "setFocusMode" -> {
                            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                            if (manager.isNotificationPolicyAccessGranted) {
                                val prefs = AlarmScheduler.preferences(this)
                                if (call.argument<Boolean>("enabled") == true) {
                                    if (!prefs.contains("previousFilter")) prefs.edit().putInt("previousFilter", manager.currentInterruptionFilter).apply()
                                    manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                                } else if (prefs.contains("previousFilter")) {
                                    manager.setInterruptionFilter(prefs.getInt("previousFilter", NotificationManager.INTERRUPTION_FILTER_ALL))
                                    prefs.edit().remove("previousFilter").apply()
                                }
                                result.success(true)
                            } else result.success(false)
                        }
                        "requestFocusPermission" -> {
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                            result.success(null)
                        }
                        "pickAlarmSound" -> {
                            if (soundResult != null) { result.error("PICKER_BUSY", "A sound picker is already open", null); return@setMethodCallHandler }
                            val record = call.argument<Boolean>("record") == true
                            val picker = if (record) Intent(MediaStore.Audio.Media.RECORD_SOUND_ACTION).putExtra(MediaStore.EXTRA_DURATION_LIMIT, 30)
                                else Intent(Intent.ACTION_OPEN_DOCUMENT).setType("audio/*").addCategory(Intent.CATEGORY_OPENABLE)
                            if (picker.resolveActivity(packageManager) == null) {
                                result.error("PICKER_UNAVAILABLE", "No audio recorder or file picker is installed", null)
                            } else {
                                soundResult = result
                                soundAlarmId = call.argument<String>("id")
                                startActivityForResult(picker, 411)
                            }
                        }
                        "resetAlarmSound" -> {
                            AlarmScheduler.preferences(this).edit().remove("sound:${call.argument<String>("id")}").apply()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_SERVICE", e.message, null)
                }
            }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 411) {
            val uri = data?.data
            if (resultCode == Activity.RESULT_OK && uri != null) {
                try { contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) } catch (_: Exception) { }
                try {
                    val target = java.io.File(filesDir, "alarm-sound-${soundAlarmId}.audio")
                    contentResolver.openInputStream(uri).use { input ->
                        requireNotNull(input)
                        target.outputStream().use { output -> input.copyTo(output) }
                    }
                    soundAlarmId?.let { AlarmScheduler.preferences(this).edit().putString("sound:$it", Uri.fromFile(target).toString()).apply() }
                    soundResult?.success(target.name)
                } catch (e: Exception) { soundResult?.error("SOUND_IMPORT", "Could not save selected audio", null) }
            } else soundResult?.success(null)
            soundResult = null; soundAlarmId = null
        }
    }
}
