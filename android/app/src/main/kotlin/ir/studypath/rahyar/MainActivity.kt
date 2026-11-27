package ir.studypath.rahyar

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var soundResult: MethodChannel.Result? = null
    private var soundAlarmId: String? = null
    private var alarmPermissionResult: MethodChannel.Result? = null
    private var alarmNeedsFullScreen = true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        for ((key, _) in AlarmScheduler.preferences(this).all) {
            if (key.startsWith("soundEdit:")) AlarmScheduler.finishSoundEdit(this, key.removePrefix("soundEdit:"), false)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rahyar/platform")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "scheduleAlarm" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            result.success(
                                AlarmScheduler.save(
                                    this,
                                    id,
                                    call.argument<Int>("hour") ?: 0,
                                    call.argument<Int>("minute") ?: 0,
                                    call.argument<String>("label") ?: "راهیار",
                                ),
                            )
                        }
                        "cancelAlarm" -> {
                            val id = call.argument<String>("id") ?: ""
                            AlarmScheduler.cancel(this, id)
                            result.success(null)
                        }
                        "unscheduleAlarm" -> {
                            val id = call.argument<String>("id") ?: ""
                            AlarmScheduler.unschedule(this, id)
                            result.success(null)
                        }
                        "scheduleTask" -> result.success(
                            TaskScheduler.save(
                                this,
                                call.argument<String>("id") ?: error("Missing task ID"),
                                call.argument<String>("title") ?: "راهیار",
                                call.argument<String>("body") ?: "",
                                call.argument<Number>("at")?.toLong() ?: 0L,
                            ),
                        )
                        "cancelTask" -> {
                            TaskScheduler.cancel(this, call.argument<String>("id") ?: "")
                            result.success(null)
                        }
                        "scheduleStudyTimer" -> result.success(
                            StudyTimerScheduler.save(
                                this,
                                call.argument<String>("id") ?: error("Missing timer ID"),
                                call.argument<Number>("at")?.toLong() ?: 0L,
                                call.argument<String>("title") ?: "زمان مطالعه تمام شد",
                            ),
                        )
                        "cancelStudyTimer" -> {
                            StudyTimerScheduler.cancel(this, call.argument<String>("id") ?: "", call.argument<Boolean>("dismissRinging") != false)
                            result.success(null)
                        }
                        "completeStudyTimer" -> result.success(
                            StudyTimerScheduler.fire(this, call.argument<String>("id") ?: ""),
                        )
                        "pendingStudyTimerId" -> result.success(
                            AlarmScheduler.preferences(this).getString(StudyTimerScheduler.RINGING, null)
                                ?.let { org.json.JSONObject(it).optString("id") },
                        )
                        "pendingAlarmId" -> result.success(
                            AlarmScheduler.preferences(this).getString("activeAlarm", null),
                        )
                        "pendingAlarmError" -> result.success(
                            AlarmScheduler.preferences(this).getString("activeAlarmError", null),
                        )
                        "stopAlarm" -> {
                            val id = call.argument<String>("id")
                            val prefs = AlarmScheduler.preferences(this)
                            val activeAlarm = prefs.getString("activeAlarm", null)
                            val previewAlarm = prefs.getString("previewAlarm", null)
                            if (activeAlarm == id || previewAlarm == id) {
                                val editor = prefs.edit().remove("activeAlarmError")
                                if (activeAlarm == id) editor.remove("activeAlarm")
                                if (previewAlarm == id) editor.remove("previewAlarm")
                                // Clear the sticky restart marker before stopping the service.
                                editor.commit()
                                stopService(Intent(this, AlarmRingingService::class.java))
                            }
                            result.success(null)
                        }
                        "stopAlarmPreview" -> {
                            val id = call.argument<String>("id")
                            val prefs = AlarmScheduler.preferences(this)
                            if (prefs.getString("previewAlarm", null) == id) {
                                stopService(Intent(this, AlarmRingingService::class.java))
                                prefs.edit().remove("previewAlarm").apply()
                            }
                            result.success(null)
                        }
                        "startAlarmPreview" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            val prefs = AlarmScheduler.preferences(this)
                            if (prefs.getString("activeAlarm", null) != null) {
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            prefs.edit().putString("previewAlarm", id)
                                .remove("activeAlarmError").apply()
                            val intent = Intent(this, AlarmRingingService::class.java)
                                .putExtra("alarmId", id).putExtra("preview", true)
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent)
                            else startService(intent)
                            result.success(true)
                        }
                        "startAlarmChallenge" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            val prefs = AlarmScheduler.preferences(this)
                            val active = prefs.getString("activeAlarm", null)
                            if (active != null && active != id) {
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            // A challenge is a real, unlimited alarm, even when started
                            // with the test button. Only sound-file previews expire.
                            prefs.edit().putString("activeAlarm", id).remove("previewAlarm")
                                .remove("activeAlarmError").commit()
                            val intent = Intent(this, AlarmRingingService::class.java)
                                .putExtra("alarmId", id).putExtra("preview", false)
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent)
                            else startService(intent)
                            result.success(true)
                        }
                        "requestAlarmPermissions" -> requestAlarmPermissions(result)
                        "requestTimerPermissions" -> requestAlarmPermissions(result, fullScreen = false)
                        "setFocusMode" -> {
                            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                            if (manager.isNotificationPolicyAccessGranted) {
                                val prefs = AlarmScheduler.preferences(this)
                                if (call.argument<Boolean>("enabled") == true) {
                                    if (!prefs.contains("previousFilter")) {
                                        prefs.edit().putInt("previousFilter", manager.currentInterruptionFilter).apply()
                                    }
                                    manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                                } else if (prefs.contains("previousFilter")) {
                                    manager.setInterruptionFilter(
                                        prefs.getInt("previousFilter", NotificationManager.INTERRUPTION_FILTER_ALL),
                                    )
                                    prefs.edit().remove("previousFilter").apply()
                                }
                                result.success(true)
                            } else result.success(false)
                        }
                        "requestFocusPermission" -> {
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                            result.success(null)
                        }
                        "pickAlarmSound" -> pickAlarmSound(call.argument<String>("id"), call.argument<Boolean>("record") == true, result)
                        "alarmSoundDuration" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            result.success(AlarmScheduler.preferences(this).getLong("soundDuration:$id", 0L).toInt())
                        }
                        "setAlarmSoundStart" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            val prefs = AlarmScheduler.preferences(this)
                            val duration = prefs.getLong("soundDuration:$id", 0L)
                            val requested = call.argument<Number>("milliseconds")?.toLong() ?: 0L
                            val maximum = (duration - 30_000L).coerceAtLeast(0L)
                            prefs.edit().putLong("soundStart:$id", requested.coerceIn(0L, maximum)).apply()
                            result.success(duration > 0)
                        }
                        "finishAlarmSoundEdit" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            AlarmScheduler.finishSoundEdit(this, id, call.argument<Boolean>("commit") == true)
                            result.success(true)
                        }
                        "resetAlarmSound" -> {
                            val id = call.argument<String>("id") ?: error("Missing alarm ID")
                            AlarmScheduler.clearSound(this, id)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("NATIVE_SERVICE", error.message, null)
                }
            }
    }

    private fun requestAlarmPermissions(result: MethodChannel.Result, fullScreen: Boolean = true) {
        if (alarmPermissionResult != null) {
            result.error("PERMISSION_FLOW_BUSY", "Alarm permission request already in progress", null)
            return
        }
        alarmPermissionResult = result
        alarmNeedsFullScreen = fullScreen
        continueAlarmPermissionFlow()
    }

    private fun continueAlarmPermissionFlow() {
        val result = alarmPermissionResult ?: return
        try {
            if (Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 410)
                return
            }
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT >= 31 && !alarmManager.canScheduleExactAlarms()) {
                startActivityForResult(
                    Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")),
                    412,
                )
                return
            }
            if (alarmNeedsFullScreen && Build.VERSION.SDK_INT >= 34) {
                val notifications = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                if (!notifications.canUseFullScreenIntent()) {
                    startActivityForResult(
                        Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$packageName")),
                        413,
                    )
                    return
                }
            }
            alarmPermissionResult = null
            result.success(true)
        } catch (error: Exception) {
            alarmPermissionResult = null
            result.error("ALARM_PERMISSION", error.message, null)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 410) return
        if (grantResults.firstOrNull() == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            continueAlarmPermissionFlow()
        } else {
            alarmPermissionResult?.success(false)
            alarmPermissionResult = null
        }
    }

    private fun pickAlarmSound(id: String?, record: Boolean, result: MethodChannel.Result) {
        if (id.isNullOrBlank()) error("Missing alarm ID")
        if (soundResult != null) {
            result.error("PICKER_BUSY", "A sound picker is already open", null)
            return
        }
        val picker = if (record) {
            Intent(MediaStore.Audio.Media.RECORD_SOUND_ACTION)
                .putExtra(MediaStore.EXTRA_DURATION_LIMIT, 30)
        } else {
            Intent(Intent.ACTION_OPEN_DOCUMENT).setType("audio/*")
                .addCategory(Intent.CATEGORY_OPENABLE)
        }
        if (picker.resolveActivity(packageManager) == null) {
            result.error("PICKER_UNAVAILABLE", "No audio recorder or file picker is installed", null)
            return
        }
        soundResult = result
        soundAlarmId = id
        startActivityForResult(picker, 411)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 412 || requestCode == 413) {
            val granted = if (requestCode == 412) {
                Build.VERSION.SDK_INT < 31 ||
                    (getSystemService(ALARM_SERVICE) as AlarmManager).canScheduleExactAlarms()
            } else {
                Build.VERSION.SDK_INT < 34 ||
                    (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).canUseFullScreenIntent()
            }
            if (!granted) {
                alarmPermissionResult?.success(false)
                alarmPermissionResult = null
                return
            }
            continueAlarmPermissionFlow()
            return
        }
        if (requestCode != 411) return
        val uri = data?.data
        if (resultCode == Activity.RESULT_OK && uri != null) {
            var importedFile: File? = null
            try {
                try { contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
                catch (_: Exception) { /* Some recorder apps return a temporary content URI. */ }
                val id = requireNotNull(soundAlarmId)
                AlarmScheduler.finishSoundEdit(this, id, false)
                val target = File.createTempFile("alarm-sound-", ".audio", filesDir)
                importedFile = target
                contentResolver.openInputStream(uri).use { input ->
                    requireNotNull(input) { "Selected recording could not be opened" }
                    target.outputStream().use { output -> input.copyTo(output) }
                }
                val metadata = MediaMetadataRetriever()
                val duration = try {
                    metadata.setDataSource(this, Uri.fromFile(target))
                    metadata.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
                } finally {
                    metadata.release()
                }
                if (duration <= 0L) error("Selected audio has no readable duration")
                val prefs = AlarmScheduler.preferences(this)
                prefs.edit()
                    .putBoolean("soundEdit:$id", true)
                    .putString("previousSound:$id", prefs.getString("sound:$id", null))
                    .putLong("previousDuration:$id", prefs.getLong("soundDuration:$id", 30_000L))
                    .putLong("previousStart:$id", prefs.getLong("soundStart:$id", 0L))
                    .putString("sound:$id", Uri.fromFile(target).toString())
                    .putLong("soundDuration:$id", duration)
                    .putLong("soundStart:$id", 0L)
                    .remove("activeAlarmError")
                    .apply()
                soundResult?.success(target.name)
            } catch (error: Exception) {
                importedFile?.delete()
                soundResult?.error("SOUND_IMPORT", error.message ?: "Could not save selected audio", null)
            }
        } else {
            soundResult?.success(null)
        }
        soundResult = null
        soundAlarmId = null
    }
}
