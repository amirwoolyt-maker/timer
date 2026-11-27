import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_theme.dart';
import '../core/state/app_state.dart';
import '../core/utils/alarm_challenge.dart';
import '../core/utils/formatters.dart';
import '../core/utils/study_clock.dart';
import '../core/platform/platform_services.dart';
import '../core/platform/task_reminders.dart';
import '../data/online/online_backend.dart';
import '../data/local/app_database.dart';
import '../data/catalog/iran_universities.dart';
import '../data/repositories/providers.dart';
import 'online/account_page.dart';
import 'online/profile_setup_page.dart';
import 'online/cloud_hub_page.dart';

part 'tasks/presentation/tasks_page.dart';
part 'notes/presentation/notes_page.dart';
part 'timers/presentation/timer_pages.dart';
part 'social/presentation/community_page.dart';
part 'more/presentation/more_pages.dart';
part 'more/presentation/university_directory_page.dart';
part 'profile/presentation/profile_page.dart';

Future<void> _restoreNote(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  try {
    await ref.read(databaseProvider).restoreNote(id);
  } catch (error) {
    if (context.mounted) {
      _toolNotice(
        context,
        error is StateError && error.message == 'NOTE_LIMIT'
            ? 'سقف ۱۵ یادداشت پر است؛ اول یکی را به سطل زباله منتقل کن.'
            : 'بازیابی انجام نشد؛ دوباره تلاش کن.',
      );
    }
  }
}

/// Keep dialog controllers alive until the route has finished its exit animation.
class _DialogControllers extends StatefulWidget {
  const _DialogControllers({required this.controllers, required this.child});
  final List<TextEditingController> controllers;
  final Widget child;
  @override
  State<_DialogControllers> createState() => _DialogControllersState();
}

class _DialogControllersState extends State<_DialogControllers> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

const featureTitles = <String, String>{
  'dashboard': 'داشبورد آمار',
  'calendar': 'تقویم جلالی',
  'studyTimer': 'تایمر درس',
  'league': 'مطالعهٔ همراهان',
  'projects': 'پروژه‌ها',
  'studyRoom': 'اتاق مطالعه',
  'templates': 'الگوها',
  'trash': 'سطل زباله',
  'resources': 'منابع درسی',
  'uniRanking': 'شناخت دانشگاه‌ها',
  'chat': 'چت با کنکوری‌ها',
  'focus': 'حالت تمرکز',
  'location': 'یادآور مکان',
  'smartAlarm': 'بیدار شو!',
  'period': 'چرخه پریود',
  'profile': 'پروفایل',
  'account': 'حساب کاربری',
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
  'account': 'Account',
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
    final compact =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(10.5) > 12;
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(AppTab.values.length, (index) {
          final active = selected.index == index;
          return Expanded(
            child: Semantics(
              button: true,
              selected: active,
              label: labels[index],
              child: Tooltip(
                message: labels[index],
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelect(AppTab.values[index]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 50),
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
                        AnimatedScale(
                          scale: active ? 1.1 : 1,
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          child: Icon(
                            icons[index],
                            size: 21,
                            color: active ? AppColors.emerald : AppColors.muted,
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 3),
                          Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: active
                                  ? AppColors.emerald
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
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
        color: Theme.of(context).colorScheme.surface,
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
      color: Theme.of(context).colorScheme.surface,
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
      color: Theme.of(context).colorScheme.surface,
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
