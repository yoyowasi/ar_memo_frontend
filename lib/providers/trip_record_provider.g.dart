// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_record_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tripRecordRepositoryHash() =>
    r'3f9cddf24638e3ba4154c0966373b3787f6b41e5';

/// See also [tripRecordRepository].
@ProviderFor(tripRecordRepository)
final tripRecordRepositoryProvider =
    AutoDisposeProvider<TripRecordRepository>.internal(
  tripRecordRepository,
  name: r'tripRecordRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tripRecordRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TripRecordRepositoryRef = AutoDisposeProviderRef<TripRecordRepository>;
String _$tripRecordDetailHash() => r'e55beea33244c3bdc0559639de0ac9deae90d713';

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

/// See also [tripRecordDetail].
@ProviderFor(tripRecordDetail)
const tripRecordDetailProvider = TripRecordDetailFamily();

/// See also [tripRecordDetail].
class TripRecordDetailFamily extends Family<AsyncValue<TripRecord>> {
  /// See also [tripRecordDetail].
  const TripRecordDetailFamily();

  /// See also [tripRecordDetail].
  TripRecordDetailProvider call(
    String id,
  ) {
    return TripRecordDetailProvider(
      id,
    );
  }

  @override
  TripRecordDetailProvider getProviderOverride(
    covariant TripRecordDetailProvider provider,
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
  String? get name => r'tripRecordDetailProvider';
}

/// See also [tripRecordDetail].
class TripRecordDetailProvider extends AutoDisposeFutureProvider<TripRecord> {
  /// See also [tripRecordDetail].
  TripRecordDetailProvider(
    String id,
  ) : this._internal(
          (ref) => tripRecordDetail(
            ref as TripRecordDetailRef,
            id,
          ),
          from: tripRecordDetailProvider,
          name: r'tripRecordDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tripRecordDetailHash,
          dependencies: TripRecordDetailFamily._dependencies,
          allTransitiveDependencies:
              TripRecordDetailFamily._allTransitiveDependencies,
          id: id,
        );

  TripRecordDetailProvider._internal(
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
    FutureOr<TripRecord> Function(TripRecordDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TripRecordDetailProvider._internal(
        (ref) => create(ref as TripRecordDetailRef),
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
  AutoDisposeFutureProviderElement<TripRecord> createElement() {
    return _TripRecordDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TripRecordDetailProvider && other.id == id;
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
mixin TripRecordDetailRef on AutoDisposeFutureProviderRef<TripRecord> {
  /// The parameter `id` of this provider.
  String get id;
}

class _TripRecordDetailProviderElement
    extends AutoDisposeFutureProviderElement<TripRecord>
    with TripRecordDetailRef {
  _TripRecordDetailProviderElement(super.provider);

  @override
  String get id => (origin as TripRecordDetailProvider).id;
}

String _$tripRecordsHash() => r'f0ae5196018de105ac780074fe49b2869661a45b';

/// See also [TripRecords].
@ProviderFor(TripRecords)
final tripRecordsProvider =
    AutoDisposeAsyncNotifierProvider<TripRecords, List<TripRecord>>.internal(
  TripRecords.new,
  name: r'tripRecordsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tripRecordsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TripRecords = AutoDisposeAsyncNotifier<List<TripRecord>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
