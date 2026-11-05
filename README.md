# Farmacia JAE

Aplicación web en Flutter para centralizar ventas, inventario, compras,
reportes, seguridad y soporte de TI de la farmacia.

## Presentación pública y administración

La raíz `/` abre `/presentacion`, una portada breve con identidad propia de
JAE. El menú lleva a vistas independientes: Inicio, Nosotros, Servicios,
Promociones y Contacto. Los teléfonos, dirección exacta y horarios pendientes
aparecen como «Por confirmar».

**La información general de presentación sigue estática y sin backend.**
La excepción solicitada es `/presentacion/promociones`: muestra el contenido
vigente preparado en `/administracion/promociones`, guardado solo en este
navegador. No consulta inventario ni cuentas. No hay carrito, pedidos,
registro ni enlaces públicos a administración. Su contenido y marco común
viven en `models/presentation`; la edición se separa en `models/promotions`.

Para acceder al sistema interno se escribe `/administracion` en la URL.
`go_router` aplica `AuthGuard` antes de construir el shell privado:

- Sin sesión: muestra el acceso en `/administracion`, sin `/login` ni `?desde=...`.
- Al iniciar sesión: abre el resumen en `/administracion`. Las direcciones antiguas del login se redirigen a esta entrada limpia.
- Con sesión: permite acceder a los módulos autorizados y a
  `/administracion/perfil`.
- Empleado: bloquea compras, proveedores, reportes y configuración incluso
  mediante URL directa. Las mismas reglas filtran el menú y accesos rápidos.
- Cerrar sesión: revoca el acceso y limpia la venta pendiente.
- El login no incluye registro; el perfil no modifica el rol ni el usuario de acceso.

### Cuentas de demostración

| Rol | Usuario | Contraseña de ejemplo |
| --- | --- | --- |
| Administrador | admin | 1234 |
| Empleado | usuario | 1234 |

El login también ofrece botones para rellenar estas cuentas sin iniciar sesión
automáticamente. El perfil muestra información estática; **Editar perfil** abre
un modal para nombre, contacto y avatar (iconos, colores o foto local optimizada).
Los cambios se guardan por cuenta y se reflejan en cabecera y menú. El correo
personal no altera la identidad del directorio, y el rol, usuario, sucursal y
caja no se editan aquí. El acceso se valida por usuario, no por correo.
Su actividad se obtiene del registro de auditoría.
Detalles y límites: [Perfil personal](documentacion/PERFIL_PERSONAL.md).

**Límite de seguridad:** la validación actual es un prototipo de cliente, no
autenticación de producción. Las cuentas son ficticias, la sesión no se
almacena y recargar exige iniciar sesión de nuevo. No se deben introducir datos
reales. Al implementar el backend de **administración**, NestJS deberá validar
identidad y permisos en cada petición. Esto no conecta ni cambia el alcance de
la presentación pública.

Las rutas utilizan `usePathUrlStrategy`, sin `#`. El servidor de producción
debe resolver rutas de aplicación a `index.html`, conservando los archivos
estáticos y devolviendo 404 para recursos inexistentes. El servidor de Flutter
ya permite probar los enlaces directos en desarrollo.

En Netlify, publica el contenido de `build/web`. El archivo `web/_redirects`
se copia allí durante la compilación y permite abrir o recargar directamente
`/presentacion`, `/administracion` y sus subrutas. Inclúyelo en cada despliegue;
sin esa regla Netlify devuelve 404 antes de que Flutter pueda resolver la URL.

## Organización del proyecto

### Módulos por proceso del negocio

Un módulo agrupa varias vistas; no es sinónimo de una pantalla individual.
El árbol único vive en `models/home/models/admin_modules.dart` y se reutiliza
en escritorio y en el menú móvil, filtrado por los permisos existentes.

| Módulo | Vistas |
| --- | --- |
| Dashboard | Resumen, Reportes |
| Inventario | Productos, Lotes, Compras, Proveedores |
| Ventas | Cajas de facturación, Facturación, Clientes |
| Gestión de la farmacia | Promociones, Personal y asignaciones, Datos y mantenimiento |
| Mi cuenta | Mi perfil, Preferencias, Ayuda y soporte |

La clasificación adapta los procesos a una farmacia; no incorpora servicios,
garantías, colores, texturas, consignaciones ni crédito del ejemplo genérico.
### Funciones administrativas locales

- Productos: registrar, buscar, editar y archivar/reactivar fichas sin borrar historial.
- Inventario: consultar existencias por producto y lote, recibir lotes, ajustar
  cantidades con motivo, buscar y filtrar vencimientos.
- Compras: crear órdenes con varias líneas, recibirlas completas por lote,
  cancelarlas mientras estén pendientes y registrar el pago completo una vez.
- Proveedores y clientes: registrar, editar, buscar y archivar/reactivar.
- Caja: temporalmente desactivada en el menú, ruta directa y comandos de
  apertura, cierre y movimientos. Su código y registros se conservan.
- Ventas: buscar productos, carrito con cantidades, elegir cliente y método,
  calcular cambio, cobrar, consultar comprobantes y anular ventas completas.
  Facturación requiere una caja de facturación asignada, pero no apertura ni movimientos del antiguo módulo de efectivo. Anular un
  comprobante nuevo requiere administrador y motivo, pero no una caja abierta.
  Si una venta antigua sí tuvo un ingreso de Caja, su devolución requiere
  reactivar Caja para no dejar su historial financiero incoherente.
- Comprobantes internos: vista, descarga HTML e impresión del navegador.
  **No son facturas fiscales ni prueba de pagos bancarios.**
- Reportes: siete gráficos de ventas y gráficos de inventario, compras y
  actividad, todos con `fl_chart`, explicaciones, unidades y datos calculados.
  El selector muestra un gráfico por vez; el desglose y las explicaciones se
  expanden bajo demanda. Los filtros avanzados se aplican desde un diálogo.
  Conserva filtros, detalle adaptable, paginación y exportación de todas las
  coincidencias a CSV. Ver [criterios de reportes y promociones](documentacion/REPORTES_Y_PROMOCIONES.md).
- Promociones: crear, editar, programar, publicar y archivar campañas con
  fechas inclusivas, condiciones e ilustración local opcional. No modifica
  precios de facturación ni crea descuentos automáticos.
- Dashboard y notificaciones: cifras, barras mensuales y alertas calculadas
  sobre los registros locales; no hay indicadores de disponibilidad inventados.
- Ayuda y soporte: registrar, actualizar prioridad/estado y cerrar con solución;
  tiempo de resolución calculado entre las fechas del registro.
- Perfil, preferencias, permisos demo y cierre de sesión continúan funcionando.
- Datos y mantenimiento (solo administración): exportar respaldo JSON, restaurar archivo o JSON pegado y
  reintentar almacenamiento. Restaurar valida todo antes de reemplazar datos.

El prototipo contempla recepción, pago y anulación **completos**, no parciales.
No incluye crédito/cuentas por cobrar, devoluciones parciales, fraccionamiento
de presentaciones, impuestos ni gestión de cuentas reales.

### Suspensión temporal de Caja

`AdministrationFeatures.cashEnabled = false` centraliza la suspensión.
Se mantienen los índices y la URL antigua para reactivarla sin mover las otras
rutas; abrir `/administracion/caja` redirige a Resumen, incluso siendo admin.
Los permisos del perfil y el menú solo cuentan vistas activas.

La facturación conserva cliente, método registrado, cambio, comprobante,
descuento FEFO, anulaciones y auditoría. No crea una caja oculta. Tampoco
modifica un turno anterior que haya quedado abierto. Los pagos de compras
siguen siendo registros manuales, sin salidas de Caja mientras esté suspendida.
Reportes permite consultar su historial anterior en modo de solo lectura.
Los respaldos siguen incluyendo esos datos. Al reactivar Caja se deben revisar
los turnos antiguos; no se convierten retroactivamente ventas nuevas en cobros
de Caja ni se simulan reembolsos que nunca ingresaron a ella.

### Productos ≠ inventario

- `/administracion/productos`: ficha maestra (código, nombre/concentración,
  categoría, principio activo, dosis, presentación, unidad mínima de venta,
  unidades por envase, origen, fabricante, indicaciones y condición de receta).
  Registrarla crea **cero existencias** y deja el precio pendiente hasta recibir
  el lote. Las fichas se organizan en pestañas comerciales, información y proveedores.
- `/administracion/inventario`: recepción y consulta de lotes de una ficha ya
  registrada. Cada lote tiene código del fabricante, proveedor, cantidad,
  fabricación, recepción, vencimiento y ubicación física en su sucursal.
- Relación **producto 1:N lotes**. Ejemplo: un medicamento, lote A con 12 cajas
  y lote B con 8 cajas: 20 cajas en total, dos vencimientos independientes.
- La cantidad usa la unidad mínima de venta. La recepción y compra permiten
  seleccionar envases completos: tres cajas de diez tabletas equivalen a 30
  tabletas; el costo y precio se indican por tableta. No se reinterpretan unidades
  antiguas ni se mezclan presentaciones.
- Se muestran existencias agregadas y detalle de lotes. La venta descuenta por
  FEFO (vence primero, sale primero), excluye vencidos y valida toda la venta
  antes de modificar saldos. El lote es válido durante su fecha de vencimiento.
- Código de producto y barcode no se repiten. El mismo código de lote puede
  existir en productos distintos, pero no se recibe dos veces para el mismo
  producto en recepción directa. Las compras sí reponen un lote si conserva su
  vencimiento y calculan el costo medio ponderado. Ajustes y anulaciones
  generan movimientos trazables.
- Relación **producto N:M proveedor**, editable desde ambas fichas, con código
  comercial, costo de referencia, plazo y suspensión del vínculo. Compras permite
  buscar medicamentos y seleccionar sus proveedores vinculados.
- Ver [flujo de abastecimiento y compatibilidad](documentacion/FLUJO_DE_ABASTECIMIENTO.md).

### Persistencia y límites

La entrada principal añade una sola vez un historial ficticio de seis meses:
16 clientes, cuatro proveedores, ventas en tres sucursales y seis puestos,
compras recibidas/pendientes/canceladas y movimientos de lotes relacionados.
Se conserva cualquier registro previo y la instalación no se repite al recargar.
Los gráficos se animan desde cero al entrar en pantalla, con un recorrido
progresivo de los datos. Ver [datos demo y animaciones](documentacion/DATOS_DEMO_Y_ANIMACIONES.md).

Los datos iniciales son ficticios. Los registros administrativos se conservan
en este navegador mediante `LocalAdministrationStore`, clave
`farmacia_jae.administration.data.v1`. No se creó NestJS ni PostgreSQL.
La sesión y el carrito NO se persisten: al recargar hay que entrar nuevamente,
pero productos, lotes, contactos, operaciones y caja permanecen.

Las escrituras son ordenadas y muestran fallos. Si falla la lectura, se bloquean
las operaciones sin sobrescribir el documento y se ofrece recuperación.
El respaldo JSON versionado incluye datos y auditoría, no credenciales,
sesión, preferencias, promociones ni datos personales del perfil. Importar exige
administrador y reemplaza los registros: exporta un respaldo antes.
La exportación CSV neutraliza textos que podrían ejecutarse como fórmulas.

**No usar con información real ni como sistema de producción.** Borrar los datos
del navegador o usar otro perfil/equipo cambia el almacenamiento disponible.
No hay sincronización, servidor, transacciones de base de datos, control de
concurrencia entre pestañas ni seguridad multiusuario. Trabaja en una sola
pestaña y exporta respaldos manuales. No hay procesamiento de pagos reales,
facturación fiscal, monitoreo de infraestructura ni copias automáticas externas.
Los lotes demo con costo cero tienen costo desconocido; no se inventa su valor.

La futura administración requerirá permisos de servidor, transacciones y
concurrencia. Las vistas informativas siguen estáticas. Publicar la compilación
en Netlify no distribuye las promociones guardadas en el navegador del editor;
no se ha implementado publicación compartida entre equipos.

La estructura sigue el patrón de `tiendasalmeron`, pero con nombres
consistentes y responsabilidades separadas:

```text
lib/
├── core/
│   ├── app.dart
│   ├── routing/            # URLs y guards de sesión y rol
│   ├── services/
│   │   ├── auth_controller.dart
│   │   └── pharmacy_controller.dart
│   └── utils/
│       ├── formatters.dart
│       └── responsive.dart
├── models/
│   ├── auth/               # Login sin registro y modelo del usuario
│   ├── dashboard/
│   ├── home/
│   ├── incidents/
│   ├── inventory/
│   ├── cash/               # Caja, movimientos y arqueos
│   ├── contacts/           # Clientes y proveedores
│   ├── purchases/          # Órdenes, recepción y pagos
│   ├── audit/              # Historial de acciones
│   ├── presentation/       # Sitio público permanente y estático
│   ├── profile/            # Perfil adaptable al rol de la sesión
│   ├── products/           # Fichas maestras, sin stock ni vencimiento
│   ├── reports/
│   ├── sales/
│   └── settings/
├── shared/
│   ├── themes/
│   └── widgets/
└── main.dart
```

### Responsabilidades

- `core`: arranque de la aplicación, estado compartido, servicios y utilidades.
- `models`: módulos del negocio. Cada módulo puede tener `models`, `views` y
  `widgets` sin mezclar lógica de otras áreas.
- `shared`: tema, colores y componentes visuales reutilizables.
- `main.dart`: únicamente inicia la aplicación.

El controlador actual trabaja con datos de demostración. Su interfaz está
preparada para sustituir la fuente temporal por la base de datos o una API sin
reorganizar las vistas.

## Preferencias personales y mantenimiento

**Mi cuenta → Preferencias**, ruta `/administracion/preferencias`, está
disponible para administradores y empleados. Cada cuenta conserva sus propios
ajustes en este navegador: tema claro/oscuro/sistema, color de acento, densidad,
tamaño de texto, contraste reforzado, movimiento reducido, indicador de alertas,
vista inicial del catálogo y confirmación antes de vaciar el carrito.
Restablecer solo modifica el perfil de preferencias activo.

**Gestión de la farmacia → Datos y mantenimiento** concentra respaldos,
restauración y estado del almacenamiento; conserva el guard de administrador.
La URL antigua `/administracion/configuracion` se mantiene por compatibilidad,
pero el nombre visible y su responsabilidad cambiaron. Las preferencias
personales no están mezcladas con estas herramientas.

**Mi cuenta → Ayuda y soporte** reúne ayuda de uso y seguimiento de problemas.
Se conserva la URL e historial anterior de solicitudes; ya no se presenta como
un módulo llamado «Incidentes TI».

`PreferencesController` usa un documento v2 con perfiles por ID de cuenta,
en la clave existente `farmacia_jae.administration.preferences.v1` para preservar
el almacenamiento anterior. Los documentos globales v1 pasan al ámbito del
login (`guest`), sin adivinar a qué usuario pertenecían. No se guardan
contraseñas, sesión, permisos ni inventario en este documento.
La presentación pública no carga estas preferencias y permanece independiente.

Facturación incorpora tarjetas rectangulares, filtros de categoría/existencias,
búsqueda por código o lector de teclado, vista de lista, edición de cantidades,
eliminación de líneas, totales claros y un cobro específico para cada método.
El historial se consulta en otra pestaña, sin mezclarlo con una nueva venta.
Los cambios visuales no alteran FEFO, pertenencia a sucursal ni trazabilidad.

Detalles de diseño, alcance y pruebas:
[Experiencia y preferencias](documentacion/EXPERIENCIA_Y_PREFERENCIAS.md).

## Diseño responsive

- Menos de 900 px: navegación móvil mediante drawer.
- Facturación: catálogo y detalle en dos columnas desde 1000 px de contenido;
  por debajo se apilan, sin fijar alturas que recorten texto.
- Menos de 620 px: cabeceras, filas de inventario e incidentes adaptadas a
  formato vertical.

Los breakpoints viven en lib/core/utils/responsive.dart y las decisiones
importantes están comentadas junto al layout que las aplica. Las tarjetas
usan Wrap para reorganizarse automáticamente sin duplicar vistas.

La presentación colapsa su menú antes de que las opciones compitan con la
marca. El login apila su composición en pantallas pequeñas y los perfiles
apilan datos y permisos. Hay pruebas de 320, 390, 768 y 1440 píxeles.

El dashboard usa `fl_chart` con barras dobles de compras y ventas, colores de
la referencia Figma, tooltips, eje mensual y selector de año. Las dos series
se calculan con compras recibidas y ventas vigentes del año elegido.

## Sucursales y cajas de facturación

Gestión de la farmacia → **Personal y asignaciones** reúne el directorio,
los roles, puestos, sucursales y cajas en una sola vista. Permite crear y editar
sedes/cajas y habilitar productos por sede sin ir a otro editor.
Ventas → **Cajas de facturación** muestra operador actual, comprobantes,
productos vendidos e indicadores por período; sus editores se centralizaron
en Personal y asignaciones. La misma caja no puede tener dos
operadores activos. Los empleados solo facturan stock vigente de su sucursal.

El catálogo maestro se reutiliza; las existencias por lote y las compras no se
mezclan entre sedes. Las facturas conservan su asignación histórica aunque el
personal cambie de puesto. Los reportes incorporan filtros combinables,
detalle por producto y agrupación por sucursal/caja/operador con CSV.

Los arqueos de efectivo anteriores siguen desactivados; las nuevas cajas son
puestos de facturación estadísticos. El respaldo operativo v2 acepta v1 sin
inventar la caja de las ventas antiguas. Las cuentas creadas por administración
usan contraseña demo `1234`, sin registro público.

La barra global de sucursal/caja se sustituyó por rutas de navegación
(por ejemplo, **Facturación › Nueva factura**). Historial y preferencias
mantienen su sub-vista en la URL. El contexto de consulta de otras sedes
se cambia dentro de Personal y asignaciones; no reasigna empleados.
Los roles se aplican al siguiente login y no se puede quitar el acceso de la
cuenta `admin` ni el de la propia sesión administradora. El perfil personal
no permite cambiar permisos. Véase [Navegación y personal](documentacion/NAVEGACION_Y_PERSONAL.md).

**Sigue siendo un prototipo local**: no sincroniza sucursales ni computadoras.
Para operación real falta implementar autorización y concurrencia en NestJS y
PostgreSQL. Reglas, migración y límites: [Sucursales y cajas](documentacion/SUCURSALES_Y_CAJAS.md).

## Verificación y ejecución

Los listados de Productos, Lotes, Compras, Proveedores, Clientes, Cajas,
Personal, Promociones, Soporte e historial de facturas usan
filas compactas, búsqueda y paginación. En escritorio muestran hasta ocho
registros por página, ajustando la cantidad al alto disponible; en móvil
usan filas planas con scroll y conservan el pie de navegación. Las fichas,
los movimientos de lotes y las líneas de órdenes se consultan en vistas de
detalle con regreso al listado, sin apilar una tarjeta por registro.
Los enlaces de detalle conservan los permisos del módulo y las rutas de
navegación. El Dashboard muestra indicadores, gráfico, alertas y accesos
rápidos; el historial de actividad se consulta en Reportes.

Personal y asignaciones reúne personas, roles, sucursales, cajas y catálogo
en pestañas de un mismo centro. Cajas de facturación abre su detalle en una
vista con facturas, productos y medios de pago; el período acompaña al enlace.
Perfil y preferencias usan el mismo marco compacto. Los formularios comparten
cabecera, cuerpo desplazable y acciones al pie.

Facturación comparte composición entre administrador y empleado. Catálogo y
carrito se desplazan dentro de su espacio; en móvil se alternan sin perder
la venta. El criterio para todas las vistas se documenta en
[Criterios de interfaz](documentacion/CRITERIOS_DE_INTERFAZ.md).

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
flutter build web
```

El arranque web carga CanvasKit desde `canvaskit/` en el mismo servidor mediante
`web/flutter_bootstrap.js`; Flutter incluye esos archivos en `build/web`.
La fuente de respaldo Roboto también se incluye como recurso local, con su
licencia en `assets/fonts/Roboto/`. Esto evita las descargas iniciales desde
`www.gstatic.com` y `fonts.gstatic.com` que pueden fallar por restricciones de
red. Publica toda la carpeta `build/web`, incluyendo `canvaskit` y `assets`.
Después de cambiar el bootstrap o las fuentes, detén la ejecución y vuelve a
iniciarla; hot reload no reinicia el motor web.

El diagnóstico se conserva como antecedente de necesidades. Los nombres y la
navegación de la aplicación se organizan por procesos de la farmacia y tareas
del personal, no por los capítulos de ese informe.

Las fotos ilustrativas de contactos, personal y promociones se incluyen como
archivos locales. Los documentos de demostración llevan el prefijo `DEMO-`.
Procedencia, instalación compatible con respaldos y descarga reproducible:
[Fotos y datos de demostración](documentacion/RECURSOS_DEMO.md).
