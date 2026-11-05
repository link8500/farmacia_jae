# Historial ficticio y entrada de gráficos

La entrada `main.dart` activa `FarmaciaApp(seedDemoHistory: true)`. Los datos
operativos siguen cargándose al entrar al sistema interno; visitar la
presentación pública no inicializa inventario ni historial administrativo.

## Datos vinculados

`PharmacyDemoScenario` construye un escenario reproducible desde el primer día
de hace cinco meses hasta el momento de la instalación. Incluye varios cientos
de ventas, 16 clientes ficticios, cuatro proveedores ficticios, tres sucursales,
seis operadores y seis cajas. Las dos cuentas originales conservan sus datos
y credenciales. Las sedes adicionales y los proveedores se identifican como Demo;
las direcciones son explícitamente ficticias y los correos usan `.example`.
Los dos contactos genéricos anteriores permanecen si ya existían.

El escenario reutiliza hasta ocho fichas activas existentes. No cambia sus
precios, nombres ni imágenes, ni reemplaza lotes o asignaciones previas.
Cada venta conserva cliente, operador, sucursal y caja de emisión, método de
pago, líneas y asignaciones de lotes. Las anuladas conservan motivo y fecha.
No se generan operaciones posteriores al momento de la carga.

Las compras recibidas abastecen la demanda mensual más una reserva. Cada línea
crea su lote con costo, recepción y vencimiento, y un movimiento que identifica
la compra. Las ventas descuentan por FEFO entre los lotes del escenario y las
anulaciones devuelven unidades a sus lotes originales. Los saldos finales se
obtienen de esos movimientos, sin cantidades negativas. Compras pendientes y
canceladas no generan lotes ni existencias; algunas recibidas quedan sin pago.
No se crea actividad del módulo suspendido de arqueos de efectivo.

## Instalación y conservación

La carga es aditiva. Primero se construye y valida una copia completa con el
mismo validador de respaldos; solo después se aplica al estado operativo.
Un conflicto de identificadores o nombres no sobrescribe parcialmente datos.
Los IDs del escenario usan un espacio propio y no consumen las secuencias de
comprobantes nuevos. Se almacena `demoScenarioVersion: 1` dentro del documento
administrativo y de sus respaldos. Al recargar no se duplican ni se regeneran
las ventas con nuevas fechas: los cambios que hagas permanecen.

Si una entrada alternativa no lo instaló, un administrador puede usar
**Datos y mantenimiento → Añadir historial de demostración**. Si ya está
instalado, aparece su estado. Los errores de instalación se muestran en esa
vista y no sustituyen los datos existentes. Una restauración conserva la marca
del respaldo; respaldos antiguos sin ella siguen siendo compatibles.

## Animaciones con fl_chart

`ChartEntrance` proporciona un progreso de 0 a 1 durante 1.4 segundos y espera
a que el área del gráfico entre en pantalla. Se reutiliza en Dashboard y
Reportes. Un cambio de período, año o datos reinicia la entrada; un repintado,
un cambio de apariencia o el guardado del mismo contenido no la reinician.

- Barras: crecen desde cero por orden de izquierda a derecha, con ambos valores
  de un mes animados juntos en Dashboard.
- Líneas: parten de cero y revelan las muestras y el segmento actual hasta llegar
  al último dato. Los ejes mantienen sus límites finales para evitar saltos.
- Circulares: barrido horario desde las doce; conserva las proporciones reales
  mientras recorta progresivamente la pintura de `PieChart`.

Se desactiva la interpolación implícita adicional de fl_chart para evitar dos
animaciones superpuestas. Los valores de leyendas e indicadores son siempre
los finales; las consultas por puntero se habilitan al acabar la entrada.
Con **Reducir animaciones** se muestran directamente los datos finales.
Cada animación libera su controlador y sus listeners al salir de la vista.

Las pruebas comprueban relaciones, saldos reconstruidos, anulaciones,
restauración, conservación e instalación única, límites de fechas y permisos.
También verifican el primer fotograma en cero, el recorrido parcial, los valores
finales, la espera fuera de pantalla y el respeto a reducir movimiento.
