// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uploadRepository)
const uploadRepositoryProvider = UploadRepositoryProvider._();

final class UploadRepositoryProvider extends $FunctionalProvider<
    UploadRepository,
    UploadRepository,
    UploadRepository> with $Provider<UploadRepository> {
  const UploadRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'uploadRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$uploadRepositoryHash();

  @$internal
  @override
  $ProviderElement<UploadRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UploadRepository create(Ref ref) {
    return uploadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadRepository>(value),
    );
  }
}

String _$uploadRepositoryHash() => r'4674ad7c1025c250abb3e28ade174f27f4e325a3';
