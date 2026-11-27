// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/theme/app_theme.dart';
import 'package:rahyar/data/catalog/iran_universities.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/features/feature_pages.dart';

Future<void> flush(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 40)),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'catalog contains 100 distinct sourced entries with contiguous ranks',
    () {
      expect(iranUniversities, hasLength(100));
      expect(
        iranUniversities.map((u) => u.rank),
        orderedEquals(List.generate(100, (i) => i + 1)),
      );
      expect(iranUniversities.map((u) => u.id).toSet(), hasLength(100));
      expect(iranUniversities.map((u) => u.name).toSet(), hasLength(100));
      for (final university in iranUniversities) {
        final source = Uri.parse(university.sourceUrl);
        expect(source.scheme, 'https');
        expect(source.host, 'edurank.org');
        expect(university.city, isNotEmpty);
      }
      expect(
        legacyUniversityFavorites.values.every(
          (id) => iranUniversities.any((u) => u.id == id),
        ),
        isTrue,
      );
    },
  );

  test(
    'search handles Arabic letters, English, city and the last university',
    () {
      expect(
        iranUniversities.singleWhere((u) => u.rank == 3).matches('صنعتي شريف'),
        isTrue,
      );
      expect(iranUniversities.first.matches(' UNIVERSITY OF TEHRAN '), isTrue);
      expect(iranUniversities.last.matches('لاهیجان'), isTrue);
      expect(iranUniversities.any((u) => u.matches('نام ناموجود')), isFalse);
    },
  );

  testWidgets('search reaches entry 100 and legacy favorites retain identity', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => db.savePreference(
        'tools.universities',
        jsonEncode([
          {'rank': 1},
        ]),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(dark: true),
          locale: const Locale('fa'),
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: UniversityDirectoryPage(),
            ),
          ),
        ),
      ),
    );
    await flush(tester);
    expect(find.text('۱۰۰ دانشگاه از ۱۰۰'), findsOneWidget);
    await tester.tap(find.byKey(const Key('university-favorites')));
    await tester.pumpAndSettle();
    expect(find.text('دانشگاه صنعتی شریف'), findsOneWidget);
    expect(find.text('دانشگاه تهران'), findsNothing);
    await tester.tap(find.byKey(const Key('university-favorites')));
    await tester.enterText(
      find.byKey(const Key('university-search')),
      'لاهیجان',
    );
    await tester.pumpAndSettle();
    expect(find.text('دانشگاه آزاد اسلامی واحد لاهیجان'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const Key('university-favorite-islamic-azad-university-of-lahijan'),
      ),
    );
    await flush(tester);
    final record = await tester.runAsync(
      () => (db.select(
        db.appPreferences,
      )..where((p) => p.key.equals('tools.universities'))).getSingle(),
    );
    final favorites = jsonDecode(record!.value) as List;
    expect(
      favorites.map((f) => f['id']),
      contains('sharif-university-of-technology'),
    );
    expect(
      favorites.map((f) => f['id']),
      contains('islamic-azad-university-of-lahijan'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(db.close);
  });
}
