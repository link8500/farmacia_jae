import 'dart:ui';

import 'package:web/web.dart' as web;

/// Declara el esquema que Flutter está pintando. Así el navegador puede
/// combinar sus controles con la app y aplicar filtros externos al lienzo.
void updateBrowserAppearance({Color? background, bool dark = false}) {
  final scheme = dark ? 'dark' : 'light';
  final cssBackground = background == null
      ? '#ffffff'
      : '#${(background.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
  final root = web.document.documentElement as web.HTMLElement?;
  root?.style.setProperty('color-scheme', scheme);
  root?.style.setProperty('background-color', cssBackground);
  web.document
      .querySelector('meta[name="color-scheme"]')
      ?.setAttribute('content', scheme);
  web.document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute('content', background == null ? '#167b57' : cssBackground);
}
