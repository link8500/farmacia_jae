import 'package:web/web.dart' as web;

/// Enlaces editoriales acotados; no ejecuta HTML ni URLs guardadas en respaldos.
bool openPublicLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      (uri.scheme != 'tel' &&
          !(uri.scheme == 'https' &&
              uri.host == 'www.google.com' &&
              uri.path == '/maps/search/'))) {
    return false;
  }
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  anchor.click();
  return true;
}
