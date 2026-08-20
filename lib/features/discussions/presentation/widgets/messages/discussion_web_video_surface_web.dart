import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewTypes = <String>{};

Widget buildDiscussionWebVideoSurface({
  required String viewType,
  required Uri uri,
}) {
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final video = web.HTMLVideoElement()
        ..src = uri.toString()
        ..controls = true
        ..autoplay = false
        ..muted = false
        ..preload = 'metadata'
        ..tabIndex = 0
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.display = 'block'
        ..style.backgroundColor = '#000'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..setAttribute('disablepictureinpicture', 'false')
        ..setAttribute('controlsList', 'nodownload');

      return video;
    });
  }

  return HtmlElementView(viewType: viewType);
}
