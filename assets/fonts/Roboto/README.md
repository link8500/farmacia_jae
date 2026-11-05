# Roboto local

`Roboto-Regular.ttf` y `Roboto-Medium.ttf` son las fuentes Roboto sin modificar
incluidas en `engine/src/flutter/txt/third_party/fonts/` del SDK de Flutter.
Proyecto original: https://github.com/googlefonts/roboto
Se distribuyen bajo Apache License 2.0; ver `LICENSE.txt`.

Flutter Web busca la familia `Roboto` al inicializar CanvasKit y, si no aparece
en el manifiesto, intenta descargarla de Google. La declaración en
`pubspec.yaml` permite cargar esta fuente de respaldo desde el propio servidor.
