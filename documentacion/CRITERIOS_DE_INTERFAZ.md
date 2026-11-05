# Criterio de diseño de la administración

El diseño se aplica al conjunto del sistema. Una vista nueva debe seguir el
mismo lenguaje que las existentes, aunque no tenga una pantalla en Figma.

## Composición

- Una cabecera breve con título, contexto y acciones principales.
- Listados con búsqueda, filtros y paginación; una fila por registro.
- En móvil, filas planas que ajustan el texto, sin una tarjeta por registro.
- Los detalles extensos se abren bajo demanda y ofrecen un regreso al listado.
- Las pestañas separan tareas dentro de un centro; no se apilan varios listados.
- Indicadores en una franja breve cuando ayudan a interpretar la consulta.
- Reservar tarjetas para grupos con una función propia, como un gráfico o el
  carrito. No usarlas como sustituto de una tabla de cajas, personas o productos.
- El texto ampliado y las ventanas bajas pueden desplazar el conjunto. Nunca
  reducir la fuente ni ocultar controles para forzar que todo quepa.

## Componentes compartidos

- `CompactWorkspace`: cabecera y área de trabajo; mide el contexto antes de
  reservar espacio para el contenido y permite desplazarlo si hace falta.
- `CompactRecords`: tabla adaptable, búsqueda por el consumidor y paginación
  ajustada al alto disponible.
- `WorkspaceTabs`: navegación secundaria uniforme, desplazable en móvil.
- `SummaryStrip`: cifras de contexto sin varias fichas grandes.
- `RecordDetail`: información de lectura y acciones sobre un registro.
- `FormDialog`: cabecera, cuerpo desplazable y acciones al pie.
- `FormFieldsGrid`: dos columnas cuando hay espacio y una con texto ampliado
  o pantallas estrechas.

## Aplicación por tarea

| Vista | Composición |
| --- | --- |
| Productos, lotes, compras, contactos | Listado compacto y detalle bajo demanda |
| Cajas de facturación | Tabla de puestos; detalle con facturas, productos vendidos y medios de pago |
| Personal y asignaciones | Un solo centro con pestañas de personal, sucursales, cajas y catálogo |
| Historial de facturas | Tabla paginada, consulta de comprobante y anulación con motivo |
| Nueva factura | Catálogo y carrito acotados; en móvil se alternan conservando la venta |
| Promociones y soporte | Listados paginados, detalle de lectura y formulario de edición |
| Mi perfil | Identidad breve, datos estáticos, acceso y actividad paginados |
| Preferencias | Un grupo de ajustes a la vez; vista previa bajo demanda |
| Datos y mantenimiento | Herramientas de respaldo agrupadas, sin paneles explicativos repetidos |
| Resumen y reportes | Indicadores y gráficos; el detalle tabular tiene una vista propia |

## Consistencia entre roles

Administrador y empleado usan los mismos componentes y márgenes. El rol decide
qué datos y acciones están autorizados, sin crear una composición distinta para
Facturación. Las pruebas comparan los límites del catálogo y del carrito con el
shell real en cinco tamaños de pantalla, y recorren las vistas compartidas en
modo oscuro con texto ampliado.

Las cifras de cajas excluyen anulaciones de importes netos y unidades. El detalle
mantiene el período de consulta y los operadores históricos. La asignación de
personas y roles se edita exclusivamente desde el centro de personal.

Las funciones continúan usando los controladores locales existentes. Este cambio
de interfaz no conecta un backend ni modifica el formato del respaldo.
