// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/core/theme/app_theme.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/online/online_backend.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/features/online/profile_setup_page.dart';
import 'support/fake_online_backend.dart';

void main() {
  testWidgets(
    'profile editor fits small screens and validates missing values',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.runAsync(() async {
        await (FontLoader('Vazirmatn')
              ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf')))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      for (final dark in [true, false]) {
        final db = AppDatabase(NativeDatabase.memory());
        final backend = FakeOnlineBackend()
          ..user = const CloudUser(id: 'ui', email: 'ui@example.com', name: '');
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              onlineBackendProvider.overrideWithValue(backend),
            ],
            child: MaterialApp(
              theme: buildAppTheme(dark: dark),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: ProfileSetupPage(user: backend.user),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('avatar-unicorn')), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('WRITE_QA_IMAGES')) {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final picture = await boundary.toImage(pixelRatio: 1);
            final data = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/qa/profile-${dark ? 'dark' : 'light'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            picture.dispose();
          });
        }
        await tester.ensureVisible(find.byKey(const Key('profile-save')));
        await tester.tap(find.byKey(const Key('profile-save')));
        await tester.pumpAndSettle();
        expect(backend.user!.profile.complete, isFalse);
        expect(find.text('نامت را وارد کن'), findsOneWidget);
        expect(find.text('سن را بین ۶ تا ۱۰۰ سال وارد کن'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(db.close);
        await backend.events.close();
      }
    },
  );
}
