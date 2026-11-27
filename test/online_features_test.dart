// ignore_for_file: deprecated_member_use
import 'support/fake_online_backend.dart';
import 'package:drift/native.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/data/online/online_backend.dart';
import 'package:rahyar/features/online/account_page.dart';
import 'package:rahyar/features/online/cloud_hub_page.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 35)),
  );
  await tester.pumpAndSettle();
}

Future<void> mount(
  WidgetTester tester,
  FakeOnlineBackend backend,
  Widget page,
) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onlineBackendProvider.overrideWithValue(backend),
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Directionality(textDirection: TextDirection.rtl, child: page),
        ),
      ),
    ),
  );
  await settle(tester);
}

Future<void> cleanup(WidgetTester tester, FakeOnlineBackend backend) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await settle(tester);
  await backend.events.close();
}

void main() {
  test('email and Persian OTP validation are strict', () {
    expect(normalizeEmail(' A@Example.COM '), 'a@example.com');
    expect(validEmail('a@example.com'), isTrue);
    for (final email in ['a', 'a@', 'a b@example.com', 'x@localhost']) {
      expect(validEmail(email), isFalse);
    }
    expect(normalizeEmailCode('۱۲۳ ٤٥٦'), '123456');
    expect(
      const OnlineConfig(
        endpoint: 'http://insecure/v1',
        projectId: '123',
      ).enabled,
      isFalse,
    );
    expect(
      const OnlineConfig(
        endpoint: 'https://fra.cloud.appwrite.io/v1',
        projectId: '123',
      ).enabled,
      isTrue,
    );
  });
  testWidgets(
    'email OTP validates, throttles resend, verifies Persian digits and logs out',
    (tester) async {
      final backend = FakeOnlineBackend();
      await mount(tester, backend, const AccountPage());
      await tester.tap(find.byKey(const Key('account-send')));
      await settle(tester);
      expect(backend.sendCount, 0);
      await tester.enterText(
        find.byKey(const Key('account-email')),
        'test@example.com',
      );
      await tester.tap(find.byKey(const Key('account-send')));
      await settle(tester);
      expect(backend.sentEmail, 'test@example.com');
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('account-send')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('silver meadow'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('account-code')), '۱۲۳۴۵۶');
      await tester.ensureVisible(find.byKey(const Key('account-verify')));
      await tester.tap(find.byKey(const Key('account-verify')));
      await settle(tester);
      expect(backend.verifiedCode, '123456');
      expect(find.text('حساب آنلاین تو'), findsOneWidget);
      await tester.ensureVisible(find.text('خروج از حساب آنلاین'));
      await tester.tap(find.text('خروج از حساب آنلاین'));
      await settle(tester);
      expect(backend.user, isNull);
      expect(find.byKey(const Key('account-email')), findsOneWidget);
      await cleanup(tester, backend);
    },
  );
  testWidgets('invalid email code does not unlock shared community', (
    tester,
  ) async {
    final backend = FakeOnlineBackend()..rejectCode = true;
    await mount(tester, backend, const CloudHubPage());
    expect(find.byKey(const Key('cloud-compose')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('account-email')),
      'test@example.com',
    );
    await tester.tap(find.byKey(const Key('account-send')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('account-code')), '123456');
    await tester.ensureVisible(find.byKey(const Key('account-verify')));
    await tester.tap(find.byKey(const Key('account-verify')));
    await settle(tester);
    expect(backend.user, isNull);
    expect(find.byKey(const Key('cloud-compose')), findsNothing);
    await cleanup(tester, backend);
  });
  testWidgets('authenticated posts use shared backend and update feed', (
    tester,
  ) async {
    final backend = FakeOnlineBackend()
      ..user = const CloudUser(
        id: 'one',
        email: 'private@example.com',
        name: 'همراه',
      );
    await mount(tester, backend, const CloudHubPage());
    await tester.enterText(
      find.byKey(const Key('cloud-compose')),
      'امروز مطالعه کردم',
    );
    await tester.ensureVisible(find.byKey(const Key('cloud-send')));
    await tester.tap(find.byKey(const Key('cloud-send')));
    await settle(tester);
    expect(backend.entries['posts']!.single.body, 'امروز مطالعه کردم');
    expect(find.text('امروز مطالعه کردم'), findsOneWidget);
    expect(find.text('private@example.com'), findsNothing);
    await cleanup(tester, backend);
  });
}
