import 'package:drift/drift.dart' hide Column, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/main.dart';

void main() {
  testWidgets('راهیار loads its main navigation and the exact tool grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) {
            final database = AppDatabase(NativeDatabase.memory());
            ref.onDispose(database.close);
            return database;
          }),
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
