{{flutter_js}}
{{flutter_build_config}}

// CanvasKit se sirve junto con la app, tanto en desarrollo como al publicar.
// document.baseURI respeta <base href> incluso al abrir una ruta interna.
// Evita que un bloqueo de gstatic.com impida iniciar toda la aplicación.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href,
  },
});
