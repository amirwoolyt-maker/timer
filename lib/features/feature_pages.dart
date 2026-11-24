import 'dart:async';
import 'package:drift/drift.dart' hide Column;
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/state/app_state.dart';
import '../core/utils/formatters.dart';
import '../data/local/app_database.dart';
import '../data/repositories/providers.dart';

part 'tasks/presentation/tasks_page.dart';
part 'notes/presentation/notes_page.dart';
part 'timers/presentation/timer_pages.dart';
part 'social/presentation/community_page.dart';
part 'more/presentation/more_pages.dart';

const featureTitles = <String, String>{
  'dashboard': 'داشبورد آمار',
  'calendar': 'تقویم جلالی',
  'studyTimer': 'تایمر درس',
  'league': 'لیگ رقابت',
  'projects': 'پروژه‌ها',
  'studyRoom': 'اتاق مطالعه',
  'templates': 'الگوها',
  'trash': 'سطل زباله',
  'resources': 'منابع درسی',
  'uniRanking': 'رتبه‌بندی دانشگاه‌ها',
  'chat': 'چت با کنکوری‌ها',
  'focus': 'حالت تمرکز',
  'location': 'یادآور مکان',
  'smartAlarm': 'بیدار شو!',
  'period': 'چرخه پریود',
  'profile': 'پروفایل',
};

const featureTitlesEn = <String, String>{
  'dashboard': 'Progress dashboard',
  'calendar': 'Jalali calendar',
  'studyTimer': 'Study timer',
  'league': 'Study league',
  'projects': 'Projects',
  'studyRoom': 'Study rooms',
  'templates': 'Templates',
  'trash': 'Trash',
  'resources': 'Study resources',
  'uniRanking': 'Universities',
  'chat': 'Community chat',
  'focus': 'Focus mode',
  'location': 'Place reminders',
  'smartAlarm': 'Smart alarm',
  'period': 'Cycle tracker',
  'profile': 'Profile',
};

class AppNavigation extends ConsumerWidget {
  const AppNavigation({
    required this.selected,
    required this.onSelect,
    super.key,
  });
  final AppTab selected;
  final ValueChanged<AppTab> onSelect;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(languageProvider)
        ? const ['Tasks', 'Focus', 'Notes', 'Community', 'More']
        : const ['کارها', 'تمرکز', 'یادداشت', 'همراهان', 'بیشتر'];
    const icons = [
      Icons.checklist_rounded,
      Icons.timer_outlined,
      Icons.sticky_note_2_outlined,
      Icons.groups_2_outlined,
      Icons.grid_view_rounded,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(AppTab.values.length, (index) {
          final active = selected.index == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(AppTab.values[index]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.emerald.withValues(alpha: .13)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 21,
                      color: active ? AppColors.emerald : AppColors.muted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10.5,
                        color: active ? AppColors.emerald : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, this.onTap, super.key});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 9),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.emerald,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(action!),
          ),
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title, subtitle, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(23),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, size: 36, color: AppColors.emerald),
        const SizedBox(height: 9),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 13),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 17),
          label: Text(action),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.emerald,
            side: const BorderSide(color: AppColors.emerald),
          ),
        ),
      ],
    ),
  );
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    super.key,
  });
  final IconData icon;
  final String title, subtitle;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageFrame(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Color(0x2234D399),
                child: Text('🌱', style: TextStyle(fontSize: 30)),
              ),
              SizedBox(height: 9),
              Text(
                'دانش‌آموز پرتلاش',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                'ریاضی · پایه دوازدهم',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        const InfoTile(
          icon: Icons.menu_book_outlined,
          title: 'کتاب‌های من',
          subtitle: 'ثبت کتاب‌ها برای استفاده در همه بخش‌ها',
          color: AppColors.emerald,
        ),
        const InfoTile(
          icon: Icons.edit_outlined,
          title: 'اطلاعات تحصیلی',
          subtitle: 'رشته و پایه',
          color: AppColors.purple,
        ),
        SectionTitle(
          'کتاب‌های ذخیره‌شده',
          action: 'افزودن',
          onTap: () => _addBook(context, ref),
        ),
        ref
            .watch(booksProvider)
            .when(
              data: (books) => books.isEmpty
                  ? const Text(
                      'هنوز کتابی اضافه نشده.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    )
                  : Column(
                      children: books
                          .map(
                            (book) => InfoTile(
                              icon: Icons.menu_book_rounded,
                              title: book.title,
                              subtitle: '${book.grade} · ${book.subject}',
                              color: AppColors.emerald,
                            ),
                          )
                          .toList(),
                    ),
              error: (error, _) => Text('$error'),
              loading: () =>
                  const CircularProgressIndicator(color: AppColors.emerald),
            ),
      ],
    ),
  );

  static Future<void> _addBook(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final grade = TextEditingController(text: 'دوازدهم');
    final subject = TextEditingController(text: 'ریاضی');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن کتاب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'نام کتاب'),
            ),
            TextField(
              controller: grade,
              decoration: const InputDecoration(labelText: 'مقطع'),
            ),
            TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'درس'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بی‌خیال'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, title.text.trim().isNotEmpty),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final db = ref.read(databaseProvider);
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            id: const Uuid().v4(),
            title: title.text.trim(),
            grade: grade.text.trim(),
            subject: Value(subject.text.trim()),
          ),
        );
  }
}
