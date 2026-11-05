# Fotos y datos de demostración

Las 28 fotos de personas proceden de Random User / UI Faces:
https://randomuser.me/copyright. Los nombres, documentos y contactos de la app
son ficticios y no describen a las personas fotografiadas. Los documentos llevan
el prefijo `DEMO-`; no son cédulas reales ni imágenes de documentos oficiales.

Las tres fotografías editoriales de promociones proceden de Unsplash, bajo su
licencia: https://unsplash.com/license.

- Bienestar: Natallia Photo, https://unsplash.com/photos/UvEgtPspFrY.
- Botiquín: Kristine Wook, https://unsplash.com/photos/ZyxNWi3JCto.
- Cuidado: Apothecary 87 / Andrew Jackson, https://unsplash.com/photos/QS7mFJi2Vlk.

Las marcas de las fotos no identifican el inventario ni indican una relación
comercial con la farmacia. Los envases de productos continúan usando las ocho
ilustraciones locales de demostración, ahora también en sus detalles y lotes.
Las alertas de inventario del Resumen comparten estas mismas miniaturas.

## Descargas y presentación

`tool/download_demo_media.py` descarga únicamente los recursos enumerados en
`tool/demo_media_sources.json`. Conserva la procedencia, el tamaño y el SHA-256
en `images/DEMO_MEDIA_SOURCES.json`. No requiere API keys. Los archivos se
incluyen en el bundle; la aplicación utiliza `Image.asset`.

Las fotos de contactos y personal se comparten entre listado y detalle.
El perfil utiliza la foto local inicial y permite sustituirla por una subida
por el usuario o por un icono. Sus cambios personales siguen separados de los
roles y asignaciones.

## Compatibilidad con datos guardados

Los campos nuevos son opcionales en respaldos anteriores. Solo los IDs de
demostración conocidos reciben fotos y documentos de ejemplo; los datos no
vacíos existentes se conservan. Un contacto o empleado creado por el usuario
no recibe una identidad ficticia automáticamente.

El modo de demostración añade cinco campañas sin reemplazar otras: tres
vigentes, una programada y un borrador. La vista pública filtra por estado y
vigencia. Las fechas se conservan al instalarse en el editor y no se reinician
al recargar. Editar o archivar una campaña conserva su identidad.

Las campañas son contenido editorial: no aplican descuentos a las ventas.
