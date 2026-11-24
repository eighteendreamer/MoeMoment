import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/image_storage.dart';
import '../features/care_solution/care_solution_service.dart';
import '../features/lens/lens_repository.dart';
import '../features/lens/lens_service.dart';
import '../features/reminder/reminder_scheduler.dart';
import '../features/updater/github_config.dart';
import '../features/updater/update_service.dart';

/// 应用级服务容器：统一组装依赖，经 Provider 注入。
class AppServices {
  AppServices({required this.db}) {
    lensRepository = LensRepository(db);
    careService = CareSolutionService(db);
    notifications = NotificationService(db);
    lensService = const LensService();
    imageStorage = ImageStorage();
    reminders = ReminderScheduler(
      notifications,
      lensRepository,
      lensService,
      careService,
    );
    updater = UpdateService(config: const GithubConfig());
  }

  final AppDatabase db;

  late final LensRepository lensRepository;
  late final LensService lensService;
  late final CareSolutionService careService;
  late final ImageStorage imageStorage;
  late final NotificationService notifications;
  late final ReminderScheduler reminders;
  late final UpdateService updater;
}

/// 在 Widget 树中获取服务容器的便捷入口。
class AppServicesScope {
  const AppServicesScope._();

  static AppServices of(BuildContext context) =>
      Provider.of<AppServices>(context, listen: false);

  static AppServices watch(BuildContext context) =>
      Provider.of<AppServices>(context);
}
