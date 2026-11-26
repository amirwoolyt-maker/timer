// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/online/online_backend.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});
  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _email = TextEditingController(),
      _code = TextEditingController(),
      _name = TextEditingController();
  EmailChallenge? _challenge;
  Timer? _timer;
  DateTime? _resendAt;
  String? _error, _notice;
  bool _busy = false;
  String? _editingUser;
  int get _remaining =>
      (_resendAt?.difference(DateTime.now()).inSeconds ?? 0).clamp(0, 60);
  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _remaining > 0) return;
    if (!validEmail(normalizeEmail(_email.text))) {
      setState(() => _error = 'یک نشانی ایمیل معتبر وارد کن.');
      return;
    }
    final backend = ref.read(onlineBackendProvider);
    if (backend == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final challenge = await backend.sendCode(_email.text);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _code.clear();
        _resendAt = DateTime.now().add(const Duration(seconds: 60));
        _notice = 'کد به ایمیلت ارسال شد؛ پوشهٔ Spam را هم بررسی کن.';
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _remaining == 0) timer.cancel();
        if (mounted) setState(() {});
      });
    } catch (error) {
      if (mounted) setState(() => _error = onlineError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || _challenge == null) return;
    final code = normalizeEmailCode(_code.text);
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'کد شش‌رقمی ایمیل را وارد کن.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(onlineBackendProvider)!
          .verifyCode(_challenge!.userId, code);
      if (!mounted) return;
      _timer?.cancel();
      _code.clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
      ref.invalidate(cloudUserProvider);
    } catch (error) {
      if (mounted) setState(() => _error = onlineError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accountAction(
    Future<void> Function(OnlineBackend) action, {
    bool returnToRoot = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action(ref.read(onlineBackendProvider)!);
      if (!mounted) return;
      if (returnToRoot) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      ref.invalidate(cloudUserProvider);
      if (!mounted) return;
      setState(() {
        _notice = 'انجام شد.';
        _challenge = null;
        _resendAt = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = onlineError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _feedback() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_busy)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
      if (_notice != null && !_busy)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _notice!,
            style: const TextStyle(color: AppColors.emerald, height: 1.7),
          ),
        ),
      if (_error != null)
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.red, height: 1.7),
            ),
          ),
        ),
    ],
  );

  Widget _login(BuildContext context) {
    final verifying = _challenge != null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 27,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'راهیار',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'برای روزهایی که می‌خواهی جلوتر بروی',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.8),
          ),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 124,
              height: 124,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: .14),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.emerald.withValues(alpha: .25),
                          const Color(0xFF7066D9).withValues(alpha: .16),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: .3),
                      ),
                    ),
                    child: Icon(
                      verifying
                          ? Icons.mark_email_read_outlined
                            : Icons.alternate_email_rounded,
                      size: 47,
                      color: dark
                          ? const Color(0xFF99F4D0)
                          : AppColors.emeraldDark,
                    ),
                  ),
                  Positioned(
                    left: 2,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: .25),
                        ),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AppColors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: .22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: .04),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: verifying
                              ? AppColors.emerald
                              : AppColors.emerald.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          verifying
                              ? '۲ از ۲ • تأیید ایمیل'
                              : '۱ از ۲ • ورود / ساخت حساب',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),
                  Text(
                    verifying ? 'ایمیلت را بررسی کن' : 'به راهیار خوش آمدی',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verifying
                        ? 'کد شش‌رقمی را وارد کن تا مستقیم وارد برنامه شوی.'
                        : 'ایمیلت را بنویس؛ یک کد ورود برایت می‌فرستیم. رمز عبور لازم نیست.',
                    style: const TextStyle(height: 1.9, fontSize: 12),
                  ),
                  const SizedBox(height: 21),
                  if (!verifying) ...[
                    TextField(
                      key: const Key('account-email'),
                      controller: _email,
                      enabled: !_busy,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        labelText: 'آدرس ایمیل',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('account-send'),
                      onPressed: _busy || _remaining > 0 ? null : _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: Text(
                        _remaining > 0
                            ? 'ارسال دوباره پس از $_remaining ثانیه'
                            : 'دریافت کد ورود',
                      ),
                    ),
                  ] else ...[
                    SelectableText(
                      normalizeEmail(_email.text),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('account-code'),
                      controller: _code,
                      enabled: !_busy,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 25,
                        letterSpacing: 7,
                        fontWeight: FontWeight.w700,
                      ),
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onSubmitted: (_) => _verify(),
                      decoration: const InputDecoration(
                        labelText: 'کد شش‌رقمی',
                        hintText: '------',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('account-verify'),
                      onPressed: _busy ? null : _verify,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('تأیید و ورود به راهیار'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('account-send'),
                      onPressed: _busy || _remaining > 0 ? null : _send,
                      child: Text(
                        _remaining > 0
                            ? 'ارسال دوباره پس از $_remaining ثانیه'
                            : 'ارسال دوبارهٔ کد',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _challenge = null;
                              _code.clear();
                              _error = null;
                              _notice = null;
                            }),
                      child: const Text('اصلاح آدرس ایمیل'),
                    ),
                    if (_challenge!.phrase.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          'عبارت امنیتی: ${_challenge!.phrase}\nاین عبارت باید در ایمیل هم یکسان باشد.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, height: 1.8),
                        ),
                      ),
                  ],
                  _feedback(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.emerald,
                size: 15,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'بدون رمز عبور • ورود با تأیید ایمیل',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'با اولین تأیید، حسابت ساخته می‌شود. کارها و یادداشت‌های شخصی روی همین دستگاه می‌مانند و خودکار منتشر نمی‌شوند.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.9),
          ),
        ],
      ),
    );
  }

  Widget _profile(BuildContext context, CloudUser user) {
    if (_editingUser != user.id) {
      _editingUser = user.id;
      _name.text = user.name;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.emerald,
            size: 54,
          ),
          const SizedBox(height: 16),
          const Text(
            'حساب آنلاین تو',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
          const SizedBox(height: 12),
          SelectableText(
            user.email,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('account-name'),
            controller: _name,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'نام نمایشی عمومی'),
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    if (_name.text.trim().isEmpty) {
                      setState(() => _error = 'نام نمایشی را وارد کن.');
                      return;
                    }
                    _accountAction((backend) async {
                      await backend.updateName(_name.text);
                    });
                  },
            child: const Text('ذخیرهٔ نام نمایشی'),
          ),
          const SizedBox(height: 14),
          const Text(
            'برای تغییر جنسیت، پایه و رشته به بخش پروفایل برو. ایمیلت در پست‌ها و چت نمایش داده نمی‌شود. خروج از حساب، داده‌های آفلاین این دستگاه را پاک نمی‌کند.',
            style: TextStyle(height: 1.9, fontSize: 12),
          ),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => _accountAction(
                    (backend) => backend.signOut(),
                    returnToRoot: true,
                  ),
            icon: const Icon(Icons.logout),
            label: const Text('خروج از حساب آنلاین'),
          ),
          _feedback(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(onlineBackendProvider) == null) {
      return const OnlineSetupNotice();
    }
    return ref
        .watch(cloudUserProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(onlineError(error), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(cloudUserProvider),
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
          data: (user) =>
              user == null ? _login(context) : _profile(context, user),
        );
  }
}

class OnlineSetupNotice extends StatelessWidget {
  const OnlineSetupNotice({super.key});
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(Icons.cloud_outlined, size: 52, color: AppColors.emerald),
        SizedBox(height: 16),
        Text(
          'اتصال آنلاین هنوز تنظیم نشده',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          'سازنده باید پروژهٔ سرویس آنلاین را به این نسخه متصل کند. ورود ایمیلی و ارتباط با دیگران بعد از این مرحله فعال می‌شود؛ ابزارهای شخصی آفلاین در دسترس‌اند.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.9),
        ),
      ],
    ),
  );
}
