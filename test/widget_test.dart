// ignore_for_file: deprecated_member_use

import 'package:drift/drift.dart' hide Column, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/main.dart';

void main() {
  testWidgets('راهیار loads its main navigation and the exact tool grid', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(database.close));
    await tester.runAsync(() => database.savePreference('profile.grade', '10'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) => database),
          tasksProvider.overrideWith((ref) => Stream.value(<Task>[])),
        ],
        child: const RahyarApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('راهیار'), findsOneWidget);
    expect(find.text('کارها'), findsOneWidget);
    await tester.tap(find.text('بیشتر'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('همه ابزارها، یک‌جا'), findsOneWidget);
    expect(find.text('داشبورد آمار'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('first launch asks for study level and saves the selection', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(database.close));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWith((ref) => database)],
        child: const RahyarApp(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('پایهٔ تحصیلی‌ات را انتخاب کن'), findsOneWidget);
    expect(find.text('ادامه'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'ادامه'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('دهم').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('ادامه'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    final saved = await tester.runAsync(
      () => database.select(database.appPreferences).get(),
    );
    expect(
      saved!
          .singleWhere((preference) => preference.key == 'profile.grade')
          .value,
      '10',
    );
    expect(find.text('پایهٔ تحصیلی‌ات را انتخاب کن'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWith((ref) => database)],
        child: const RahyarApp(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('پایهٔ تحصیلی‌ات را انتخاب کن'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('Drift stores tasks and moves them into trash', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 11, 24);
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'sample-task',
            title: 'مرور درس',
            dueAt: Value(now),
            createdAt: now,
          ),
        );
    expect((await database.watchActiveTasks().first).single.title, 'مرور درس');
    await database.softDeleteTask('sample-task');
    expect((await database.watchTrashTasks().first).single.title, 'مرور درس');
    await database.restoreTask('sample-task');
    expect((await database.watchActiveTasks().first).single.deletedAt, isNull);
    await database.close();
  });
}
