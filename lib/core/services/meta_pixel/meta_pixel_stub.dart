import 'meta_pixel_service.dart';

MetaPixelService createMetaPixelService() => const MetaPixelServiceStub();

/// No-op implementation of [MetaPixelService] for non-web platforms (mobile/desktop).
class MetaPixelServiceStub implements MetaPixelService {
  const MetaPixelServiceStub();

  @override
  Future<void> track(String event, [Map<String, Object?> params = const {}]) async {}

  @override
  Future<void> trackCustom(String event, [Map<String, Object?> params = const {}]) async {}
}

