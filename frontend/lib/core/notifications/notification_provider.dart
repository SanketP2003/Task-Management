import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

const _notificationsEnabledKey = 'notifications_enabled';

class NotificationSettingsNotifier extends AsyncNotifier<bool> {
  late SharedPreferences _prefs;

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    final notificationsAvailable =
        await NotificationService.instance.initialize();
    final enabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    if (enabled && notificationsAvailable) {
      await NotificationService.instance.requestPermissions();
    }
    return enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncValue.data(enabled);
    await _prefs.setBool(_notificationsEnabledKey, enabled);
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    } else {
      await NotificationService.instance.cancelAllNotifications();
    }
  }

  Future<void> toggle() async {
    final enabled = state.valueOrNull ?? true;
    await setEnabled(!enabled);
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, bool>(
  NotificationSettingsNotifier.new,
);
