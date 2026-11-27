part of '../../feature_pages.dart';

String profileGenderKey(WidgetRef ref) {
  final userId = ref.read(cloudUserProvider).asData?.value?.id;
  return userId == null ? 'profile.gender' : 'profile.gender:$userId';
}

String profilePreference(WidgetRef ref, String key, [String fallback = '']) {
  final user = ref.watch(cloudUserProvider).asData?.value;
  final plain = key.replaceFirst('profile.', '');
  if (user != null && !plain.contains(':')) {
    final value = user.profile.toMap()[plain];
    if (value != null && '$value'.isNotEmpty) return '$value';
    if (plain == 'name' && user.name.isNotEmpty) return user.name;
    key = '$key:${user.id}';
  }
  final values =
      ref.watch(preferencesProvider).asData?.value ?? <AppPreference>[];
  for (final value in values) {
    if (value.key == key) return value.value;
  }
  return fallback;
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = ref.watch(languageProvider);
    final name = profilePreference(
      ref,
      'profile.name',
      english ? 'Your profile' : 'پروفایل من',
    );
    final grade = profilePreference(ref, 'profile.grade');
    final subject = profilePreference(ref, 'profile.subject');
    final gender = profilePreference(ref, 'profile.gender');
    final age = profilePreference(ref, 'profile.age');
    final avatar = profilePreference(ref, 'profile.avatar');
    final user = ref.watch(cloudUserProvider).asData?.value;
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.cloud_done_outlined,
                color: AppColors.emerald,
              ),
              title: Text(
                english ? 'Online account' : 'حساب آنلاین و ورود ایمیلی',
              ),
              subtitle: Text(
                english
                    ? 'Email code • shared community'
                    : 'کد یک‌بارمصرف ایمیلی • فضای مشترک همراهان',
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: Text(english ? 'Account' : 'حساب کاربری'),
                    ),
                    body: const AccountPage(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (user?.isOffline ?? false)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'حالت آفلاین؛ پروفایل ذخیره‌شده نمایش داده می‌شود. برای ویرایش اطلاعات حساب، به اینترنت وصل شو.',
                style: TextStyle(height: 1.8),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  ProfileAvatar(avatar: avatar),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (grade.isNotEmpty)
                        english
                            ? (grade == 'student'
                                  ? 'University'
                                  : grade == 'elementary'
                                  ? 'Elementary'
                                  : 'Grade $grade')
                            : educationGrades[grade] ?? grade,
                      if (subject.isNotEmpty) subject,
                      if (age.isNotEmpty) english ? '$age years' : '$age سال',
                      if (gender.isNotEmpty)
                        english
                            ? {
                                    'female': 'Female',
                                    'male': 'Male',
                                    'unspecified': 'Prefer not to say',
                                  }[gender] ??
                                  ''
                            : {
                                    'female': 'دختر / زن',
                                    'male': 'پسر / مرد',
                                    'unspecified': 'جنسیت: اعلام‌نشده',
                                  }[gender] ??
                                  '',
                    ].join(' · '),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _editProfile(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      english
                          ? 'Edit education and profile'
                          : 'ویرایش پروفایل و اطلاعات تحصیلی',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(
            english ? 'My books' : 'کتاب‌های من',
            action: english ? 'Add book' : 'افزودن کتاب',
            onTap: () => _editBook(context, ref),
          ),
          Text(
            english
                ? 'Saved books are available to your study timer.'
                : 'کتاب‌ها ذخیره می‌شوند و در تایمر درس قابل انتخاب‌اند.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ref
              .watch(booksProvider)
              .when(
                data: (books) => books.isEmpty
                    ? EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: english
                            ? 'Your bookshelf is empty'
                            : 'کتابخانه‌ات منتظر اولین کتاب است',
                        subtitle: english
                            ? 'Add any school or university book.'
                            : 'کتاب درسی یا دانشگاهی خودت را اضافه کن.',
                        action: english ? 'Add book' : 'افزودن کتاب',
                        onTap: () => _editBook(context, ref),
                      )
                    : Column(
                        children: books
                            .map(
                              (book) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.menu_book_rounded,
                                    color: AppColors.emerald,
                                  ),
                                  title: Text(book.title),
                                  subtitle: Text(
                                    '${educationGrades[book.grade] ?? book.grade} · ${book.subject}',
                                  ),
                                  onTap: () => _editBook(context, ref, book),
                                  trailing: IconButton(
                                    tooltip: english
                                        ? 'Delete book'
                                        : 'حذف کتاب',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 19,
                                    ),
                                    onPressed: () async {
                                      final remove = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            english
                                                ? 'Delete this book?'
                                                : 'این کتاب حذف شود؟',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                english ? 'Cancel' : 'انصراف',
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                english ? 'Delete' : 'حذف',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (remove == true) {
                                        final db = ref.read(databaseProvider);
                                        await (db.delete(db.books)..where(
                                              (row) => row.id.equals(book.id),
                                            ))
                                            .go();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                error: (_, _) => Text(
                  english
                      ? 'Could not load books. Try again.'
                      : 'خواندن کتاب‌ها انجام نشد. دوباره تلاش کن.',
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProfileSetupPage(
            user: ref.read(cloudUserProvider).asData?.value,
            editing: true,
          ),
        ),
      );

  Future<void> _editBook(
    BuildContext context,
    WidgetRef ref, [
    Book? book,
  ]) async {
    final english = ref.read(languageProvider);
    final prefs = {
      for (final p
          in ref.read(preferencesProvider).asData?.value ?? <AppPreference>[])
        p.key: p.value,
    };
    final title = TextEditingController(text: book?.title);
    final subject = TextEditingController(
      text: book?.subject ?? prefs['profile.subject'],
    );
    var grade = book?.grade ?? prefs['profile.grade'] ?? '12';
    if (!educationGrades.containsKey(grade)) grade = '12';
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          english
              ? (book == null ? 'New book' : 'Edit book')
              : (book == null ? 'کتاب جدید' : 'ویرایش کتاب'),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: english ? 'Book title' : 'نام کتاب',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? (english ? 'Enter a title' : 'نام کتاب لازم است')
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: grade,
                  items: educationGrades.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(english ? e.key : e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => grade = v!,
                  decoration: InputDecoration(
                    labelText: english ? 'Education level' : 'پایهٔ تحصیلی',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subject,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: english ? 'Subject' : 'درس',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(english ? 'Cancel' : 'انصراف'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: Text(english ? 'Save' : 'ذخیره'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final db = ref.read(databaseProvider);
      await db
          .into(db.books)
          .insertOnConflictUpdate(
            BooksCompanion.insert(
              id: book?.id ?? const Uuid().v4(),
              title: title.text.trim(),
              grade: grade,
              subject: Value(subject.text.trim()),
            ),
          );
    }
  }
}
