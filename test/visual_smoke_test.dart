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
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/data/online/online_backend.dart';
import 'package:rahyar/main.dart';
import 'support/fake_online_backend.dart';

Future<void> snapshot(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('WRITE_QA_IMAGES')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/qa/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'star field and account layout fit a phone in dark and light themes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.runAsync(() async {
        final font = FontLoader('Vazirmatn')
          ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
        await font.load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      for (final dark in [true, false]) {
        final db = AppDatabase(NativeDatabase.memory());
        await tester.runAsync(() => db.savePreference('profile.grade', '10'));
        await tester.runAsync(
          () => db.savePreference('profile.gender:visual', 'unspecified'),
        );
        final key = GlobalKey();
        final backend = FakeOnlineBackend()
          ..user = const CloudUser(
            id: 'visual',
            email: 'test@example.com',
            name: 'همراه',
          );
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                onlineBackendProvider.overrideWithValue(backend),
                darkModeProvider.overrideWith((ref) => dark),
              ],
              child: const RahyarApp(),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(CosmicGlow), findsOneWidget);
        expect(tester.takeException(), isNull);
        await snapshot(tester, key, dark ? 'stars-dark' : 'stars-light');
        backend.user = null;
        ProviderScope.containerOf(
          tester.element(find.byType(AppShell)),
        ).invalidate(cloudUserProvider);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('به راهیار خوش آمدی'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await snapshot(tester, key, dark ? 'account-dark' : 'account-light');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(db.close);
        await backend.events.close();
      }
    },
  );
}
