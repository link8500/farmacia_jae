# Reportes visuales y promociones

## Reportes

`/administracion/reportes` conserva la restricción de administrador. El selector
de reporte, el período inclusivo y los filtros de ventas alimentan tanto los
indicadores como los gráficos y el detalle. Los accesos rápidos permiten hoy,
7 días, 30 días y mes actual. La búsqueda inferior afecta solo filas y CSV;
se indica expresamente para evitar confundir un resultado buscado con un total.
La exportación incluye todas las coincidencias y no solo las 20 filas visibles.

Los gráficos se calculan en `report_visuals.dart` y se dibujan exclusivamente
con `fl_chart` en `report_chart_card.dart`. Los contenedores, leyendas, unidades,
estados vacíos y explicaciones son reutilizables. No se generan datos ficticios
para llenar un gráfico vacío. La tabla de escritorio tiene desplazamiento
horizontal; en móvil y con texto ampliado se usa detalle desplegable por fila.

### Criterios de cálculo

- **Evolución:** suma de facturas vigentes por fecha de emisión. Días sin ventas
  valen cero. El período agrupa por días (hasta 31), semanas (hasta 186 días),
  meses (hasta 36 meses) o años. Los intervalos extremos respetan el filtro.
- **Pagos:** porcentajes por importe de facturas vigentes. No confirma pagos
  bancarios. Efectivo, tarjeta y transferencia son métodos registrados localmente.
- **Productos:** seis mayores cantidades, agrupadas por ID y unidad histórica.
  No se convierten cajas, frascos ni tabletas entre sí.
- **Sucursales, cajas y operadores:** seis mayores importes vigentes por
  identificadores estables conservados al facturar. Renombrar o reasignar un
  empleado no mueve su historial. Los registros antiguos sin asignación se
  identifican expresamente. Cajas de igual nombre en sedes distintas se separan.
- **Estado de facturas:** número de vigentes y anuladas, independiente de su
  importe. Si se filtran solo anuladas, las ventas netas y sus rankings valen cero.
- **Indicadores:** ventas netas, cantidad vigente, ticket promedio, unidades y
  anulaciones. Ventas netas significa facturas no anuladas; no es utilidad.
  El ticket divide centavos enteros y redondea al centavo más cercano: C$ 9.95
  entre dos facturas produce C$ 4.98, evitando errores de aproximación binaria.
- **Inventario:** foto actual de la sucursal consultada; las fechas no reconstruyen
  saldos anteriores. La distribución cuenta cada unidad una vez: primero
  archivadas/no habilitadas, después vencidas, próximas a vencer (hasta 90 días)
  y vigentes. La comparación de mínimo prioriza el menor margen disponible menos
  mínimo. Conserva la unidad de cada ficha.
- **Compras:** órdenes creadas en el período de la sucursal consultada. Estados
  por cantidad; proveedores por importe de órdenes recibidas. No representa flujo
  de pagos, deuda ni fecha real de recepción.
- **Actividad:** número de movimientos, eventos de auditoría, casos de soporte o
  arqueos anteriores por su fecha de creación. No suma importes ni unidades
  movidas. El módulo antiguo de efectivo continúa desactivado.

Las líneas no se suavizan para evitar picos o valores negativos artificiales.
Las leyendas y el detalle de intervalos permiten consultar cifras sin depender
del color o de situar el puntero. Se respeta la preferencia de reducir animaciones.

## Presentación y promociones

Rutas públicas:

| Vista | Ruta |
| --- | --- |
| Inicio breve | `/presentacion` |
| Nosotros | `/presentacion/nosotros` |
| Servicios y categorías | `/presentacion/servicios` |
| Promociones vigentes | `/presentacion/promociones` |
| Contacto | `/presentacion/contacto` |

El menú cambia de ruta, en lugar de desplazarse por una página larga. Todas
comparten cabecera, menú móvil y pie. Las vistas informativas siguen estáticas,
sin consulta de datos operativos ni botones de acceso a administración.

En **Gestión de la farmacia → Promociones** el administrador crea campañas con
título, descripción, etiqueta, condiciones, fechas e ilustración local opcional.
Los estados son Borrador, Publicada y Archivada. Las publicadas aparecen solo
desde la fecha inicial hasta la final, ambas incluidas. Una publicación futura
aparece como Programada en el editor y una vencida como Finalizada. Archivar es
reversible desde Editar campaña. No hay eliminación permanente ni descuentos
automáticos: las campañas son contenido informativo.

`PromotionsController` comprueba permisos también en sus comandos. El nuevo
índice de navegación se añadió al final para conservar los índices anteriores.
El guard bloquea el acceso directo de empleados y visitantes al editor.

### Persistencia y recuperación

`PromotionStore` mantiene dos documentos independientes:

- `farmacia_jae.promotions.editor.v1`: documento del editor, incluidos borradores.
- `farmacia_jae.promotions.public.v1`: proyección de publicaciones para la vista pública.

La consulta pública no abre el documento del editor, perfiles ni inventario.
Una lectura inválida del editor bloquea sobrescrituras hasta recuperarlo. Si
se guarda el editor pero falla la proyección pública, se muestra publicación
pendiente y se permite reintentar, incluso después de recargar. Reintentar el
formulario conserva la identidad y no duplica la campaña.

**Alcance local:** las promociones se comparten entre las vistas de esta app en
el mismo navegador y origen. No hay servidor, sincronización entre equipos,
publicación remota ni actualización automática de otras pestañas abiertas.
Una persona que visite la web desde otro dispositivo no recibe esas campañas.
La compilación desplegada en Netlify tampoco incluye el almacenamiento local.
Los respaldos operativos JSON no contienen promociones; sus claves son separadas.
El almacenamiento del cliente y los guards de demostración no sustituyen la
seguridad de un servidor. No introducir datos privados o de producción.
