// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memoryRepository)
const memoryRepositoryProvider = MemoryRepositoryProvider._();

final class MemoryRepositoryProvider extends $FunctionalProvider<
    MemoryRepository,
    MemoryRepository,
    MemoryRepository> with $Provider<MemoryRepository> {
  const MemoryRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'memoryRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemoryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoryRepository create(Ref ref) {
    return memoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoryRepository>(value),
    );
  }
}

String _$memoryRepositoryHash() => r'f5b3b8bee57f3f07bd83f9627ebb6e1ea0bf112e';

@ProviderFor(myMemories)
const myMemoriesProvider = MyMemoriesProvider._();

final class MyMemoriesProvider extends $FunctionalProvider<
        AsyncValue<List<Memory>>, List<Memory>, FutureOr<List<Memory>>>
    with $FutureModifier<List<Memory>>, $FutureProvider<List<Memory>> {
  const MyMemoriesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'myMemoriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myMemoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<Memory>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Memory>> create(Ref ref) {
    return myMemories(ref);
  }
}

String _$myMemoriesHash() => r'6606d44cd533ceffb8fbd552b4d252ae68d97854';

@ProviderFor(memorySummary)
const memorySummaryProvider = MemorySummaryProvider._();

final class MemorySummaryProvider extends $FunctionalProvider<
        AsyncValue<MemorySummary>, MemorySummary, FutureOr<MemorySummary>>
    with $FutureModifier<MemorySummary>, $FutureProvider<MemorySummary> {
  const MemorySummaryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'memorySummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memorySummaryHash();

  @$internal
  @override
  $FutureProviderElement<MemorySummary> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MemorySummary> create(Ref ref) {
    return memorySummary(ref);
  }
}

String _$memorySummaryHash() => r'ffac37c1cb8751e6f9d7c679113bddc351b64dbf';

@ProviderFor(memoryDetail)
const memoryDetailProvider = MemoryDetailFamily._();

final class MemoryDetailProvider
    extends $FunctionalProvider<AsyncValue<Memory>, Memory, FutureOr<Memory>>
    with $FutureModifier<Memory>, $FutureProvider<Memory> {
  const MemoryDetailProvider._(
      {required MemoryDetailFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'memoryDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memoryDetailHash();

  @override
  String toString() {
    return r'memoryDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Memory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Memory> create(Ref ref) {
    final argument = this.argument as String;
    return memoryDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemoryDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memoryDetailHash() => r'da65f01b12cf09e71ebf9ae436fd860e85d992a7';

final class MemoryDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Memory>, String> {
  const MemoryDetailFamily._()
      : super(
          retry: null,
          name: r'memoryDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MemoryDetailProvider call(
    String id,
  ) =>
      MemoryDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'memoryDetailProvider';
}

@ProviderFor(groupMemories)
const groupMemoriesProvider = GroupMemoriesFamily._();

final class GroupMemoriesProvider extends $FunctionalProvider<
        AsyncValue<List<Memory>>, List<Memory>, FutureOr<List<Memory>>>
    with $FutureModifier<List<Memory>>, $FutureProvider<List<Memory>> {
  const GroupMemoriesProvider._(
      {required GroupMemoriesFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'groupMemoriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$groupMemoriesHash();

  @override
  String toString() {
    return r'groupMemoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Memory>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Memory>> create(Ref ref) {
    final argument = this.argument as String;
    return groupMemories(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMemoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupMemoriesHash() => r'fb38e322951f07cb8162ea0b334c52ce22f6b5c1';

final class GroupMemoriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Memory>>, String> {
  const GroupMemoriesFamily._()
      : super(
          retry: null,
          name: r'groupMemoriesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  GroupMemoriesProvider call(
    String groupId,
  ) =>
      GroupMemoriesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupMemoriesProvider';
}

@ProviderFor(MemoryCreator)
const memoryCreatorProvider = MemoryCreatorProvider._();

final class MemoryCreatorProvider
    extends $AsyncNotifierProvider<MemoryCreator, Memory?> {
  const MemoryCreatorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'memoryCreatorProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memoryCreatorHash();

  @$internal
  @override
  MemoryCreator create() => MemoryCreator();
}

String _$memoryCreatorHash() => r'190e490ab8de09045dff68e384bc1f74ba88a078';

abstract class _$MemoryCreator extends $AsyncNotifier<Memory?> {
  FutureOr<Memory?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Memory?>, Memory?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Memory?>, Memory?>,
        AsyncValue<Memory?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
