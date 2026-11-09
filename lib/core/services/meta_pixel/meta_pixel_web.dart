import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:uuid/uuid.dart';

import '../../constants/env.dart';
import 'meta_pixel_service.dart';

MetaPixelService createMetaPixelService() => MetaPixelServiceWeb();

/// Web implementation of [MetaPixelService] using `dart:js_interop`.
class MetaPixelServiceWeb implements MetaPixelService {
  MetaPixelServiceWeb({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  Future<void> track(String event, [Map<String, Object?> params = const {}]) async {
    _send('track', event, params);
  }

  @override
  Future<void> trackCustom(String event, [Map<String, Object?> params = const {}]) async {
    _send('trackCustom', event, params);
  }

  void _send(String method, String event, Map<String, Object?> params) {
    if (!Env.enableMetaPixel) return;
    try {
      if (!globalContext.has('fbq')) return;

      final cleanParams = <String, Object>{};
      for (final entry in params.entries) {
        final val = entry.value;
        if (val != null) {
          cleanParams[entry.key] = val;
        }
      }

      final eventId = _uuid.v4();
      final jsParams = cleanParams.jsify();
      final jsOptions = {'eventID': eventId}.jsify();

      globalContext.callMethod<JSAny?>(
        'fbq'.toJS,
        method.toJS,
        event.toJS,
        jsParams,
        jsOptions,
      );
    } catch (_) {
      // Ad blockers or missing fbq: swallow and no-op.
    }
  }
}

