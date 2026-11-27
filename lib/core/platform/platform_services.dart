import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native Android bridge. Web/iOS never pretend to support background alarms.
abstract final class PlatformServices {
  static const _channel = MethodChannel('rahyar/platform');
  static bool get supportsBackgroundAlarms =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!supportsBackgroundAlarms) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('Platform service $method: ${error.code}');
      return null;
    }
  }

  static Future<bool> scheduleAlarm(
    String id,
    int hour,
    int minute,
    String label,
  ) async =>
      await _invoke<bool>('scheduleAlarm', {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
      }) ??
      false;
  static Future<void> cancelAlarm(String id) async =>
      _invoke<void>('cancelAlarm', {'id': id});
  static Future<void> unscheduleAlarm(String id) async =>
      _invoke<void>('unscheduleAlarm', {'id': id});
  static Future<String?> pendingAlarmId() => _invoke<String>('pendingAlarmId');
  static Future<String?> pendingAlarmError() =>
      _invoke<String>('pendingAlarmError');
  static Future<void> stopAlarm(String id) async =>
      _invoke<void>('stopAlarm', {'id': id});
  static Future<bool> startAlarmPreview(String id) async =>
      await _invoke<bool>('startAlarmPreview', {'id': id}) ?? false;
  static Future<bool> startAlarmChallenge(String id) async =>
      await _invoke<bool>('startAlarmChallenge', {'id': id}) ?? false;
  static Future<void> stopAlarmPreview(String id) async =>
      _invoke<void>('stopAlarmPreview', {'id': id});
  static Future<bool> requestAlarmPermissions() async =>
      await _invoke<bool>('requestAlarmPermissions') ?? false;
  static Future<bool> requestTimerPermissions() async =>
      await _invoke<bool>('requestTimerPermissions') ?? false;
  static Future<bool> scheduleStudyTimer(
    String id,
    DateTime deadline, {
    required String title,
  }) async =>
      await _invoke<bool>('scheduleStudyTimer', {
        'id': id,
        'at': deadline.millisecondsSinceEpoch,
        'title': title,
      }) ??
      false;
  static Future<void> cancelStudyTimer(
    String id, {
    bool dismissRinging = true,
  }) async => _invoke<void>('cancelStudyTimer', {
    'id': id,
    'dismissRinging': dismissRinging,
  });
  static Future<bool> completeStudyTimer(String id) async =>
      await _invoke<bool>('completeStudyTimer', {'id': id}) ?? false;
  static Future<String?> pendingStudyTimerId() =>
      _invoke<String>('pendingStudyTimerId');
  static Future<bool> setFocusMode(bool enabled) async =>
      await _invoke<bool>('setFocusMode', {'enabled': enabled}) ?? false;
  static Future<void> requestFocusPermission() async =>
      _invoke<void>('requestFocusPermission');
  static Future<String?> pickAlarmSound(
    String alarmId, {
    bool record = false,
  }) => _invoke<String>('pickAlarmSound', {'id': alarmId, 'record': record});
  static Future<void> resetAlarmSound(String id) async =>
      _invoke<void>('resetAlarmSound', {'id': id});
  static Future<bool> finishAlarmSoundEdit(
    String id, {
    required bool commit,
  }) async =>
      await _invoke<bool>('finishAlarmSoundEdit', {
        'id': id,
        'commit': commit,
      }) ??
      false;
  static Future<int?> alarmSoundDuration(String id) =>
      _invoke<int>('alarmSoundDuration', {'id': id});
  static Future<bool> setAlarmSoundStart(String id, int milliseconds) async =>
      await _invoke<bool>('setAlarmSoundStart', {
        'id': id,
        'milliseconds': milliseconds,
      }) ??
      false;
  static Future<bool> scheduleTask(
    String id,
    String title,
    DateTime dueAt, {
    String body = '',
  }) async =>
      await _invoke<bool>('scheduleTask', {
        'id': id,
        'title': title,
        'body': body,
        'at': dueAt.millisecondsSinceEpoch,
      }) ??
      false;
  static Future<void> cancelTask(String id) async =>
      _invoke<void>('cancelTask', {'id': id});
}
