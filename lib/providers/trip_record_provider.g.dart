// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_record_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripRecordRepository)
const tripRecordRepositoryProvider = TripRecordRepositoryProvider._();

final class TripRecordRepositoryProvider extends $FunctionalProvider<
    TripRecordRepository,
    TripRecordRepository,
    TripRecordRepository> with $Provider<TripRecordRepository> {
  const TripRecordRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tripRecordRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tripRecordRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripRecordRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TripRecordRepository create(Ref ref) {
    return tripRecordRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripRecordRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripRecordRepository>(value),
    );
  }
}

String _$tripRecordRepositoryHash() =>
    r'3f9cddf24638e3ba4154c0966373b3787f6b41e5';

@ProviderFor(TripRecords)
const tripRecordsProvider = TripRecordsProvider._();

final class TripRecordsProvider
    extends $AsyncNotifierProvider<TripRecords, List<TripRecord>> {
  const TripRecordsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tripRecordsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tripRecordsHash();

  @$internal
  @override
  TripRecords create() => TripRecords();
}

String _$tripRecordsHash() => r'0da69ae54063fae92ede044b446ef2a6ebd0e342';

abstract class _$TripRecords extends $AsyncNotifier<List<TripRecord>> {
  FutureOr<List<TripRecord>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<TripRecord>>, List<TripRecord>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<TripRecord>>, List<TripRecord>>,
        AsyncValue<List<TripRecord>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(tripRecordDetail)
const tripRecordDetailProvider = TripRecordDetailFamily._();

final class TripRecordDetailProvider extends $FunctionalProvider<
        AsyncValue<TripRecord>, TripRecord, FutureOr<TripRecord>>
    with $FutureModifier<TripRecord>, $FutureProvider<TripRecord> {
  const TripRecordDetailProvider._(
      {required TripRecordDetailFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'tripRecordDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tripRecordDetailHash();

  @override
  String toString() {
    return r'tripRecordDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TripRecord> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TripRecord> create(Ref ref) {
    final argument = this.argument as String;
    return tripRecordDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripRecordDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripRecordDetailHash() => r'e55beea33244c3bdc0559639de0ac9deae90d713';

final class TripRecordDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TripRecord>, String> {
  const TripRecordDetailFamily._()
      : super(
          retry: null,
          name: r'tripRecordDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  TripRecordDetailProvider call(
    String id,
  ) =>
      TripRecordDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'tripRecordDetailProvider';
}
