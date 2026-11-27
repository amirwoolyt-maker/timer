// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/state/app_state.dart';
import 'package:rahyar/core/theme/app_scenes.dart';
import 'package:rahyar/core/theme/app_theme.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/online/online_backend.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/features/appearance/appearance_page.dart';
import 'package:rahyar/main.dart';
import 'support/fake_online_backend.dart';

Future<void> _settleDatabase(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 70)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRunningApp(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 70)),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('signed-out launch restores light mode, language and scene', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final backend = FakeOnlineBackend();
    await tester.runAsync(() async {
      await db.savePreference('darkMode', 'false');
      await db.savePreference('languageEn', 'true');
      await db.savePreference('appearance.scene', 'lantern');
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          onlineBackendProvider.overrideWithValue(backend),
        ],
        child: const RahyarApp(),
      ),
    );
    await _pumpRunningApp(tester);
    expect(find.byType(AppShell), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionGate)),
    );
    expect(container.read(darkModeProvider), isFalse);
    expect(container.read(languageProvider), isTrue);
    expect(container.read(appSceneProvider), AppScene.lantern);
    final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(material.locale, const Locale('en'));
    final sceneContext = tester.element(find.byType(SceneBackground));
    expect(Theme.of(sceneContext).brightness, Brightness.light);
    expect(Directionality.of(sceneContext), TextDirection.ltr);
    expect(
      tester.widget<SceneBackground>(find.byType(SceneBackground)).scene,
      AppScene.lantern,
    );
    // The existing async save + notifier settings path remains compatible.
    await tester.runAsync(() => db.savePreference('darkMode', 'true'));
    container.read(darkModeProvider.notifier).state = true;
    await tester.runAsync(
      () => db.savePreference('appearance.scene', 'kawaii'),
    );
    await _pumpRunningApp(tester);
    expect(container.read(darkModeProvider), isTrue);
    expect(container.read(languageProvider), isTrue);
    expect(container.read(appSceneProvider), AppScene.kawaii);
    final saved = await tester.runAsync(
      () => db.select(db.appPreferences).get(),
    );
    expect(saved!.singleWhere((p) => p.key == 'darkMode').value, 'true');
    expect(saved.singleWhere((p) => p.key == 'languageEn').value, 'true');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(db.close);
    await backend.events.close();
  });

  testWidgets('settings scene choice updates shell artwork and actual theme', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await db.savePreference('profile.grade', '10');
      await db.savePreference('darkMode', 'true');
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          onlineBackendProvider.overrideWithValue(null),
        ],
        child: const RahyarApp(),
      ),
    );
    await _pumpRunningApp(tester);
    expect(find.byType(AppShell), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await _pumpRunningApp(tester);
    await tester.tap(find.byKey(const Key('open-appearance')));
    await _pumpRunningApp(tester);
    expect(find.byType(AppearancePage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('scene-kawaii')),
      240,
      scrollable: find
          .descendant(
            of: find.byType(AppearancePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('scene-kawaii')));
    await _pumpRunningApp(tester);
    await tester.tap(
      find.byTooltip(
        MaterialLocalizations.of(
          tester.element(find.byType(AppearancePage)),
        ).backButtonTooltip,
      ),
    );
    await _pumpRunningApp(tester);
    // Finish the outgoing route after the theme transition has also rebuilt it.
    await _pumpRunningApp(tester);
    expect(find.byType(AppearancePage), findsNothing);
    final background = tester.widget<SceneBackground>(
      find.byType(SceneBackground),
    );
    expect(background.scene, AppScene.kawaii);
    final appContext = tester.element(find.byType(AppShell));
    expect(Theme.of(appContext).colorScheme.primary, AppScene.kawaii.accent);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(db.close);
  });

  test(
    'scene identifiers survive persistence and unknown values fall back',
    () {
      expect(AppScene.values.length, 7);
      for (final scene in AppScene.values) {
        expect(sceneFromId(scene.name), scene);
        expect(scene.title, isNotEmpty);
        expect(scene.description, isNotEmpty);
      }
      expect(sceneFromId('obsolete'), AppScene.cosmic);
      expect(sceneFromId(null), AppScene.cosmic);
    },
  );

  testWidgets('reduce motion freezes decorative scene progress', (
    tester,
  ) async {
    Widget scene(double progress) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: SizedBox(
        width: 390,
        height: 844,
        child: SceneBackground(scene: AppScene.kawaii, progress: progress),
      ),
    );
    await tester.pumpWidget(scene(.2));
    final painterFinder = find.descendant(
      of: find.byType(SceneBackground),
      matching: find.byType(CustomPaint),
    );
    final first = tester.widget<CustomPaint>(painterFinder).painter!;
    await tester.pumpWidget(scene(.7));
    final next = tester.widget<CustomPaint>(painterFinder).painter!;
    expect(next.shouldRepaint(first), isFalse);
  });

  testWidgets('theme selection persists and a fresh provider restores it', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => db.savePreference('appearance.scene', 'lantern'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(dark: true),
          home: const AppearancePage(),
        ),
      ),
    );
    await _settleDatabase(tester);
    final page = tester.element(find.byType(AppearancePage));
    final container = ProviderScope.containerOf(page);
    expect(container.read(appSceneProvider), AppScene.lantern);
    await tester.tap(find.byKey(const ValueKey('scene-halloween')));
    await _settleDatabase(tester);
    expect(container.read(appSceneProvider), AppScene.halloween);
    final saved = await tester.runAsync(
      () => (db.select(
        db.appPreferences,
      )..where((row) => row.key.equals('appearance.scene'))).getSingle(),
    );
    expect(saved!.value, 'halloween');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(db.close);
  });

  testWidgets('all seven illustrated scenes render in both brightness modes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader(
        'Vazirmatn',
      )..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    for (final dark in [true, false]) {
      for (final scene in AppScene.values) {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(dark: dark, scene: scene),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: SceneBackground(
                        scene: scene,
                        dark: dark,
                        progress: .2,
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 215, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              scene.icon,
                              color: dark ? scene.accent : scene.lightAccent,
                              size: 35,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              scene.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  children: [
                                    const Text(
                                      'زمانی برای خودت',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      scene.description,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      '۲۵:۰۰',
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: () {},
                                      child: const Text('شروع تمرکز'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(Card))).colorScheme.primary,
          dark ? scene.accent : scene.lightAccent,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${scene.name} ${dark ? 'dark' : 'light'}',
        );
        if (const bool.fromEnvironment('WRITE_QA_IMAGES')) {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              'build/qa/theme-${scene.name}-${dark ? 'dark' : 'light'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('picker remains usable on a narrow screen with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(dark: false),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const AppearancePage(),
        ),
      ),
    );
    await _settleDatabase(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('scene-kawaii')),
      300,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(db.close);
  });
}
