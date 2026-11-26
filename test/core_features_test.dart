// ignore_for_file: deprecated_member_use
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/theme/app_theme.dart';
import 'package:rahyar/core/utils/study_clock.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/features/feature_pages.dart';

Widget featureApp(AppDatabase database, Widget page) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(
    theme: buildAppTheme(dark: true),
    locale: const Locale('fa'),
    supportedLocales: const [Locale('fa'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(
      body: Directionality(textDirection: TextDirection.rtl, child: page),
    ),
  ),
);

void main() {
  test('wall clock counts background time and excludes paused time', () {
    final start = DateTime(2026, 11, 26, 8);
    final clock = const StudyClock().start(start);
    expect(clock.elapsedAt(start.add(const Duration(minutes: 12))), 720);
    final paused = clock.pause(start.add(const Duration(minutes: 12)));
    expect(paused.elapsedAt(start.add(const Duration(hours: 1))), 720);
    final resumed = paused.start(start.add(const Duration(hours: 1)));
    expect(
      resumed.elapsedAt(start.add(const Duration(hours: 1, minutes: 3))),
      900,
    );
    expect(resumed.remainingAt(start.add(const Duration(hours: 2)), 1500), 0);
    expect(
      const StudyClock()
          .start(start)
          .elapsedAt(start.subtract(const Duration(minutes: 2))),
      0,
    );
  });

  test('task search normalizes Arabic letter variants and casing', () {
    expect(normalizeTaskSearch('  كتاب رياضي '), 'کتاب ریاضی');
    expect(normalizeTaskSearch('Review BIOLOGY'), 'review biology');
  });

  test('recurring task dates preserve local wall time and clamp month end', () {
    final day = DateTime(2026, 1, 31, 9, 15);
    expect(nextTaskOccurrence(day, 'daily'), DateTime(2026, 2, 1, 9, 15));
    expect(nextTaskOccurrence(day, 'weekly'), DateTime(2026, 2, 7, 9, 15));
    expect(nextTaskOccurrence(day, 'monthly'), DateTime(2026, 2, 28, 9, 15));
  });

  testWidgets(
    'task form validates its title and saves optional due date correctly',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));
      await tester.pumpWidget(featureApp(db, const TasksPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-task')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-task')));
      await tester.pumpAndSettle();
      expect(find.text('عنوان را وارد کن.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('task-title')),
        'مرور فصل اول',
      );
      await tester.tap(find.byKey(const Key('save-task')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      final tasks = (await tester.runAsync(() => db.select(db.tasks).get()))!;
      expect(tasks.single.title, 'مرور فصل اول');
      expect(tasks.single.dueAt, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'notes accept a body without a title and enforce a hard 15 note limit',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));
      await tester.pumpWidget(featureApp(db, const NotesPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-note')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-note')));
      await tester.pumpAndSettle();
      expect(find.text('متن یادداشت را بنویس.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('note-body')),
        'یک ایده برای فردا',
      );
      await tester.tap(find.byKey(const Key('save-note')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(
        (await tester.runAsync(() => db.select(db.notes).get()))!.single.body,
        'یک ایده برای فردا',
      );
      for (var index = 1; index < 15; index++) {
        await tester.runAsync(
          () => db
              .into(db.notes)
              .insert(
                NotesCompanion.insert(
                  id: 'note-$index',
                  body: 'یادداشت $index',
                  updatedAt: DateTime.now(),
                ),
              ),
        );
      }
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('add-note')),
      );
      expect(button.onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('note-search')),
        'نتیجه‌ای ندارد',
      );
      await tester.pumpAndSettle();
      expect(find.text('یادداشتی پیدا نشد'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  test(
    'stopwatch stays active at zero and cannot change mode while running',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container.read(studyTimerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final timer = container.read(studyTimerProvider.notifier);
      await timer.configure(mode: 'stopwatch');
      await timer.start();
      expect(container.read(studyTimerProvider).running, true);
      await timer.configure(mode: 'pomodoro');
      expect(container.read(studyTimerProvider).mode, 'stopwatch');
      await timer.pause();
      expect(container.read(studyTimerProvider).running, false);
      await timer.finish();
      expect(await db.select(db.studySessions).get(), isEmpty);
    },
  );

  test(
    'restored study session saves once when finish is pressed repeatedly',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.savePreference(
        'activeStudyTimer',
        jsonEncode({
          'mode': 'study',
          'elapsed': 180,
          'since': null,
          'subject': 'زیست',
          'id': 'restored-session',
          'work': 25,
          'break': 5,
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
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final timer = container.read(studyTimerProvider.notifier);
      expect(container.read(studyTimerProvider).clock.elapsedSeconds, 180);
      await Future.wait([timer.finish(), timer.finish()]);
      await timer.finish();
      final sessions = await db.select(db.studySessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.single.durationMinutes, 3);
      expect(sessions.single.subject, 'زیست');
    },
  );
}
