// ignore_for_file: deprecated_member_use
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/state/app_state.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/features/feature_pages.dart';
import 'package:rahyar/main.dart';

Future<void> mountApp(
  WidgetTester tester,
  Size size, {
  bool english = false,
  double textScaleFactor = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final database = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() => database.select(database.appPreferences).get());
  await tester.runAsync(() => database.savePreference('profile.grade', '10'));
  addTearDown(() => tester.runAsync(database.close));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => database),
        languageProvider.overrideWith((ref) => english),
      ],
      child: const RahyarApp(),
    ),
  );
  await pumpData(tester);
}

Future<void> pumpData(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  // A breathing background intentionally never settles; bound animation pumps.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 100));
}

Finder navLabel(String label) =>
    find.descendant(of: find.byType(AppNavigation), matching: find.text(label));

void main() {
  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets('shell keeps usable body and navigation at $size', (
      tester,
    ) async {
      await mountApp(tester, size);
      final body = tester.getRect(find.byKey(const ValueKey('app-body')));
      final nav = tester.getRect(find.byType(AppNavigation));
      final add = tester.getRect(find.byKey(const Key('add-task')));
      expect(body.height, greaterThan(500));
      expect(nav.height, lessThan(110));
      expect(nav.top, greaterThan(size.height - 110));
      expect(nav.bottom, lessThanOrEqualTo(size.height));
      expect(add.bottom, lessThanOrEqualTo(body.bottom));
      expect(add.top, greaterThan(body.top));
      expect(find.byKey(const Key('add-task')).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      const labels = ['کارها', 'تمرکز', 'یادداشت', 'همراهان', 'بیشتر'];
      const pages = [
        TasksPage,
        StudyTimerPage,
        NotesPage,
        CommunityPage,
        MoreGrid,
      ];
      for (var i = 0; i < labels.length; i++) {
        await tester.tap(navLabel(labels[i]));
        await pumpData(tester);
        expect(find.byType(pages[i]), findsOneWidget, reason: labels[i]);
        final navigation = tester.widget<AppNavigation>(
          find.byType(AppNavigation),
        );
        expect(navigation.selected, AppTab.values[i]);
        expect(tester.takeException(), isNull, reason: labels[i]);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'compact English navigation and tools fit at 320px with large text',
    (tester) async {
      await mountApp(
        tester,
        const Size(320, 800),
        english: true,
        textScaleFactor: 1.5,
      );

      expect(find.byTooltip('Community'), findsOneWidget);
      await tester.tap(find.byTooltip('Community'));
      await pumpData(tester);
      expect(find.byType(CommunityPage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('More'));
      await pumpData(tester);
      expect(find.text('Statistics dashboard'), findsOneWidget);
      expect(find.text('University directory'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('all sixteen More cards open their own route on a phone', (
    tester,
  ) async {
    await mountApp(tester, const Size(360, 800));
    expect(MoreGrid.items, hasLength(16));
    for (final item in MoreGrid.items) {
      await tester.tap(navLabel('بیشتر'));
      await pumpData(tester);
      final card = find.text(item.$2);
      await tester.ensureVisible(card);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(card);
      await pumpData(tester);
      expect(find.byType(FeaturePage), findsOneWidget, reason: item.$1);
      expect(
        tester.widget<FeaturePage>(find.byType(FeaturePage)).feature,
        item.$1,
      );
      expect(find.byTooltip('بازگشت'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: item.$1);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
