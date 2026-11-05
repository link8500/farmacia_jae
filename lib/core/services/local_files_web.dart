import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Descarga exclusivamente datos locales mediante Blob, sin peticiones de red.
bool downloadText(
  String name,
  String content, {
  String type = 'text/plain;charset=utf-8',
}) {
  final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: type));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  anchor.click();
  Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  return true;
}

Future<String?> selectBackupFile() {
  final result = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json';
  input.onchange = ((web.Event event) {
    final file = input.files?.item(0);
    if (file == null) {
      if (!result.isCompleted) result.complete(null);
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      result.completeError(const FormatException('Máximo 5 MB.'));
      return;
    }
    file.text().toDart.then(
      (text) {
        if (!result.isCompleted) result.complete(text.toDart);
      },
      onError: (Object error) {
        if (!result.isCompleted) result.completeError(error);
      },
    );
  }).toJS;
  input.oncancel = ((web.Event event) {
    if (!result.isCompleted) result.complete(null);
  }).toJS;
  input.click();
  return result.future;
}

/// Documento generado por la aplicación con valores escapados, nunca HTML del
/// respaldo. Una ventana bloqueada devuelve false para informar al usuario.
bool printDocument(String html) {
  final popup = web.window.open('', '_blank');
  if (popup == null) return false;
  popup.document.write(html.toJS);
  popup.document.close();
  Timer(const Duration(milliseconds: 200), () {
    popup.focus();
    popup.print();
  });
  return true;
}
