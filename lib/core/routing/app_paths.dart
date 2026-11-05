import '../config/administration_features.dart';

/// Rutas públicas y privadas. No se muestran enlaces privados en presentación.
abstract final class AppPaths {
  static const presentation = '/presentacion';
  static const presentationAbout = '$presentation/nosotros';
  static const presentationServices = '$presentation/servicios';
  static const presentationContact = '$presentation/contacto';
  static const publicPromotions = '$presentation/promociones';
  static const administration = '/administracion';
  // El formulario y el resumen comparten la entrada; la sesión decide la vista.
  static const login = administration;
  static const legacyLogin = '$administration/login';
  static const profile = '/administracion/perfil';
  static const products = '/administracion/productos';
  static const cash = '/administracion/caja';
  static const organization = '/administracion/sucursales';
  static const billingRegisters = '/administracion/cajas';
  static const preferences = '/administracion/preferencias';
  static const promotions = '/administracion/promociones';

  /// Mantiene los índices de los módulos existentes para preservar sus acciones.
  static const sections = <String>[
    administration,
    '$administration/ventas',
    '$administration/inventario',
    '$administration/compras',
    '$administration/proveedores',
    '$administration/clientes',
    '$administration/reportes',
    '$administration/incidentes',
    '$administration/configuracion',
    profile,
    products,
    cash,
    organization,
    billingRegisters,
    preferences,
    promotions,
  ];

  static const titles = <String>[
    'Resumen general',
    'Facturación',
    'Lotes',
    'Compras',
    'Proveedores',
    'Clientes',
    'Reportes',
    'Ayuda y soporte',
    'Datos y mantenimiento',
    'Mi perfil',
    'Productos',
    'Caja y arqueos',
    'Personal y asignaciones',
    'Cajas de facturación',
    'Mis preferencias',
    'Promociones',
  ];

  /// Estas vistas requieren el rol de administrador, además de una sesión.
  static const administratorOnly = <int>{3, 4, 6, 8, 12, 15};

  /// Se reserva el índice de Caja para no desplazar las rutas ya existentes.
  static const disabledSections = <int>{
    if (!AdministrationFeatures.cashEnabled) 11,
  };
  static List<int> get enabledSectionIndices => [
    for (var index = 0; index < sections.length; index++)
      if (!disabledSections.contains(index)) index,
  ];

  static int indexOf(String path) => sections.indexOf(path);

  static const preferenceLabels = [
    'Apariencia',
    'Accesibilidad',
    'Facturación y avisos',
  ];

  /// Solo se conservan sub-vistas conocidas; nunca se acepta un destino externo.
  static int preferenceSection(Uri uri) =>
      switch (uri.queryParameters['seccion']) {
        'accesibilidad' => 1,
        'facturacion' => 2,
        _ => 0,
      };
  static String preferenceLocation(int section) => switch (section) {
    1 => '$preferences?seccion=accesibilidad',
    2 => '$preferences?seccion=facturacion',
    _ => preferences,
  };
  static String salesLocation(bool history) =>
      '${sections[1]}${history ? '?vista=historial' : ''}';
  static String reportLocation(bool details) =>
      '${sections[6]}${details ? '?vista=detalle' : ''}';

  static String productLocation(String id) =>
      Uri(path: products, queryParameters: {'producto': id}).toString();
  static String registerLocation(String id, {DateTime? start, DateTime? end}) =>
      Uri(
        path: billingRegisters,
        queryParameters: {
          'caja': id,
          if (start != null && end != null)
            'desde': start.toIso8601String().substring(0, 10),
          if (start != null && end != null)
            'hasta': end.toIso8601String().substring(0, 10),
        },
      ).toString();
  static String supportLocation(String id) =>
      Uri(path: sections[7], queryParameters: {'solicitud': id}).toString();
  static String promotionLocation(String id) =>
      Uri(path: promotions, queryParameters: {'promocion': id}).toString();
  static const organizationLabels = [
    'Personal',
    'Sucursales',
    'Cajas',
    'Catálogo por sucursal',
  ];
  static int organizationSection(Uri uri) =>
      switch (uri.queryParameters['seccion']) {
        'sucursales' => 1,
        'cajas' => 2,
        'catalogo' => 3,
        _ => 0,
      };
  static String organizationLocation(int section) => switch (section) {
    1 => '$organization?seccion=sucursales',
    2 => '$organization?seccion=cajas',
    3 => '$organization?seccion=catalogo',
    _ => organization,
  };
  static String purchaseLocation(String id, {String? supplierId}) => Uri(
    path: sections[3],
    queryParameters: {
      'compra': id,
      if (supplierId != null && supplierId.isNotEmpty) 'proveedor': supplierId,
    },
  ).toString();
  static String contactLocation(int section, String id) => Uri(
    path: sections[section],
    queryParameters: {'contacto': id},
  ).toString();
  static String inventoryLocation({
    String? productId,
    String? lotId,
    bool lots = false,
  }) {
    final query = {
      if (productId != null && productId.isNotEmpty) 'producto': productId,
      if (lotId != null && lotId.isNotEmpty) 'lote': lotId,
      if (lots || productId != null) 'vista': 'lotes',
    };
    return Uri(
      path: sections[2],
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// Ruta de lectura por módulo, no etiquetas de sucursal ni de permisos.
  /// Los padres son accesos reales y el último elemento describe la vista actual.
  static List<({String label, String? location})> breadcrumbs(
    int index,
    Uri uri,
  ) {
    if (index == 12) {
      return [
        (label: 'Gestión de la farmacia', location: organization),
        (label: 'Personal y asignaciones', location: organization),
        (label: organizationLabels[organizationSection(uri)], location: null),
      ];
    }
    final auxiliaryDetail = switch (index) {
      13 when uri.queryParameters['caja']?.isNotEmpty == true =>
        'Ventas de la caja',
      7 when uri.queryParameters['solicitud']?.isNotEmpty == true =>
        'Detalle de solicitud',
      15 when uri.queryParameters['promocion']?.isNotEmpty == true =>
        'Detalle de campaña',
      _ => null,
    };
    if (auxiliaryDetail != null) {
      return [
        (label: titles[index], location: sections[index]),
        (label: auxiliaryDetail, location: null),
      ];
    }
    if (index == 6 && uri.queryParameters['vista'] == 'detalle') {
      return [
        (label: 'Dashboard', location: administration),
        (label: 'Reportes', location: sections[6]),
        (label: 'Detalle de registros', location: null),
      ];
    }
    final detail = switch (index) {
      3 when uri.queryParameters['compra']?.isNotEmpty == true =>
        'Detalle de compra',
      10 when uri.queryParameters['producto']?.isNotEmpty == true =>
        'Detalle del producto',
      2 when uri.queryParameters['lote']?.isNotEmpty == true =>
        'Detalle del lote',
      2 when uri.queryParameters['producto']?.isNotEmpty == true =>
        'Lotes del producto',
      4 when uri.queryParameters['contacto']?.isNotEmpty == true =>
        'Detalle del proveedor',
      5 when uri.queryParameters['contacto']?.isNotEmpty == true =>
        'Detalle del cliente',
      _ => null,
    };
    if (detail != null) {
      if (index == 3 && uri.queryParameters['proveedor']?.isNotEmpty == true) {
        return [
          (label: 'Inventario', location: products),
          (label: 'Proveedores', location: sections[4]),
          (
            label: 'Detalle del proveedor',
            location: contactLocation(4, uri.queryParameters['proveedor']!),
          ),
          (label: detail, location: null),
        ];
      }
      return [
        (
          label: index == 5 ? 'Ventas' : 'Inventario',
          location: index == 5 ? sections[1] : products,
        ),
        (label: titles[index], location: sections[index]),
        (label: detail, location: null),
      ];
    }
    if (index == 1) {
      return [
        (label: 'Facturación', location: sections[1]),
        (
          label: uri.queryParameters['vista'] == 'historial'
              ? 'Historial de facturas'
              : 'Nueva factura',
          location: null,
        ),
      ];
    }
    if (index == 14) {
      return [
        (label: 'Mi cuenta', location: profile),
        (label: 'Mis preferencias', location: preferences),
        (label: preferenceLabels[preferenceSection(uri)], location: null),
      ];
    }
    final (group, destination) = switch (index) {
      0 || 6 => ('Dashboard', administration),
      2 || 3 || 4 || 10 => ('Inventario', products),
      5 || 11 || 13 => ('Ventas', sections[1]),
      8 || 12 || 15 => ('Gestión de la farmacia', organization),
      _ => ('Mi cuenta', profile),
    };
    return [
      (label: group, location: destination),
      (label: index == 0 ? 'Resumen' : titles[index], location: null),
    ];
  }

  /// Evita redirecciones externas o destinos arbitrarios desde el login.
  static String safeDestination(String? destination) {
    final uri = Uri.tryParse(destination ?? '');
    if (uri == null || uri.hasScheme || uri.hasAuthority) return administration;
    final index = indexOf(uri.path);
    if (index < 0 || disabledSections.contains(index)) return administration;
    if (index == 1) {
      return salesLocation(uri.queryParameters['vista'] == 'historial');
    }
    if (index == 14) return preferenceLocation(preferenceSection(uri));
    if (index == 12) return organizationLocation(organizationSection(uri));
    if (index == 13 && uri.queryParameters['caja']?.isNotEmpty == true) {
      return registerLocation(
        uri.queryParameters['caja']!,
        start: DateTime.tryParse(uri.queryParameters['desde'] ?? ''),
        end: DateTime.tryParse(uri.queryParameters['hasta'] ?? ''),
      );
    }
    if (index == 7 && uri.queryParameters['solicitud']?.isNotEmpty == true) {
      return supportLocation(uri.queryParameters['solicitud']!);
    }
    if (index == 15 && uri.queryParameters['promocion']?.isNotEmpty == true) {
      return promotionLocation(uri.queryParameters['promocion']!);
    }
    if (index == 3 && uri.queryParameters['compra']?.isNotEmpty == true) {
      return purchaseLocation(
        uri.queryParameters['compra']!,
        supplierId: uri.queryParameters['proveedor'],
      );
    }
    if (index == 6) {
      return reportLocation(uri.queryParameters['vista'] == 'detalle');
    }
    if (index == 10 && uri.queryParameters['producto']?.isNotEmpty == true) {
      return productLocation(uri.queryParameters['producto']!);
    }
    if ((index == 4 || index == 5) &&
        uri.queryParameters['contacto']?.isNotEmpty == true) {
      return contactLocation(index, uri.queryParameters['contacto']!);
    }
    if (index == 2) {
      return inventoryLocation(
        productId: uri.queryParameters['producto'],
        lotId: uri.queryParameters['lote'],
        lots: uri.queryParameters['vista'] == 'lotes',
      );
    }
    return uri.path;
  }
}
