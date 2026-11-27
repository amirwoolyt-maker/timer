// ignore_for_file: deprecated_member_use
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/online/online_backend.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:rahyar/main.dart';
import 'package:rahyar/features/online/profile_setup_page.dart';
import 'support/fake_online_backend.dart';

Future<void> pumpData(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 40)),
  );
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> mount(
  WidgetTester tester,
  AppDatabase db,
  FakeOnlineBackend backend,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        onlineBackendProvider.overrideWithValue(backend),
      ],
      child: const RahyarApp(),
    ),
  );
  await pumpData(tester);
}

Future<void> cleanup(
  WidgetTester tester,
  AppDatabase db,
  FakeOnlineBackend backend,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.runAsync(db.close);
  await backend.events.close();
}

void main() {
  testWidgets(
    'launch shows login first and valid code replaces it with the app',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() async {
        await db.savePreference('profile.grade', '10');
        await db.savePreference('profile.gender:user-one', 'unspecified');
      });
      final backend = FakeOnlineBackend()
        ..verifiedProfile = const UserProfile(
          name: 'همراه',
          age: 18,
          grade: '10',
          gender: 'unspecified',
          avatar: 'fox',
        );
      await mount(tester, db, backend);
      expect(find.byType(AppShell), findsNothing);
      expect(find.text('به راهیار خوش آمدی'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('account-email')),
        'test@example.com',
      );
      await tester.ensureVisible(find.byKey(const Key('account-send')));
      await tester.tap(find.byKey(const Key('account-send')));
      await pumpData(tester);
      await tester.enterText(find.byKey(const Key('account-code')), '123456');
      await tester.ensureVisible(find.byKey(const Key('account-verify')));
      await tester.tap(find.byKey(const Key('account-verify')));
      await pumpData(tester);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byKey(const Key('account-email')), findsNothing);
      expect(find.byKey(const Key('account-code')), findsNothing);
      expect(tester.takeException(), isNull);
      await cleanup(tester, db, backend);
    },
  );
  testWidgets(
    'first account completes name, age, education, gender and avatar',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() => db.savePreference('profile.grade', '10'));
      final backend = FakeOnlineBackend()
        ..user = const CloudUser(
          id: 'new-user',
          email: 'test@example.com',
          name: '',
        );
      await mount(tester, db, backend);
      await pumpData(tester);
      expect(find.byType(ProfileSetupPage), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      await tester.tap(find.byKey(const Key('avatar-fox')));
      await tester.enterText(find.byKey(const Key('onboarding-name')), 'سارا');
      await tester.enterText(find.byKey(const Key('onboarding-age')), '۱۷');
      await tester.ensureVisible(find.byKey(const Key('onboarding-grade')));
      await tester.tap(find.byKey(const Key('onboarding-grade')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('دهم').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.byKey(const Key('onboarding-gender')));
      await tester.tap(find.byKey(const Key('onboarding-gender')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('دختر / زن').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.byKey(const Key('profile-save')));
      await tester.tap(find.byKey(const Key('profile-save')));
      await pumpData(tester);
      await pumpData(tester);
      expect(backend.user!.profile.complete, isTrue);
      expect(backend.user!.profile.age, 17);
      expect(backend.user!.profile.gender, 'female');
      expect(find.byType(ProfileSetupPage), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
      final prefs = await tester.runAsync(
        () => db.select(db.appPreferences).get(),
      );
      expect(
        prefs!.singleWhere((p) => p.key == 'profile.age:new-user').value,
        '17',
      );
      expect(tester.takeException(), isNull);
      await cleanup(tester, db, backend);
    },
  );
  testWidgets('a ringing Android alarm can be solved while signed out', (
    tester,
  ) async {
    const channel = MethodChannel('rahyar/platform');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'pendingAlarmId' ? 'wake' : null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => db
          .into(db.alarms)
          .insert(
            AlarmsCompanion.insert(
              id: 'wake',
              label: 'بیداری',
              hour: 7,
              minute: 0,
            ),
          ),
    );
    final backend = FakeOnlineBackend();
    await mount(tester, db, backend);
    await tester.pump(const Duration(seconds: 3));
    await pumpData(tester);
    expect(find.byKey(const Key('alarm-question')), findsOneWidget);
    expect(find.byKey(const Key('account-email')), findsNothing);
    await cleanup(tester, db, backend);
  });
  testWidgets(
    'offline tools do not bypass profile setup after account recovery',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() => db.savePreference('profile.grade', '10'));
      final backend = FakeOnlineBackend()..offline = true;
      await mount(tester, db, backend);
      await pumpData(tester);
      expect(find.text('بررسی حساب انجام نشد'), findsOneWidget);
      await tester.tap(find.text('ادامه با ابزارهای آفلاین'));
      await pumpData(tester);
      expect(find.byType(AppShell), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      backend.offline = false;
      backend.user = const CloudUser(
        id: 'recovered',
        email: 'recovered@example.com',
        name: '',
      );
      container.invalidate(cloudUserProvider);
      await pumpData(tester);
      await pumpData(tester);
      expect(find.byType(ProfileSetupPage), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      expect(tester.takeException(), isNull);
      await cleanup(tester, db, backend);
    },
  );
}
