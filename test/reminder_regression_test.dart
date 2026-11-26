import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/platform/task_reminders.dart';
import 'package:rahyar/core/utils/alarm_challenge.dart';
import 'package:rahyar/data/local/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('persisted alarm cooldown survives recreation and expires', () {
    final now = DateTime(2026, 11, 26, 8);
    final deadline = now.add(const Duration(seconds: 30)).toIso8601String();
    expect(remainingAlarmCooldown(deadline, now), 30);
    expect(
      remainingAlarmCooldown(deadline, now.add(const Duration(seconds: 12))),
      18,
    );
    expect(
      remainingAlarmCooldown(deadline, now.add(const Duration(seconds: 31))),
      0,
    );
    expect(remainingAlarmCooldown('broken', now), 0);
  });
  test('trash restore cannot bypass the fifteen note limit', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    for (var i = 0; i < 16; i++) {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              id: '$i',
              body: '$i',
              updatedAt: DateTime.now(),
            ),
          );
    }
    await db.softDeleteNote('15');
    await expectLater(db.restoreNote('15'), throwsStateError);
    expect(await db.watchActiveNotes().first, hasLength(15));
    await db.softDeleteNote('14');
    expect(await db.restoreNote('15'), 1);
    expect(await db.watchActiveNotes().first, hasLength(15));
  });
  test(
    'denied reminder permission never schedules a misleading alarm',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('rahyar/platform');
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            methods.add(call.method);
            return call.method != 'requestAlarmPermissions';
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final task = Task(
        id: 'reminder',
        title: 'مطالعه',
        description: '',
        category: 'درسی',
        priority: 'متوسط',
        completed: false,
        dueAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
      );
      expect(
        await TaskReminders.sync(task, requestPermission: true),
        ReminderResult.permissionDenied,
      );
      expect(methods, ['requestAlarmPermissions']);
    },
  );
}
