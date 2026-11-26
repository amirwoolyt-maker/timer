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
      ref.invalidate(cloudUserProvider);
    } catch (error) {
      if (mounted) setState(() => _error = onlineError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accountAction(
    Future<void> Function(OnlineBackend) action,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action(ref.read(onlineBackendProvider)!);
      if (!mounted) return;
      ref.invalidate(cloudUserProvider);
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

  @override
  Widget build(BuildContext context) {
    if (ref.watch(onlineBackendProvider) == null) {
      return const OnlineSetupNotice();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
      child: ref
          .watch(cloudUserProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Column(
              children: [
                Text(onlineError(error)),
                TextButton(
                  onPressed: () => ref.invalidate(cloudUserProvider),
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
            data: (user) {
              if (user != null && _editingUser != user.id) {
                _editingUser = user.id;
                _name.text = user.name;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF123D38), Color(0xFF15203E)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: .35),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          color: Color(0xFF80E5C2),
                          size: 46,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user == null
                              ? 'یک ایمیل تا همراه‌شدن'
                              : 'حساب آنلاین تو',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ورود امن با کد یک‌بارمصرف؛ بدون رمز عبور',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFC2DDD7),
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (user == null) ...[
                    TextField(
                      key: const Key('account-email'),
                      controller: _email,
                      enabled: !_busy && _challenge == null,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'ایمیل',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_challenge != null) ...[
                      TextField(
                        key: const Key('account-code'),
                        controller: _code,
                        enabled: !_busy,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        onSubmitted: (_) => _verify(),
                        decoration: const InputDecoration(
                          labelText: 'کد شش‌رقمی',
                          prefixIcon: Icon(Icons.password_rounded),
                        ),
                      ),
                      if (_challenge!.phrase.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SelectableText(
                            'عبارت امنیتی این درخواست: ${_challenge!.phrase}\nاین عبارت باید در ایمیل هم یکسان باشد.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      FilledButton(
                        key: const Key('account-verify'),
                        onPressed: _busy ? null : _verify,
                        child: const Text('تأیید و ورود'),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _challenge = null;
                                _code.clear();
                                _error = null;
                              }),
                        child: const Text('اصلاح ایمیل'),
                      ),
                    ],
                    OutlinedButton(
                      key: const Key('account-send'),
                      onPressed: _busy || _remaining > 0 ? null : _send,
                      child: Text(
                        _remaining > 0
                            ? 'ارسال دوباره پس از $_remaining ثانیه'
                            : _challenge == null
                            ? 'دریافت کد ورود'
                            : 'ارسال دوبارهٔ کد',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'با تأیید اولین کد، حسابت ساخته می‌شود. فقط اطلاعاتی که خودت در بخش آنلاین منتشر کنی با کاربران واردشده به اشتراک گذاشته می‌شود. کارها و یادداشت‌های شخصی فعلاً روی همین دستگاه می‌مانند.',
                      style: TextStyle(height: 1.9, fontSize: 12),
                    ),
                  ] else ...[
                    SelectableText(
                      user.email,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('account-name'),
                      controller: _name,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'نام نمایشی عمومی',
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () {
                              if (_name.text.trim().isEmpty) {
                                setState(
                                  () => _error = 'نام نمایشی را وارد کن.',
                                );
                                return;
                              }
                              _accountAction((backend) async {
                                await backend.updateName(_name.text);
                              });
                            },
                      child: const Text('ذخیرهٔ نام نمایشی'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ایمیلت در پست‌ها و چت نمایش داده نمی‌شود. اطلاعات آفلاین این دستگاه با خروج از حساب پاک یا منتقل نمی‌شود.',
                      style: TextStyle(height: 1.9),
                    ),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () =>
                                _accountAction((backend) => backend.signOut()),
                      icon: const Icon(Icons.logout),
                      label: const Text('خروج از حساب آنلاین'),
                    ),
                  ],
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _notice!,
                        style: const TextStyle(color: AppColors.emerald),
                      ),
                    ),
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
