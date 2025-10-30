// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memoryRepositoryHash() => r'f5b3b8bee57f3f07bd83f9627ebb6e1ea0bf112e';

/// See also [memoryRepository].
@ProviderFor(memoryRepository)
final memoryRepositoryProvider = AutoDisposeProvider<MemoryRepository>.internal(
  memoryRepository,
  name: r'memoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$memoryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MemoryRepositoryRef = AutoDisposeProviderRef<MemoryRepository>;
String _$myMemoriesHash() => r'6606d44cd533ceffb8fbd552b4d252ae68d97854';

/// See also [myMemories].
@ProviderFor(myMemories)
final myMemoriesProvider = AutoDisposeFutureProvider<List<Memory>>.internal(
  myMemories,
  name: r'myMemoriesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myMemoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyMemoriesRef = AutoDisposeFutureProviderRef<List<Memory>>;
String _$memorySummaryHash() => r'ffac37c1cb8751e6f9d7c679113bddc351b64dbf';

/// See also [memorySummary].
@ProviderFor(memorySummary)
final memorySummaryProvider = AutoDisposeFutureProvider<MemorySummary>.internal(
  memorySummary,
  name: r'memorySummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$memorySummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MemorySummaryRef = AutoDisposeFutureProviderRef<MemorySummary>;
String _$memoryDetailHash() => r'da65f01b12cf09e71ebf9ae436fd860e85d992a7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [memoryDetail].
@ProviderFor(memoryDetail)
const memoryDetailProvider = MemoryDetailFamily();

/// See also [memoryDetail].
class MemoryDetailFamily extends Family<AsyncValue<Memory>> {
  /// See also [memoryDetail].
  const MemoryDetailFamily();

  /// See also [memoryDetail].
  MemoryDetailProvider call(
    String id,
  ) {
    return MemoryDetailProvider(
      id,
    );
  }

  @override
  MemoryDetailProvider getProviderOverride(
    covariant MemoryDetailProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'memoryDetailProvider';
}

/// See also [memoryDetail].
class MemoryDetailProvider extends AutoDisposeFutureProvider<Memory> {
  /// See also [memoryDetail].
  MemoryDetailProvider(
    String id,
  ) : this._internal(
          (ref) => memoryDetail(
            ref as MemoryDetailRef,
            id,
          ),
          from: memoryDetailProvider,
          name: r'memoryDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$memoryDetailHash,
          dependencies: MemoryDetailFamily._dependencies,
          allTransitiveDependencies:
              MemoryDetailFamily._allTransitiveDependencies,
          id: id,
        );

  MemoryDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Memory> Function(MemoryDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MemoryDetailProvider._internal(
        (ref) => create(ref as MemoryDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Memory> createElement() {
    return _MemoryDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MemoryDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MemoryDetailRef on AutoDisposeFutureProviderRef<Memory> {
  /// The parameter `id` of this provider.
  String get id;
}

class _MemoryDetailProviderElement
    extends AutoDisposeFutureProviderElement<Memory> with MemoryDetailRef {
  _MemoryDetailProviderElement(super.provider);

  @override
  String get id => (origin as MemoryDetailProvider).id;
}

String _$groupMemoriesHash() => r'fb38e322951f07cb8162ea0b334c52ce22f6b5c1';

/// See also [groupMemories].
@ProviderFor(groupMemories)
const groupMemoriesProvider = GroupMemoriesFamily();

/// See also [groupMemories].
class GroupMemoriesFamily extends Family<AsyncValue<List<Memory>>> {
  /// See also [groupMemories].
  const GroupMemoriesFamily();

  /// See also [groupMemories].
  GroupMemoriesProvider call(
    String groupId,
  ) {
    return GroupMemoriesProvider(
      groupId,
    );
  }

  @override
  GroupMemoriesProvider getProviderOverride(
    covariant GroupMemoriesProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupMemoriesProvider';
}

/// See also [groupMemories].
class GroupMemoriesProvider extends AutoDisposeFutureProvider<List<Memory>> {
  /// See also [groupMemories].
  GroupMemoriesProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupMemories(
            ref as GroupMemoriesRef,
            groupId,
          ),
          from: groupMemoriesProvider,
          name: r'groupMemoriesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMemoriesHash,
          dependencies: GroupMemoriesFamily._dependencies,
          allTransitiveDependencies:
              GroupMemoriesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupMemoriesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    FutureOr<List<Memory>> Function(GroupMemoriesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupMemoriesProvider._internal(
        (ref) => create(ref as GroupMemoriesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Memory>> createElement() {
    return _GroupMemoriesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMemoriesProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupMemoriesRef on AutoDisposeFutureProviderRef<List<Memory>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupMemoriesProviderElement
    extends AutoDisposeFutureProviderElement<List<Memory>>
    with GroupMemoriesRef {
  _GroupMemoriesProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupMemoriesProvider).groupId;
}

String _$memoryCreatorHash() => r'28969acc0f539d04f5ad061bf4aa3b4596896f4a';

/// See also [MemoryCreator].
@ProviderFor(MemoryCreator)
final memoryCreatorProvider =
    AutoDisposeAsyncNotifierProvider<MemoryCreator, Memory?>.internal(
  MemoryCreator.new,
  name: r'memoryCreatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$memoryCreatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MemoryCreator = AutoDisposeAsyncNotifier<Memory?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
