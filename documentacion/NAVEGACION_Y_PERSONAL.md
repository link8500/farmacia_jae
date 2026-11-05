# Navegación y gestión central de personal

## Una sola vista de gestión

En Gestión de la farmacia → Personal y asignaciones se encuentra:

- Directorio con búsqueda por persona, usuario, rol, puesto, sucursal o caja.
- Filtros por sucursal, rol y estado; paginación de diez personas.
- Edición conjunta de nombre, rol, puesto, estado, sucursal y caja.
- Creación y edición de sucursales y cajas, agrupadas por sede en la misma vista.
- Consulta del operador actual de cada caja y del catálogo habilitado por sede.

En escritorio se presenta una tabla; en móvil o con texto muy grande se usan
fichas. Los formularios son desplazables y comparten las validaciones del dominio.
No se trasladan cajas existentes entre sedes: se crea una nueva para conservar
la identidad de las cajas y la atribución histórica de las ventas.

Rol y puesto son conceptos distintos: el rol concede permisos de administrador
o empleado; el puesto describe su trabajo. El empleado conserva la restricción
de catálogo/stock de su sucursal y necesita una caja activa asignada para cobrar.
Al cambiar de sucursal en el formulario se limpia la selección de caja y solo
se ofrecen las de esa sede. Las ocupadas por otra persona están deshabilitadas;
el controlador también rechaza la operación, sin guardar cambios parciales.

Los cambios de rol se leen desde el directorio en el próximo inicio de sesión,
incluido el usuario de demostración `usuario`. El perfil personal no concede
permisos. No se permite desactivar ni degradar la cuenta principal `admin`, ni
quitarse el propio acceso administrativo durante la sesión. El respaldo v2 ya
incluía el rol: no hay cambio de esquema ni se modifican las facturas anteriores.

Ventas → Cajas de facturación conserva estadísticas, productos y comprobantes;
ofrece un acceso al centro de personal para administradores, pero ya no duplica
formularios de edición de cajas o asignaciones.

## Rutas de navegación

Se eliminó la antigua barra global que mostraba sucursal/caja. El shell presenta
una ruta compacta con padres navegables y la vista actual destacada:

| Vista | Ruta mostrada |
| --- | --- |
| Facturación | Facturación › Nueva factura |
| Historial | Facturación › Historial de facturas |
| Productos / Inventario / Compras / Proveedores | Compra › nombre de la vista |
| Clientes / Cajas de facturación | Ventas › nombre de la vista |
| Resumen / Reportes | Dashboard › nombre de la vista |
| Personal / Datos y mantenimiento | Gestión de la farmacia › nombre de la vista |
| Perfil / Soporte | Mi cuenta › nombre de la vista |
| Preferencias | Mi cuenta › Mis preferencias › sección actual |

Historial usa `/administracion/ventas?vista=historial`. Las preferencias usan
`?seccion=accesibilidad` o `?seccion=facturacion`; apariencia es la vista predeterminada.
La URL, la vista y su ruta visible comparten el mismo estado, incluso al abrir
un enlace directo. El login conserva únicamente parámetros internos conocidos.

Para consultar otra sucursal, el administrador expande la sede en Personal y
asignaciones y elige «Usar para consultas». Esto no modifica el puesto de nadie
ni concede una caja para facturar. Si existe un carrito pendiente se solicita
confirmación antes de descartarlo. También se confirma cambiar la propia
asignación cuando hay una venta pendiente. Editar a otra persona no descarta
el carrito de la sesión actual.

## Alcance y verificación

Continúa siendo un prototipo sin backend: datos y permisos locales, contraseña
demo `1234`, sin sesiones simultáneas entre equipos. No es seguridad de producción.
Los arqueos de efectivo siguen desactivados. No se modificó la presentación pública.

Las pruebas cubren persistencia de roles, privilegios, atomicidad de asignación,
facturas históricas, login de una cuenta promovida, sub-vistas y rutas del guard,
formularios, y diseños de 320/390/768/1440 píxeles con texto aumentado.
