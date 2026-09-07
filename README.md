# Farmacia JAE

Aplicación web en Flutter para centralizar ventas, inventario, compras,
reportes, seguridad y soporte de TI de la farmacia.

## Organización del proyecto

La estructura sigue el patrón de `tiendasalmeron`, pero con nombres
consistentes y responsabilidades separadas:

```text
lib/
├── core/
│   ├── app.dart
│   ├── services/
│   │   └── pharmacy_controller.dart
│   └── utils/
│       ├── formatters.dart
│       └── responsive.dart
├── models/
│   ├── dashboard/
│   ├── home/
│   ├── incidents/
│   ├── inventory/
│   ├── operations/
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

## Diseño responsive

- Menos de 900 px: navegación móvil mediante drawer.
- Menos de 720 px: paneles de dashboard y punto de venta apilados.
- Menos de 620 px: cabeceras, filas de inventario e incidentes adaptadas a
  formato vertical.

Los breakpoints viven en lib/core/utils/responsive.dart y las decisiones
importantes están comentadas junto al layout que las aplica. Las tarjetas
usan Wrap para reorganizarse automáticamente sin duplicar vistas.

## Comandos útiles

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
flutter build web
```

La aplicación se basa en el diagnóstico TI de Farmacia JAE y contempla los
módulos principales del sistema web integral: POS, inventario, alertas,
reportes, auditoría, roles, respaldos, continuidad e incidentes TI.
