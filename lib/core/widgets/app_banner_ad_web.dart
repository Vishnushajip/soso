// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import '../ads/ad_config.dart';

const double _bannerHeight = 90;
final Set<String> _registered = {};

/// Renders an AdSense display unit inside a Flutter platform view.
/// Returns an empty box until [AdConfig.adSenseBannerSlot] is configured.
Widget buildWebBanner(String placement) {
  const slot = AdConfig.adSenseBannerSlot;
  if (slot.isEmpty) return const SizedBox.shrink();

  final viewType = 'adsense-banner-$placement';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.height = '${_bannerHeight.toInt()}px'
        ..setAttribute('data-ad-client', AdConfig.adSenseClientId)
        ..setAttribute('data-ad-slot', slot)
        ..setAttribute('data-ad-format', 'horizontal')
        ..setAttribute('data-full-width-responsive', 'false');

      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..append(ins);

      // adsbygoogle can only fill an <ins> that is attached to the document,
      // so wait until Flutter has mounted the platform view before pushing.
      var tries = 0;
      Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (ins.isConnected ?? false) {
          t.cancel();
          container.append(
            html.ScriptElement()
              ..text = '(adsbygoogle = window.adsbygoogle || []).push({});',
          );
        } else if (++tries > 50) {
          t.cancel();
        }
      });
      return container;
    });
  }

  return SizedBox(
    height: _bannerHeight,
    child: HtmlElementView(viewType: viewType),
  );
}
