// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(groupRepository)
const groupRepositoryProvider = GroupRepositoryProvider._();

final class GroupRepositoryProvider extends $FunctionalProvider<GroupRepository,
    GroupRepository, GroupRepository> with $Provider<GroupRepository> {
  const GroupRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'groupRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$groupRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupRepository create(Ref ref) {
    return groupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupRepository>(value),
    );
  }
}

String _$groupRepositoryHash() => r'35cb72c3a9119cc329384fff8023e1db2751dc1b';

@ProviderFor(myGroups)
const myGroupsProvider = MyGroupsProvider._();

final class MyGroupsProvider extends $FunctionalProvider<
        AsyncValue<List<Group>>, List<Group>, FutureOr<List<Group>>>
    with $FutureModifier<List<Group>>, $FutureProvider<List<Group>> {
  const MyGroupsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'myGroupsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<Group>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Group>> create(Ref ref) {
    return myGroups(ref);
  }
}

String _$myGroupsHash() => r'7431ab9070505ec99f8f563fe5d648a37f1102f6';

@ProviderFor(groupDetail)
const groupDetailProvider = GroupDetailFamily._();

final class GroupDetailProvider
    extends $FunctionalProvider<AsyncValue<Group>, Group, FutureOr<Group>>
    with $FutureModifier<Group>, $FutureProvider<Group> {
  const GroupDetailProvider._(
      {required GroupDetailFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'groupDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$groupDetailHash();

  @override
  String toString() {
    return r'groupDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Group> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Group> create(Ref ref) {
    final argument = this.argument as String;
    return groupDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupDetailHash() => r'95958fd4d72d9df4e623d61b6c33b50461f74cb4';

final class GroupDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Group>, String> {
  const GroupDetailFamily._()
      : super(
          retry: null,
          name: r'groupDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  GroupDetailProvider call(
    String id,
  ) =>
      GroupDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'groupDetailProvider';
}
