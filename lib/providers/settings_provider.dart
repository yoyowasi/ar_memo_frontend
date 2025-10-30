import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

class NotificationSettings {
  final bool pushEnabled;
  final bool diaryReminderEnabled;
  final bool groupActivityEnabled;

  const NotificationSettings({
    required this.pushEnabled,
    required this.diaryReminderEnabled,
    required this.groupActivityEnabled,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? diaryReminderEnabled,
    bool? groupActivityEnabled,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      diaryReminderEnabled: diaryReminderEnabled ?? this.diaryReminderEnabled,
      groupActivityEnabled: groupActivityEnabled ?? this.groupActivityEnabled,
    );
  }
}

@riverpod
class NotificationSettingsController
    extends _$NotificationSettingsController {
  static const _pushKey = 'notifications_push_enabled';
  static const _diaryKey = 'notifications_diary_reminder';
  static const _groupKey = 'notifications_group_activity';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(key, value);
  }

  @override
  FutureOr<NotificationSettings> build() async {
    final prefs = await _ensurePrefs();
    return NotificationSettings(
      pushEnabled: prefs.getBool(_pushKey) ?? true,
      diaryReminderEnabled: prefs.getBool(_diaryKey) ?? true,
      groupActivityEnabled: prefs.getBool(_groupKey) ?? true,
    );
  }

  Future<void> updatePushEnabled(bool value) async {
    final current = await future;
    state = AsyncData(current.copyWith(pushEnabled: value));
    await _save(_pushKey, value);
  }

  Future<void> updateDiaryReminder(bool value) async {
    final current = await future;
    state = AsyncData(current.copyWith(diaryReminderEnabled: value));
    await _save(_diaryKey, value);
  }

  Future<void> updateGroupActivity(bool value) async {
    final current = await future;
    state = AsyncData(current.copyWith(groupActivityEnabled: value));
    await _save(_groupKey, value);
  }
}
