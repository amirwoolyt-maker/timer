import '../../data/local/app_database.dart';
import 'platform_services.dart';

enum ReminderResult {
  scheduled,
  notNeeded,
  unsupported,
  permissionDenied,
  failed,
}

abstract final class TaskReminders {
  static Future<ReminderResult> sync(
    Task task, {
    bool requestPermission = false,
  }) async {
    if (!PlatformServices.supportsBackgroundAlarms) {
      return ReminderResult.unsupported;
    }
    try {
      if (task.completed ||
          task.deletedAt != null ||
          task.dueAt == null ||
          !task.dueAt!.isAfter(DateTime.now())) {
        await PlatformServices.cancelTask(task.id);
        return ReminderResult.notNeeded;
      }
      if (requestPermission &&
          !await PlatformServices.requestAlarmPermissions()) {
        return ReminderResult.permissionDenied;
      }
      final saved = await PlatformServices.scheduleTask(
        task.id,
        task.title,
        task.dueAt!,
        body: task.description,
      );
      return saved ? ReminderResult.scheduled : ReminderResult.failed;
    } catch (_) {
      return ReminderResult.failed;
    }
  }
}
