import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/providers/settings_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 1,
      ),
      body: settingsAsync.when(
        data: (settings) {
          final controller =
              ref.read(notificationSettingsControllerProvider.notifier);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                '원하는 알림만 골라 받아보세요.',
                style: bodyText2.copyWith(color: subTextColor),
              ),
              const SizedBox(height: 24),
              SwitchListTile.adaptive(
                value: settings.pushEnabled,
                onChanged: (value) => controller.updatePushEnabled(value),
                title: const Text('푸시 알림'),
                subtitle: const Text('앱 전체 알림 수신 여부를 설정합니다.'),
                activeColor: primaryColor,
              ),
              const Divider(height: 32),
              SwitchListTile.adaptive(
                value: settings.diaryReminderEnabled,
                onChanged: settings.pushEnabled
                    ? (value) => controller.updateDiaryReminder(value)
                    : null,
                title: const Text('일기 작성 알림'),
                subtitle: const Text('일기 작성을 잊지 않도록 알림을 받을게요.'),
                activeColor: primaryColor,
              ),
              SwitchListTile.adaptive(
                value: settings.groupActivityEnabled,
                onChanged: settings.pushEnabled
                    ? (value) => controller.updateGroupActivity(value)
                    : null,
                title: const Text('그룹 활동 알림'),
                subtitle: const Text('그룹에 새로운 활동이 있을 때 알려드립니다.'),
                activeColor: primaryColor,
              ),
              if (!settings.pushEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '푸시 알림이 꺼져 있어 세부 알림은 사용할 수 없습니다.',
                    style: bodyText2.copyWith(color: Colors.redAccent),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text('알림 설정을 불러오지 못했습니다.\n$err',
                    textAlign: TextAlign.center, style: bodyText2),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(notificationSettingsControllerProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
