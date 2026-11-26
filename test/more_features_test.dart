// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/theme/app_theme.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/features/feature_pages.dart';

Widget _app(AppDatabase db, Widget page) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(db)],
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
Future<void> _pump(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 35)),
  );
  await tester.pumpAndSettle();
}

Future<AppDatabase> _mount(
  WidgetTester tester,
  Widget page, {
  Map<String, String> prefs = const {},
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(700, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() async {
    for (final entry in prefs.entries) {
      await db.savePreference(entry.key, entry.value);
    }
    await db.select(db.appPreferences).get();
  });
  addTearDown(() => tester.runAsync(db.close));
  await tester.pumpWidget(_app(db, page));
  await _pump(tester);
  return db;
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<List<dynamic>> _records(
  WidgetTester tester,
  AppDatabase db,
  String key,
) async => (await tester.runAsync(
  () => (db.select(
    db.appPreferences,
  )..where((r) => r.key.equals(key))).getSingleOrNull(),
)).letDecode();

extension on AppPreference? {
  List<dynamic> letDecode() =>
      this == null ? [] : jsonDecode(this!.value) as List<dynamic>;
}

void main() {
  testWidgets(
    'template confirmation creates real tasks and cancel creates none',
    (tester) async {
      final db = await _mount(tester, const TemplatesPage());
      await tester.tap(find.text('افزودن کارها به امروز').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(await tester.runAsync(() => db.select(db.tasks).get()), isEmpty);
      await tester.tap(find.text('افزودن کارها به امروز').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید'));
      await _pump(tester);
      final rows = await tester.runAsync(() => db.select(db.tasks).get());
      expect(rows, hasLength(4));
      expect(rows!.every((r) => r.dueAt != null), isTrue);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    },
  );

  testWidgets(
    'custom template edits, moves to trash and restores its exact data',
    (tester) async {
      final db = await _mount(
        tester,
        const TemplatesPage(),
        prefs: {
          'tools.templates': jsonEncode([
            {
              'id': 'one',
              'title': 'برنامه من',
              'description': 'تمرین',
              'tasks': 'تمرین یک',
            },
          ]),
        },
      );
      await tester.tap(find.byTooltip('ویرایش'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tool-field-title')),
        'برنامه اصلاح‌شده',
      );
      await tester.tap(find.byKey(const Key('tool-save')));
      await _pump(tester);
      expect(find.text('برنامه اصلاح‌شده'), findsOneWidget);
      await tester.tap(find.byTooltip('انتقال به سطل زباله'));
      await _pump(tester);
      expect(await _records(tester, db, 'tools.templates'), isEmpty);
      expect(await _records(tester, db, 'tools.trash'), hasLength(1));
      await tester.pumpWidget(_app(db, const TrashPage()));
      await _pump(tester);
      await tester.tap(find.text('بازیابی'));
      await _pump(tester);
      final restored = await _records(tester, db, 'tools.templates');
      expect(restored.single['title'], 'برنامه اصلاح‌شده');
      expect(restored.single['tasks'], 'تمرین یک');
      expect(await _records(tester, db, 'tools.trash'), isEmpty);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    },
  );

  testWidgets('chat saves real messages and allows deleting them', (
    tester,
  ) async {
    final db = await _mount(tester, const LocalChatPage());
    await tester.enterText(find.byType(TextField), 'برای آزمون آماده‌ام');
    await tester.tap(find.text('ذخیره پیام'));
    await _pump(tester);
    expect(
      (await _records(tester, db, 'tools.chat')).single['body'],
      'برای آزمون آماده‌ام',
    );
    expect(find.text('برای آزمون آماده‌ام'), findsOneWidget);
    await tester.tap(find.byTooltip('حذف پیام'));
    await _pump(tester);
    expect(await _records(tester, db, 'tools.chat'), isEmpty);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets(
    'study rooms create a saved room and launch a working timer route',
    (tester) async {
      final db = await _mount(tester, const StudyRoomsPage());
      await tester.tap(find.text('اتاق جدید'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tool-field-name')),
        'اتاق جبر',
      );
      await tester.enterText(
        find.byKey(const Key('tool-field-description')),
        'تمرین فصل دوم',
      );
      await tester.tap(find.byKey(const Key('tool-save')));
      await _pump(tester);
      expect(
        (await _records(tester, db, 'tools.rooms')).single['name'],
        'اتاق جبر',
      );
      await tester.tap(find.text('ورود و شروع مطالعه'));
      await _pump(tester);
      expect(find.byType(StudyTimerPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    },
  );

  testWidgets('junior grades only have easy challenge option', (tester) async {
    await _mount(
      tester,
      const AlarmsPage(),
      prefs: {'profile.grade': 'elementary'},
    );
    await tester.tap(find.text('آلارم جدید'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('متوسط'), findsNothing);
    expect(find.text('سخت'), findsNothing);
    expect(find.text('آسان'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets(
    'six wrong alarm answers lock input without disabling alarm and Persian digits solve it',
    (tester) async {
      final db = await _mount(
        tester,
        const AlarmsPage(),
        prefs: {'profile.grade': '9'},
      );
      await tester.runAsync(
        () => db
            .into(db.alarms)
            .insert(
              AlarmsCompanion.insert(
                id: 'test-alarm',
                label: 'بیداری',
                hour: 23,
                minute: 59,
              ),
            ),
      );
      await _pump(tester);
      await tester.tap(find.text('آزمایش چالش'));
      await _pump(tester);
      final question = tester
          .widget<Text>(find.byKey(const Key('alarm-question')))
          .data!;
      final numbers = RegExp(
        r'\d+',
      ).allMatches(question).map((m) => int.parse(m.group(0)!)).toList();
      final answer = question.contains('×')
          ? numbers[0] * numbers[1]
          : numbers[0] ~/ numbers[1];
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(const Key('alarm-answer')), '999999');
        await tester.tap(find.byKey(const Key('alarm-answer-submit')));
        await _pump(tester);
      }
      final alarm = await tester.runAsync(
        () => db.select(db.alarms).getSingle(),
      );
      expect(alarm!.enabled, isTrue);
      expect(alarm.wrongAttempts, 6);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('alarm-answer-submit')))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const Key('alarm-question')), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
      await _pump(tester);
      const digits = '۰۱۲۳۴۵۶۷۸۹';
      final persian = answer
          .toString()
          .split('')
          .map((c) => digits[int.parse(c)])
          .join();
      await tester.enterText(find.byKey(const Key('alarm-answer')), persian);
      await tester.tap(find.byKey(const Key('alarm-answer-submit')));
      await _pump(tester);
      expect(find.byKey(const Key('alarm-question')), findsNothing);
      expect(
        (await tester.runAsync(
          () => db.select(db.alarms).getSingle(),
        ))!.wrongAttempts,
        0,
      );
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    },
  );

  testWidgets('dashboard starts with real zero stats and saves daily habits', (
    tester,
  ) async {
    final db = await _mount(tester, const DashboardPage());
    final add = find.byKey(const Key('add-habit'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('tool-field-title')),
      'مطالعه هر روز',
    );
    await tester.tap(find.byKey(const Key('tool-save')));
    await _pump(tester);
    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await _pump(tester);
    final habits = await _records(tester, db, 'tools.habits');
    expect(habits.single['days'], hasLength(1));
    await tester.tap(find.byTooltip('انتقال عادت به سطل زباله'));
    await _pump(tester);
    expect(await _records(tester, db, 'tools.habits'), isEmpty);
    expect(
      (await _records(tester, db, 'tools.trash')).single['source'],
      'tools.habits',
    );
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });
}
