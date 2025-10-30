// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationSettingsController)
const notificationSettingsControllerProvider =
    NotificationSettingsControllerProvider._();

final class NotificationSettingsControllerProvider
    extends $AsyncNotifierProvider<NotificationSettingsController,
        NotificationSettings> {
  const NotificationSettingsControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationSettingsControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsControllerHash();

  @$internal
  @override
  NotificationSettingsController create() => NotificationSettingsController();
}

String _$notificationSettingsControllerHash() =>
    r'82503e1ba8b41e19c707db02cda56a903b674546';

abstract class _$NotificationSettingsController
    extends $AsyncNotifier<NotificationSettings> {
  FutureOr<NotificationSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref
        as $Ref<AsyncValue<NotificationSettings>, NotificationSettings>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<NotificationSettings>, NotificationSettings>,
        AsyncValue<NotificationSettings>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
