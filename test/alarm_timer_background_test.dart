// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/theme/app_theme.dart';
import 'package:rahyar/core/utils/study_clock.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/features/feature_pages.dart';

Future<void> waitUntil(bool Function() done) async {
  for (var attempt = 0; attempt < 100 && !done(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(
    done(),
    isTrue,
    reason: 'The asynchronous timer operation did not finish.',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rahyar/platform');
  final calls = <MethodCall>[];
  var allowSchedule = true;
  var nativeCompletion = false;
  String? ringingTimer;
  setUp(() {
    calls.clear();
    allowSchedule = true;
    nativeCompletion = false;
    ringingTimer = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'completeStudyTimer') {
            if (nativeCompletion) ringingTimer = call.arguments['id'] as String;
            return nativeCompletion;
          }
          if (call.method == 'pendingStudyTimerId') return ringingTimer;
          if (call.method == 'cancelStudyTimer' &&
              call.arguments['dismissRinging'] != false &&
              call.arguments['id'] == ringingTimer) {
            ringingTimer = null;
          }
          return switch (call.method) {
            'scheduleStudyTimer' => allowSchedule,
            'requestTimerPermissions' || 'startAlarmChallenge' => true,
            _ => null,
          };
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('deadline retains elapsed time and pause never creates a deadline', () {
    final start = DateTime(2026, 11, 27, 8);
    final running = StudyTimerState(
      clock: StudyClock(elapsedSeconds: 120, runningSince: start),
    );
    expect(running.deadline, start.add(const Duration(minutes: 23)));
    expect(running.secondsAt(start.add(const Duration(minutes: 3))), 1200);
    expect(
      running.copyWith(clock: running.clock.pause(start)).deadline,
      isNull,
    );
    expect(running.copyWith(mode: 'stopwatch').deadline, isNull);
  });

  test(
    'restored running timer schedules its original native deadline and pause cancels it',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final since = DateTime.now().subtract(const Duration(minutes: 3));
      await db.savePreference(
        'activeStudyTimer',
        jsonEncode({
          'mode': 'pomodoro',
          'since': since.toIso8601String(),
          'elapsed': 120,
          'work': 25,
          'break': 5,
          'id': 'survives-close',
          'subject': 'ریاضی',
        }),
      );
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container.read(studyTimerProvider);
      await waitUntil(
        () => calls.any((call) => call.method == 'scheduleStudyTimer'),
      );
      final scheduled = calls.lastWhere(
        (call) => call.method == 'scheduleStudyTimer',
      );
      expect(scheduled.arguments['id'], 'survives-close');
      expect(
        scheduled.arguments['at'],
        since.add(const Duration(minutes: 23)).millisecondsSinceEpoch,
      );
      expect(
        container.read(studyTimerProvider).clock.elapsedAt(DateTime.now()),
        greaterThanOrEqualTo(300),
      );
      await container.read(studyTimerProvider.notifier).pause();
      expect(
        calls
            .lastWhere((call) => call.method == 'cancelStudyTimer')
            .arguments['id'],
        'survives-close',
      );
      expect(container.read(studyTimerProvider).running, isFalse);
      final saved = await (db.select(
        db.appPreferences,
      )..where((p) => p.key.equals('activeStudyTimer'))).getSingle();
      expect(jsonDecode(saved.value)['since'], isNull);
    },
  );

  test(
    'reopening an expired phase records only its planned minute and original time once',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final since = DateTime.now().subtract(const Duration(hours: 2));
      await db.savePreference(
        'activeStudyTimer',
        jsonEncode({
          'mode': 'pomodoro',
          'since': since.toIso8601String(),
          'elapsed': 0,
          'work': 1,
          'break': 5,
          'id': 'expired-in-background',
          'subject': 'زیست',
        }),
      );
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container.read(studyTimerProvider);
      await waitUntil(() => container.read(studyTimerProvider).breakPhase);
      await container.read(studyTimerProvider.notifier).refresh();
      final sessions = await db.select(db.studySessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.single.durationMinutes, 1);
      expect(
        sessions.single.startedAt.difference(since).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
      expect(container.read(studyTimerProvider).running, isFalse);
      expect(container.read(studyTimerProvider).cycles, 1);
      expect(
        calls.where((call) => call.method == 'scheduleStudyTimer'),
        isEmpty,
      );
    },
  );

  test(
    'denied background scheduling keeps the clock running and its warning visible',
    () async {
      allowSchedule = false;
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container.read(studyTimerProvider);
      await waitUntil(() => container.read(studyTimerProvider).ready);
      await container.read(studyTimerProvider.notifier).start();
      final state = container.read(studyTimerProvider);
      expect(state.running, isTrue);
      expect(state.error, contains('مجوز اعلان و آلارم دقیق'));
      expect(state.copyWith().error, state.error);
      await container.read(studyTimerProvider.notifier).pause();
    },
  );

  test(
    'phase completion and resume keep the native alarm until an explicit dismissal',
    () async {
      nativeCompletion = true;
      final db = AppDatabase(NativeDatabase.memory());
      await db.savePreference(
        'activeStudyTimer',
        jsonEncode({
          'mode': 'pomodoro',
          'since': DateTime.now()
              .subtract(const Duration(minutes: 2))
              .toIso8601String(),
          'elapsed': 0,
          'work': 1,
          'break': 5,
          'id': 'keep-ringing',
        }),
      );
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container.read(studyTimerProvider);
      await waitUntil(() => container.read(studyTimerProvider).breakPhase);
      expect(container.read(studyTimerProvider).alertSessionId, 'keep-ringing');
      await container.read(studyTimerProvider.notifier).refresh();
      expect(container.read(studyTimerProvider).alerting, isTrue);
      expect(
        calls.where(
          (call) =>
              call.method == 'cancelStudyTimer' &&
              call.arguments['dismissRinging'] != false,
        ),
        isEmpty,
      );
      await container.read(studyTimerProvider.notifier).dismissAlert();
      expect(container.read(studyTimerProvider).alerting, isFalse);
      expect(ringingTimer, isNull);
      expect(
        calls
            .lastWhere((call) => call.method == 'cancelStudyTimer')
            .arguments['dismissRinging'],
        isTrue,
      );
    },
  );

  test(
    'pausing during a delayed native schedule cancels the stale deadline',
    () async {
      final gate = Completer<bool>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'scheduleStudyTimer') return gate.future;
            return null;
          });
      final db = AppDatabase(NativeDatabase.memory());
      await db.savePreference(
        'activeStudyTimer',
        jsonEncode({
          'mode': 'pomodoro',
          'since': DateTime.now().toIso8601String(),
          'elapsed': 0,
          'work': 25,
          'break': 5,
          'id': 'delayed-schedule',
        }),
      );
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container.read(studyTimerProvider);
      await waitUntil(
        () => calls.any((call) => call.method == 'scheduleStudyTimer'),
      );
      await container.read(studyTimerProvider.notifier).pause();
      gate.complete(true);
      await waitUntil(
        () =>
            calls.where((call) => call.method == 'cancelStudyTimer').length >=
            2,
      );
      expect(container.read(studyTimerProvider).running, isFalse);
      expect(calls.last.method, 'cancelStudyTimer');
      expect(calls.last.arguments['dismissRinging'], isFalse);
    },
  );

  testWidgets(
    'challenge testing uses an unlimited alarm and stops it only after solving',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() async {
        await db.savePreference('profile.grade', '9');
        await db
            .into(db.alarms)
            .insert(
              AlarmsCompanion.insert(
                id: 'long-challenge',
                label: 'آزمایش',
                hour: 23,
                minute: 59,
              ),
            );
      });
      tester.view.physicalSize = const Size(700, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildAppTheme(dark: true),
            locale: const Locale('fa'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('fa'), Locale('en')],
            home: const Scaffold(body: AlarmsPage()),
          ),
        ),
      );
      Future<void> pumpData() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 35)),
        );
        await tester.pumpAndSettle();
      }

      await pumpData();
      await tester.tap(find.text('آزمایش چالش'));
      await pumpData();
      expect(
        calls.where((call) => call.method == 'startAlarmChallenge'),
        hasLength(1),
      );
      expect(
        calls.where((call) => call.method == 'startAlarmPreview'),
        isEmpty,
      );
      await tester.pump(const Duration(seconds: 31));
      expect(find.byKey(const Key('alarm-question')), findsOneWidget);
      expect(calls.where((call) => call.method == 'stopAlarm'), isEmpty);
      final question = tester
          .widget<Text>(find.byKey(const Key('alarm-question')))
          .data!;
      final values = RegExp(
        r'\d+',
      ).allMatches(question).map((m) => int.parse(m[0]!)).toList();
      final answer = question.contains('×')
          ? values[0] * values[1]
          : values[0] ~/ values[1];
      await tester.enterText(find.byKey(const Key('alarm-answer')), '$answer');
      await tester.tap(find.byKey(const Key('alarm-answer-submit')));
      await pumpData();
      expect(
        calls.lastWhere((call) => call.method == 'stopAlarm').arguments['id'],
        'long-challenge',
      );
      expect(find.byKey(const Key('alarm-question')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(db.close);
    },
  );
}
