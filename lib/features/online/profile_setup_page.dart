// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/app_state.dart';
import '../../data/online/online_backend.dart';
import '../../data/repositories/providers.dart';
import 'profile_avatar.dart';
export 'profile_avatar.dart';

/// One form is shared by first sign-in and subsequent profile editing.
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({this.user, this.editing = false, super.key});
  final CloudUser? user;
  final bool editing;
  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _age = TextEditingController(),
      _subject = TextEditingController();
  String? _grade, _gender, _avatar, _error;
  bool _busy = false, _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = widget.user;
    var p = user?.profile ?? const UserProfile();
    try {
      final db = ref.read(databaseProvider);
      final rows = await db.select(db.appPreferences).get();
      final values = {for (final row in rows) row.key: row.value};
      String local(String key) =>
          values[user == null ? 'profile.$key' : 'profile.$key:${user.id}'] ??
          '';
      p = UserProfile(
        name: p.name.isNotEmpty
            ? p.name
            : (user?.name.isNotEmpty ?? false)
            ? user!.name
            : local('name'),
        age: p.age ?? int.tryParse(local('age')),
        grade: p.grade.isNotEmpty ? p.grade : local('grade'),
        gender: p.gender.isNotEmpty ? p.gender : local('gender'),
        avatar: p.avatar.isNotEmpty ? p.avatar : local('avatar'),
        subject: p.subject.isNotEmpty ? p.subject : local('subject'),
      );
    } catch (_) {
      // A cache problem must not prevent completing a real account profile.
    }
    if (!mounted) return;
    _name.text = p.name;
    _age.text = p.age?.toString() ?? '';
    _subject.text = p.subject;
    setState(() {
      _grade = educationGrades.containsKey(p.grade) ? p.grade : null;
      _gender = const ['female', 'male', 'unspecified'].contains(p.gender)
          ? p.gender
          : null;
      _avatar = profileAvatars.containsKey(p.avatar) ? p.avatar : null;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _subject.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_avatar == null) {
      setState(() => _error = 'یک آواتار برای پروفایلت انتخاب کن.');
      return;
    }
    final profile = UserProfile(
      name: _name.text.trim(),
      age: int.tryParse(normalizeEmailCode(_age.text)),
      grade: _grade!,
      gender: _gender!,
      avatar: _avatar!,
      subject: _subject.text.trim(),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final backend = ref.read(onlineBackendProvider);
      if (widget.user != null) {
        if (backend == null) {
          setState(
            () => _error =
                'اتصال حساب فعال نیست. برای ویرایش پروفایل، تنظیمات سرویس آنلاین را بررسی کن.',
          );
          return;
        }
        await backend.updateProfile(profile);
        ref.invalidate(cloudUserProvider);
      } else {
        final db = ref.read(databaseProvider);
        await db.transaction(() async {
          for (final entry in profile.toMap().entries) {
            await db.savePreference(
              'profile.${entry.key}',
              '${entry.value ?? ''}',
            );
          }
        });
      }
      if (!mounted) return;
      if (widget.editing) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = onlineError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = ref.watch(languageProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: widget.editing
          ? AppBar(title: Text(english ? 'Edit profile' : 'ویرایش پروفایل'))
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: !_loaded
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!widget.editing) ...[
                            Text(
                              english
                                  ? 'EMAIL VERIFIED · YOUR PROFILE'
                                  : 'ایمیل تأیید شد • حالا نوبت توست',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            english
                                ? 'Make Rahyar yours'
                                : 'راهیارت را شخصی کن',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            english
                                ? 'Choose an avatar and tell us a little about yourself.'
                                : 'یک چهره برای پروفایلت انتخاب کن و کمی از خودت بگو.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(height: 1.8),
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: ProfileAvatar(
                              avatar: _avatar ?? '',
                              radius: 43,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: profileAvatars.entries
                                .map(
                                  (entry) => Semantics(
                                    selected: _avatar == entry.key,
                                    button: true,
                                    label:
                                        '${english ? 'Avatar' : 'آواتار'} ${entry.value.label}',
                                    child: Tooltip(
                                      message: entry.value.label,
                                      child: InkWell(
                                        key: Key('avatar-${entry.key}'),
                                        borderRadius: BorderRadius.circular(17),
                                        onTap: _busy
                                            ? null
                                            : () => setState(
                                                () => _avatar = entry.key,
                                              ),
                                        child: AnimatedContainer(
                                          duration:
                                              MediaQuery.disableAnimationsOf(
                                                context,
                                              )
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 150,
                                                ),
                                          width: 52,
                                          height: 52,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _avatar == entry.key
                                                ? scheme.primaryContainer
                                                : scheme
                                                      .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              17,
                                            ),
                                            border: Border.all(
                                              color: _avatar == entry.key
                                                  ? scheme.primary
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: AvatarGlyph(avatar: entry.key),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 26),
                          TextFormField(
                            key: const Key('onboarding-name'),
                            controller: _name,
                            enabled: !_busy,
                            maxLength: 60,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.nickname],
                            decoration: InputDecoration(
                              labelText: english
                                  ? 'Display name'
                                  : 'نام نمایشی',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              helperText: english
                                  ? 'Visible in the community'
                                  : 'این نام در فضای همراهان دیده می‌شود',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? (english
                                      ? 'Enter your name'
                                      : 'نامت را وارد کن')
                                : value.trim().length > 60
                                ? (english
                                      ? 'Use at most 60 characters'
                                      : 'نام حداکثر ۶۰ نویسه باشد')
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('onboarding-age'),
                            controller: _age,
                            enabled: !_busy,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: InputDecoration(
                              labelText: english ? 'Age' : 'سن',
                              suffixText: english ? 'years' : 'سال',
                              prefixIcon: const Icon(Icons.cake_outlined),
                            ),
                            validator: (value) {
                              final age = int.tryParse(
                                normalizeEmailCode(value ?? ''),
                              );
                              return age == null || age < 6 || age > 100
                                  ? (english
                                        ? 'Enter an age from 6 to 100'
                                        : 'سن را بین ۶ تا ۱۰۰ سال وارد کن')
                                  : null;
                            },
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            key: const Key('onboarding-grade'),
                            isExpanded: true,
                            initialValue: _grade,
                            decoration: InputDecoration(
                              labelText: english
                                  ? 'Education level'
                                  : 'پایهٔ تحصیلی',
                              prefixIcon: const Icon(Icons.school_outlined),
                            ),
                            items: educationGrades.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(
                                      english
                                          ? (int.tryParse(entry.key) != null
                                                ? 'Grade ${entry.key}'
                                                : entry.key)
                                          : entry.value,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _grade = value),
                            validator: (value) => value == null
                                ? (english
                                      ? 'Choose a level'
                                      : 'پایه‌ات را انتخاب کن')
                                : null,
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            key: const Key('onboarding-gender'),
                            isExpanded: true,
                            initialValue: _gender,
                            decoration: InputDecoration(
                              labelText: english ? 'Gender' : 'جنسیت',
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'female',
                                child: Text(english ? 'Female' : 'دختر / زن'),
                              ),
                              DropdownMenuItem(
                                value: 'male',
                                child: Text(english ? 'Male' : 'پسر / مرد'),
                              ),
                              DropdownMenuItem(
                                value: 'unspecified',
                                child: Text(
                                  english
                                      ? 'Prefer not to say'
                                      : 'ترجیح می‌دهم نگویم',
                                ),
                              ),
                            ],
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _gender = value),
                            validator: (value) => value == null
                                ? (english
                                      ? 'Choose an option'
                                      : 'یک گزینه انتخاب کن')
                                : null,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _subject,
                            enabled: !_busy,
                            maxLength: 60,
                            validator: (value) =>
                                (value?.trim().length ?? 0) > 60
                                ? (english
                                      ? 'Use at most 60 characters'
                                      : 'رشته حداکثر ۶۰ نویسه باشد')
                                : null,
                            decoration: InputDecoration(
                              labelText: english
                                  ? 'Field of study (optional)'
                                  : 'رشتهٔ تحصیلی (اختیاری)',
                              prefixIcon: const Icon(
                                Icons.auto_stories_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withValues(
                                alpha: .35,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              english
                                  ? 'Your age, education and gender stay private in your account. You can change them later in Profile.'
                                  : 'سن، پایه، رشته و جنسیت در تنظیمات خصوصی حسابت ذخیره می‌شوند و در پست‌ها نمایش داده نمی‌شوند. بعداً از پروفایل قابل تغییرند.',
                              style: const TextStyle(fontSize: 11, height: 1.9),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: scheme.error),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            key: const Key('profile-save'),
                            onPressed: _busy ? null : _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _busy
                                  ? (english ? 'Saving…' : 'در حال ذخیره…')
                                  : widget.editing
                                  ? (english
                                        ? 'Save changes'
                                        : 'ذخیرهٔ تغییرات')
                                  : (english
                                        ? 'Start my journey'
                                        : 'شروع کن؛ آماده‌ام'),
                            ),
                          ),
                          if (!widget.editing && widget.user != null)
                            TextButton(
                              onPressed:
                                  _busy ||
                                      ref.watch(onlineBackendProvider) == null
                                  ? null
                                  : () async {
                                      setState(() {
                                        _busy = true;
                                        _error = null;
                                      });
                                      try {
                                        await ref
                                            .read(onlineBackendProvider)!
                                            .signOut();
                                        ref.invalidate(cloudUserProvider);
                                      } catch (error) {
                                        if (mounted) {
                                          setState(
                                            () => _error = onlineError(error),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _busy = false);
                                        }
                                      }
                                    },
                              child: Text(
                                english
                                    ? 'Use another email'
                                    : 'ورود با ایمیل دیگر',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
