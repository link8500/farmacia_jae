# Experiencia de trabajo y preferencias personales

## Separación de responsabilidades

La navegación se basa en tareas de farmacia, no en títulos del diagnóstico TI.

| Ubicación | Responsabilidad | Acceso |
| --- | --- | --- |
| Ventas → Facturación | Preparación, cobro e historial de comprobantes | Personal autorizado en su sede/caja |
| Mi cuenta → Preferencias | Apariencia, accesibilidad y comportamiento personal | Todos los usuarios autenticados |
| Mi cuenta → Ayuda y soporte | Ayuda de uso y seguimiento de problemas | Todos los usuarios autenticados |
| Gestión de la farmacia → Datos y mantenimiento | Respaldos, restauración y almacenamiento operativo | Solo administración |
| Gestión de la farmacia → Personal y asignaciones | Roles, asignaciones, puestos, sedes, cajas y catálogo por sede | Solo administración |

Las URLs previas de soporte y mantenimiento continúan funcionando para no
romper enlaces. Cambiar etiquetas no concede nuevos permisos administrativos.
Un fallo del almacenamiento operativo no impide abrir las preferencias.

## Facturación

Se eliminaron las tarjetas con forma de cápsula y el aviso grande de asignación
correcta. La barra global sucursal/caja se sustituyó por una ruta de navegación
como «Facturación › Nueva factura»; una asignación inválida sí genera un aviso
y bloquea el cobro. El directorio central conserva toda la información del puesto.

El catálogo tiene búsqueda, categorías, filtro de existencias y dos vistas:
tarjetas rectangulares y lista. Introducir un código de producto o de barras
exacto y pulsar Enter añade una unidad si está disponible. La búsqueda parcial
no cobra ni añade artículos automáticamente. El catálogo pagina lotes de 24
resultados para no construir miles de tarjetas a la vez.

El detalle de factura separa nombre, precio/unidad, cantidad, subtotal y total.
Vaciar respeta la preferencia personal de confirmación; eliminar una línea
solo descarta esa selección, sin modificar stock ni comprobantes.
Los productos no disponibles no se pueden añadir. El lector de pantalla recibe
una etiqueta completa del producto, sin repetir todo el contenido decorativo.

El cobro en efectivo muestra recibido y cambio, y rechaza importes insuficientes.
Tarjeta y transferencia registran el método sin simular autorizaciones bancarias.
Se mantienen el descuento FEFO por sucursal, las validaciones del controlador,
la asignación de caja y la fotografía histórica de cada comprobante.
No se introdujeron impuestos, descuentos ficticios ni facturación fiscal.
El historial tiene una pestaña propia, búsqueda, estado y carga progresiva.

## Preferencias por cuenta

Las opciones se aplican al instante, sin botón de guardar:

- Apariencia: tema claro/oscuro/sistema, acento azul/verde petróleo/violeta y
  densidad cómoda/compacta.
- Accesibilidad: tamaño de texto, contraste reforzado y movimiento reducido.
- Facturación y avisos: vista inicial en tarjetas/lista, confirmación de vaciado
  e indicador visual de alertas. Ocultar el indicador no desactiva alertas reales.

Las tres secciones incluyen una vista previa y guardado automático. La selección
del catálogo también puede cambiarse desde Facturación y se conserva para esa
cuenta. La reducción de movimiento del dispositivo siempre se respeta.
Restablecer confirma y reinicia solo las preferencias de la cuenta activa.

## Persistencia, migración y límites

El documento de preferencias v2 usa un mapa de perfiles `user:<id>`. El ámbito
`guest` corresponde al login, sin sesión. Cambiar o cerrar sesión selecciona el
perfil correspondiente y no hereda los ajustes del usuario anterior.
Las escrituras son serializadas; antes de guardar se recuperan los perfiles
existentes para no sobrescribir ajustes de otras cuentas todavía no leídos.
Una lectura tardía no revierte una elección reciente del usuario.

Se conserva la clave local anterior. Los documentos v1 globales se conservan en
`guest`: no se inventa un propietario. Los perfiles nuevos comienzan con valores
predeterminados. Los fallos de lectura/escritura son visibles y pueden reintentarse.
Este documento no contiene contraseñas, tokens, sesión, permisos ni inventario.

Todo sigue siendo local a un navegador. Las preferencias no se sincronizan entre
dispositivos y no son una barrera de seguridad. La presentación pública conserva
su diseño y no inicializa los datos operativos ni estas preferencias.

## Verificación

Se prueban perfiles independientes, cambios rápidos entre cuentas, migración v1,
lecturas tardías, restablecimiento personal, efecto real del tema/contraste,
acceso de empleado a preferencias sin respaldos, persistencia de la vista del
catálogo y los tres métodos de cobro. Las vistas se comprueban a 320, 390, 768
y 1440 píxeles, en claro/oscuro, con texto grande y contraste reforzado.
