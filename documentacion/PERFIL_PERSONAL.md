# Perfil personal y editor modal

Mi cuenta → Mi perfil es una vista de consulta para administradores y empleados.
La información personal se presenta como texto, no como campos de formulario.
El botón **Editar perfil** abre el único formulario de edición en un modal.

## Funciones locales

- Nombre completo, correo de contacto opcional y teléfono opcional.
- Avatar con iniciales, siete iconos alternativos y seis colores.
- En web, carga de foto JPG/PNG/WebP de hasta 5 MB. La foto se reduce localmente
  a un JPEG de hasta 256 px y 128 KB, sin subir archivos a ningún servidor.
- Vista previa del avatar; quitar foto o elegir icono sin guardar todavía.
- Guardar actualiza perfil, menú lateral y cabecera, también en móvil.
- Cancelar descarta el borrador. Se validan los campos antes de modificar el perfil.
- Los errores de almacenamiento son visibles y se puede reintentar el guardado.

El correo de contacto no modifica el usuario ni el correo de identidad del
directorio. El formulario nunca cambia ID, rol, código de empleado, sucursal o
caja. Los roles y asignaciones siguen en Personal y asignaciones. Actualizar
el perfil no vacía un carrito pendiente ni modifica comprobantes anteriores.

## Persistencia y límites

Se mantiene la clave de almacenamiento de perfiles existente para no perder
datos antiguos. El documento v2 incluye contacto y avatar, y acepta los perfiles
v1 que solo guardaban nombre y teléfono. Cada cuenta se identifica por su ID,
sin guardar contraseñas, permisos ni la sesión. La sesión se pierde al recargar,
pero el perfil personal se recupera al volver a entrar en el mismo navegador.

Solo se permiten iconos/colores del catálogo y fotos locales pequeñas; se
rechazan URLs externas y SVG. Una foto dañada muestra el icono de respaldo.
No se borra el almacenamiento operativo ni se mezclan datos entre cuentas.
Esto no sustituye autenticación, permisos ni almacenamiento de producción.

## Organización y comprobaciones

- `models/profile/models/profile_appearance.dart`: claves y validaciones puras.
- `models/profile/widgets/profile_edit_dialog.dart`: borrador y editor modal.
- `shared/widgets/user_avatar.dart`: renderizado reutilizable y caché de foto.
- `core/services/profile_photo_picker*`: selector/optimización web y alternativa
  de iconos para plataformas sin selector implementado.
- `AuthController`: validación, migración y guardado serializado por cuenta.

Las pruebas cubren perfil estático, cancelar/guardar, permisos inmutables,
persistencia y migración, selección/cancelación de foto, errores y reintento,
cierre al terminar la sesión, carrito intacto y tamaños de 320/390/768/1440 px
con texto aumentado en temas claro y oscuro.
