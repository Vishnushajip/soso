import 'meta_pixel_stub.dart'
    if (dart.library.js_interop) 'meta_pixel_web.dart' as platform;

/// Abstract interface for browser-side Meta (Facebook) Pixel tracking.
abstract class MetaPixelService {
  factory MetaPixelService() => platform.createMetaPixelService();

  /// Standard Meta Pixel event (e.g. 'PageView', 'CompleteRegistration', 'StartTrial').
  Future<void> track(String event, [Map<String, Object?> params = const {}]);

  /// Custom Meta Pixel event (e.g. 'PlayGame', 'GuestStart', 'MatchComplete').
  Future<void> trackCustom(String event, [Map<String, Object?> params = const {}]);
}

