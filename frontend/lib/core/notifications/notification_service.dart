import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = true;

  static const int _taskReminderIdOffset = 100000;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'task_updates_channel',
    'Task Updates',
    channelDescription: 'Notifications for task creation and updates',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  Future<bool> initialize() async {
    if (_initialized) {
      return _available;
    }

    try {
      tz_data.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(settings);
      _available = true;
    } on MissingPluginException {
      _available = false;
    } on AssertionError {
      _available = false;
    } catch (_) {
      _available = false;
    } finally {
      _initialized = true;
    }

    return _available;
  }

  Future<void> requestPermissions() async {
    if (!await initialize()) {
      return;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showTaskCreated(String title) async {
    await _show(
      id: _idFor('created', title),
      title: 'Task created',
      body: title,
    );
  }

  Future<void> showTaskUpdated(String title) async {
    await _show(
      id: _idFor('updated', title),
      title: 'Task updated',
      body: title,
    );
  }

  Future<void> showTaskDeleted(String title) async {
    await _show(
      id: _idFor('deleted', title),
      title: 'Task deleted',
      body: title,
    );
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (!await initialize()) {
      return;
    }

    final reminderTime = _resolveReminderTime(dueDate);
    final zonedDateTime = tz.TZDateTime.from(reminderTime, tz.local);
    if (zonedDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      _taskReminderId(taskId),
      'Task reminder',
      title,
      zonedDateTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (!await initialize()) {
      return;
    }
    await _plugin.cancel(_taskReminderId(taskId));
  }

  Future<void> cancelAllNotifications() async {
    if (!await initialize()) {
      return;
    }
    await _plugin.cancelAll();
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!await initialize()) {
      return;
    }
    await _plugin.show(id, title, body, _notificationDetails);
  }

  int _idFor(String action, String title) {
    final seed = '$action:$title:${DateTime.now().millisecondsSinceEpoch}';
    return seed.hashCode & 0x7fffffff;
  }

  int _taskReminderId(int taskId) => _taskReminderIdOffset + taskId;

  DateTime _resolveReminderTime(DateTime dueDate) {
    final isDateOnly =
        dueDate.hour == 0 && dueDate.minute == 0 && dueDate.second == 0;
    if (isDateOnly) {
      return DateTime(dueDate.year, dueDate.month, dueDate.day, 9);
    }
    return dueDate;
  }
}
