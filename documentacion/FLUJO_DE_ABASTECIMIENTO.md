# Catálogo, proveedores y recepción

El catálogo comercial define qué artículo se vende. El lote identifica de dónde
proviene una recepción y conserva sus existencias. La compra documenta cantidades
y costos; la factura conserva los valores que estaban vigentes cuando se emitió.

## Proveedores y su catálogo

El directorio recoge código único, razón social, tipo, representante, contacto,
correo, origen, dirección, identificación y descripción comercial. La relación
`ProductSupplier` / `producto_proveedor` tiene clave compuesta producto–proveedor:
permite varios proveedores por medicamento y varios medicamentos por proveedor.
Guarda código comercial, costo unitario de referencia, plazo y estado del vínculo.

El vínculo se edita desde **Producto → Proveedores** o desde **Proveedor → Catálogo
de productos**. Suspenderlo impide nuevas compras de esa combinación, conservando
las órdenes anteriores. Archivar un proveedor no borra su historial.

## Producto, unidad y precio

La ficha contiene presentación, unidad mínima de venta, unidades por envase,
concentración, unidad de medida, fabricante, origen, principio activo, descripción,
indicaciones, advertencias y clasificación con/sin receta. Estos campos son datos
de catálogo que el personal debe transcribir de la documentación del artículo.

La ficha nueva se guarda con precio cero, que significa **pendiente de definir**.
No se permite facturar un artículo sin precio. Se define un precio por unidad de
venta al confirmar una recepción o con **Definir precio**, después de recibir un
lote en la sucursal. Las facturas emitidas conservan su precio histórico.

Ejemplo: presentación «caja de 10 tabletas», unidad «tableta», unidades por envase
10. Recibir o comprar tres envases completos suma 30 tabletas. Con costo de C$ 1.20
por tableta, la compra suma C$ 36.00. Un precio de venta de C$ 2.50 se aplica a una
tableta; facturar una descuenta una tableta mediante FEFO.

Las fichas anteriores conservan sus unidades y saldos: no se convierten cajas a
tabletas silenciosamente. Cambiar unidad o equivalencia cuando hay lotes, órdenes
o carrito se rechaza; debe crearse una ficha distinta para la nueva presentación.

## Compra y lote del fabricante

1. Buscar el medicamento por nombre, concentración o presentación.
2. Consultar proveedores vinculados y sus costos de referencia. Se puede mostrar
   el directorio completo para establecer una relación comercial nueva.
3. Añadir líneas en unidades de venta o envases completos. Una orden corresponde
   a un proveedor y una sucursal, y todavía no modifica existencias.
4. Al recibir, transcribir código de lote, fabricación, vencimiento y ubicación
   física, y definir el precio unitario de venta. Se recibe la orden completa;
   este flujo no incluye recepciones parciales ni dividir una línea entre varios
   lotes en una sola confirmación. Se pueden recibir sucesivos lotes del producto
   mediante otras órdenes o recepciones directas.
5. Todas las líneas se validan antes de modificar existencias, movimientos,
   precios o estado. El saldo se controla exclusivamente por lotes de sucursal.

El código se obtiene del envase o del documento del proveedor; la aplicación no
genera códigos del fabricante ni deduce fechas de ellos. La fabricación debe ser
anterior al vencimiento y no posterior a la recepción. Un lote ya vencido no se
recibe. Una reposición conserva proveedor, fabricación, vencimiento y ubicación
del lote; su costo se calcula como promedio ponderado.

La recepción directa registra proveedor y ubicación. **Ubicar lote** cambia su
posición física sin alterar existencias. Los ajustes de cantidad siguen siendo
operaciones independientes con motivo y movimiento. La venta y su anulación
preservan todos los metadatos del lote. El reporte de inventario exporta proveedor,
fabricación y ubicación junto al saldo y costo.

## Datos anteriores y alcance

Los respaldos locales anteriores siguen siendo compatibles. Una tabla N:M ausente
se reconstruye a partir de compras documentadas. Los campos nuevos de catálogo
se completan en fichas conocidas solo si antes no existían; los vacíos guardados
explícitamente se conservan. No se inventan fechas de fabricación ni ubicaciones
para lotes antiguos; aparecen pendientes de documentar.
**Editar trazabilidad** permite completar proveedor, fabricación y ubicación de
esos lotes; valida las fechas y deja auditoría sin modificar saldo, costo,
recepción, vencimiento ni las facturas anteriores.

El esquema de referencia `farmacia_db.sql` refleja los campos y la tabla puente.
No se ha ejecutado SQL ni conectado un servidor. Las operaciones siguen guardadas
en el navegador con los límites del almacenamiento local existente.

## Presentación pública

`/presentacion` contiene portada publicitaria, páginas de farmacia y contacto,
catálogo editorial con búsqueda y categorías, y fichas de artículos. Sus datos y
fotografías son locales. No consulta existencias privadas ni crea ventas, cuentas
o reservas. Las campañas conservan la publicación local desde Promociones con
fechas y condiciones. El teléfono y horario reutilizan los datos existentes del
proyecto; el mapa busca la localidad, sin fingir una dirección exacta.
