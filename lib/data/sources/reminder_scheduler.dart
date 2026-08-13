import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../domain/services/reminder_schedule_calculator.dart';

/// 每日提醒调度契约（TECH_DOC §11.1）：初始化、每日排程、取消、权限引导。
///
/// 独立接口便于 Widget 测试注入桩（flutter_local_notifications 需平台通道）。
abstract interface class ReminderScheduler {
  /// 初始化通知插件与 timezone 数据（幂等）。
  Future<void> initialize();

  /// 按 [location] 时区排程每日 [hour]:[minute] 提醒（先取消旧任务再排新）。
  Future<void> scheduleDaily({
    required String timezoneName,
    required DateTime now,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  /// 取消每日提醒。
  Future<void> cancel();

  /// Android 13+：请求 POST_NOTIFICATIONS 运行时权限。
  Future<bool?> requestNotificationsPermission();

  /// 通知权限是否已授予（用户系统层关闭时用于引导，§11.1）。
  Future<bool?> areNotificationsEnabled();

  /// 跳转系统通知设置页（权限被拒后的引导入口）。
  Future<void> openNotificationSettings();
}

/// flutter_local_notifications 实现（TECH_DOC §11.1）。
///
/// - 时区：`initializeTimeZones` + 每次排程按 `settings.timezone` 的 location；
/// - 排程：`zonedSchedule(id: 1000, matchDateTimeComponents: time)`，
///   Android `inexactAllowWhileIdle`（不申请 SCHEDULE_EXACT_ALARM，见文档）；
/// - 权限：Android 13+ 经 `requestNotificationsPermission()` 申请，被拒后
///   `openAppNotificationSettings()` 引导。
class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    ReminderScheduleCalculator? calculator,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _calculator = calculator ?? const ReminderScheduleCalculator();

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderScheduleCalculator _calculator;

  /// timezone 初始化只需一次（全局数据表）。
  static bool _tzInitialized = false;

  @override
  Future<void> initialize() async {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    try {
      await _plugin.initialize(settings: settings);
    } catch (error) {
      // 通知插件初始化失败（如测试环境/平台异常）不阻塞学习核心闭环；
      // 排程调用仍会抛错，由设置页提示。
      AppLogger.warning('通知插件初始化失败：$error');
    }
  }

  @override
  Future<void> scheduleDaily({
    required String timezoneName,
    required DateTime now,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    await cancel();
    final location = tz.getLocation(timezoneName);
    final scheduled = _calculator.nextOccurrence(
      now: now,
      location: location,
      hour: hour,
      minute: minute,
    );
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.reminderNotificationChannelId,
        AppConstants.reminderNotificationChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      id: AppConstants.reminderNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    await initialize();
    await _plugin.cancel(id: AppConstants.reminderNotificationId);
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    // Android 13+ 才有该通道；其他平台（测试/桌面）返回 null，不视为拒绝。
    return await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<bool?> areNotificationsEnabled() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
  }

  @override
  Future<void> openNotificationSettings() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.openAppNotificationSettings();
  }
}
