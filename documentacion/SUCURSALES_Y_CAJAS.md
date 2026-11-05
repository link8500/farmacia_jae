# Sucursales, personal y cajas de facturación

## Alcance implementado

Prototipo Flutter local, sin API, PostgreSQL ni sincronización entre equipos.
El administrador gestiona sedes, cajas, empleados y sus asignaciones desde
Gestión de la farmacia → Personal y asignaciones, en una sola vista.
Ventas → Cajas de facturación queda como consulta estadística y de comprobantes.
Las cuentas de personal creadas por administración pueden probarse con su
usuario y contraseña **1234**. No existe registro público. Esta autenticación
es ficticia y NO sirve para publicar una administración real.

## Modelo y reglas

- Una sucursal tiene varias cajas y un catálogo de productos habilitados.
- Una ficha maestra describe el artículo una sola vez; habilitarla en una sede
  no añade stock. El administrador puede reutilizarla en otras sedes.
- Cada lote y orden de compra pertenece a una sucursal. El mismo código de lote
  puede existir en dos sedes sin compartir su saldo.
- El rol (administrador/empleado) define permisos; la sucursal y el puesto no
  son roles. El empleado solo consulta el catálogo y stock de su sede.
- Un empleado tiene una asignación actual a una sede y, opcionalmente, una caja.
  Sin caja activa no puede facturar. Una caja admite un solo operador activo.
- El administrador puede consultar otras sedes desde Sucursales y cajas,
  dentro de Personal y asignaciones, con «Usar para consultas». Para
  facturar en ellas también necesita asignarse una caja de esa sede en Personal.
- Cambiar sucursal de consulta, sesión o la propia asignación limpia el carrito,
  no el inventario. Editar a otra persona no descarta la venta propia.
- El formulario administra rol, puesto, estado, sucursal y caja juntos. Los
  cambios de rol se aplican en el próximo login. La cuenta principal y la propia
  sesión administradora conservan su acceso para evitar bloqueos accidentales.
- Una venta descuenta únicamente lotes vigentes de la sede, en orden FEFO.
- La factura guarda ID y nombre de sucursal, caja y operador al emitirla;
  reasignaciones y cambios de nombre no modifican sus datos históricos.
- La anulación administrativa devuelve unidades a los lotes originales,
  conservando la trazabilidad y el comprobante anulado.
- Archivar personal libera su caja y bloquea nuevas operaciones/login demo.
  No se borran empleados, cajas o sedes que tengan historia.
- No se puede desactivar una caja ocupada ni una sede con personal activo o
  compras pendientes. No se retira un producto con stock o compras pendientes.

## Caja estadística frente a efectivo

Las nuevas cajas de facturación están en `/administracion/cajas`. Registran
ventas de cualquier método de pago. NO simulan aperturas, cierres, arqueos,
depósitos o procesamiento bancario. El módulo anterior `/administracion/caja`
permanece desactivado, con sus sesiones y movimientos intactos. Una devolución
de una factura antigua que sí movió efectivo continúa requiriendo ese flujo.

## Reportes

Reportes conserva sus tipos anteriores y amplía ventas con:

- Comprobantes: fecha/hora, cliente, operador e ID, sucursal, caja, método,
  unidades, total, estado y motivo/fecha de anulación.
- Detalle por producto: cantidad, unidad, precio, subtotal y lotes utilizados.
- Agrupación por IDs de sucursal, caja y operador: facturas vigentes/anuladas,
  unidades netas, ventas netas, importe anulado, ticket promedio y métodos.
- Filtros combinables por fecha de emisión, sucursal, caja, operador, método
  y estado. Exportación CSV de todas las filas resultantes, no solo la página.

Ventas netas = suma de facturas vigentes. Ticket promedio = ventas netas /
facturas vigentes. Las anuladas quedan visibles pero no suman a ventas ni
unidades netas. Estos reportes agrupan por fecha de emisión de la factura, no
por fecha de reembolso: NO son un estado financiero ni una conciliación de caja.
La búsqueda textual inferior filtra filas/CSV; el resumen indica los filtros
estructurados anteriores a esa búsqueda. Inventario y compras usan la sede
de consulta elegida en Personal y asignaciones; los filtros de ventas son independientes.
El empleado solo consulta sus propios comprobantes en su sede actual; el
administrador tiene acceso histórico a todas las asignaciones.

## Persistencia y migración

El documento operativo pasa a versión 2, conservando la clave de almacenamiento
existente para no perder registros. Los respaldos v1 siguen siendo aceptados:
su inventario y compras se ubican en la sucursal principal. Las ventas anteriores
sin IDs de sede/caja/operador se muestran como **sin asignación histórica**;
no se adivina una caja a partir del nombre del vendedor. Las relaciones, la
exclusividad de operadores y las asignaciones de lotes se validan antes de
reemplazar el estado. Respaldos completos y restauración solo para administración.

## Pendiente para interconectar sucursales reales

Esta separación es funcional en un navegador, no una garantía de seguridad o
concurrencia entre equipos. NestJS deberá autenticar, autorizar y filtrar cada
consulta por las sedes autorizadas, sin confiar en IDs enviados desde Flutter.
PostgreSQL deberá aplicar claves foráneas de pertenencia, unicidad del operador
activo por caja, transacciones de factura/descuento FEFO y bloqueo de filas de
stock para impedir sobreventas simultáneas. Se necesitan usuarios/contraseñas
reales, migraciones de datos, respaldos centralizados y pruebas concurrentes.
Nada de esto se obtiene solamente publicando Flutter en Netlify.

## Organización del código

`models/organization` contiene entidades, vistas y formularios. El controlador
coordina permisos y contexto; `core/services/organization_operations.dart`
concentra sus comandos, y `administration_persistence.dart` valida respaldos.
`models/reports/models/sales_analytics.dart` comparte consultas y cálculos entre
cajas y reportes para no mantener totales mutables duplicados. Las reglas y las
decisiones históricas están comentadas junto al código correspondiente.
