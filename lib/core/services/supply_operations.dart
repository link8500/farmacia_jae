part of 'pharmacy_controller.dart';

/// Catálogo comercial N:M y valoración. La ficha, el proveedor y el lote tienen
/// identidades separadas; el historial no cambia al actualizar una referencia.
extension SupplyOperations on PharmacyController {
  List<ProductSupplier> get productSuppliers =>
      isAdministrator ? List.unmodifiable(_productSuppliers) : const [];

  List<Contact> suppliersForProduct(String productId) {
    if (!isAdministrator) return const [];
    final ids = _productSuppliers
        .where((r) => r.productId == productId && r.active)
        .map((r) => r.supplierId)
        .toSet();
    return _contacts
        .where(
          (c) =>
              c.kind == ContactKind.supplier && c.active && ids.contains(c.id),
        )
        .toList();
  }

  ProductSupplier? supplierTerms(String productId, String supplierId) =>
      productSuppliers
          .where((r) => r.productId == productId && r.supplierId == supplierId)
          .firstOrNull;

  String? saveProductSupplier({
    required String productId,
    required String supplierId,
    String supplierCode = '',
    double referenceCost = 0,
    int leadDays = 0,
    bool active = true,
  }) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final supplier = contactById(supplierId);
    if (productById(productId)?.active != true ||
        supplier?.kind != ContactKind.supplier ||
        supplier?.active != true) {
      return 'Selecciona un producto y un proveedor activos.';
    }
    if (!referenceCost.isFinite ||
        referenceCost < 0 ||
        referenceCost > 1000000 ||
        leadDays < 0 ||
        leadDays > 365) {
      return 'Revisa el costo de referencia y el plazo (0 a 365 días).';
    }
    final record = ProductSupplier(
      productId: productId,
      supplierId: supplierId,
      supplierCode: supplierCode.trim(),
      referenceCost: money(referenceCost),
      leadDays: leadDays,
      active: active,
    );
    final i = _productSuppliers.indexWhere(
      (r) => r.productId == productId && r.supplierId == supplierId,
    );
    if (i < 0) {
      _productSuppliers.add(record);
    } else {
      _productSuppliers[i] = record;
    }
    _commit(
      'Catálogo de proveedor actualizado',
      '${productById(productId)!.name} · ${supplier!.name}',
    );
    return null;
  }

  /// El precio se decide después de conocer la recepción. Afecta ventas nuevas,
  /// no facturas ya emitidas. No se permite cambiarlo con ese producto en carrito.
  String? setProductPrice(String productId, double price) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final product = productById(productId);
    if (product == null ||
        !product.active ||
        !lots.any((l) => l.productId == productId)) {
      return 'Recibe primero un lote de este producto en la sucursal.';
    }
    if (!price.isFinite || money(price) <= 0 || price > 1000000) {
      return 'Indica un precio unitario mayor que cero.';
    }
    if (_cart.any((l) => l.product.id == productId)) {
      return 'Finaliza o retira este producto de la venta pendiente.';
    }
    _products[_products.indexOf(product)] = product.withPrice(money(price));
    _commit(
      'Precio unitario actualizado',
      '${product.code} · ${money(price)} por ${product.unit}',
    );
    return null;
  }

  /// Completa o corrige la documentación de lotes anteriores con auditoría,
  /// conservando cantidades, costos y fechas de recepción y vencimiento.
  String? documentLot(
    String lotId, {
    required String supplierId,
    required DateTime manufacturedAt,
    required String location,
  }) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final lot = lots.where((l) => l.id == lotId).firstOrNull;
    final supplier = contactById(supplierId);
    if (lot == null ||
        supplier?.kind != ContactKind.supplier ||
        (supplier?.active != true && supplierId != lot.supplierId) ||
        location.trim().isEmpty) {
      return 'Selecciona proveedor y ubicación válidos para el lote de esta sucursal.';
    }
    final date = InventoryLot.dayOnly(manufacturedAt);
    if (date.isAfter(InventoryLot.dayOnly(lot.receivedAt)) ||
        !date.isBefore(InventoryLot.dayOnly(lot.expiry))) {
      return 'La fabricación debe ser anterior al vencimiento y no posterior a la recepción.';
    }
    _lots[_lots.indexOf(lot)] = lot.withMetadata(
      supplierId: supplierId,
      manufacturedAt: date,
      location: location.trim(),
    );
    _commit(
      'Trazabilidad de lote actualizada',
      '${lot.code} · ${supplier!.name} · ${location.trim()}',
    );
    return null;
  }

  /// Reubicación rápida, independiente del resto de la documentación del lote.
  String? relocateLot(String lotId, String location) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final lot = lots.where((l) => l.id == lotId).firstOrNull;
    if (lot == null || location.trim().isEmpty) {
      return 'Selecciona un lote de la sucursal y una ubicación.';
    }
    _lots[_lots.indexOf(lot)] = InventoryLot(
      id: lot.id,
      productId: lot.productId,
      branchId: lot.branchId,
      code: lot.code,
      quantity: lot.quantity,
      expiry: lot.expiry,
      receivedAt: lot.receivedAt,
      unitCost: lot.unitCost,
      supplierId: lot.supplierId,
      manufacturedAt: lot.manufacturedAt,
      location: location.trim(),
    );
    _commit(
      'Ubicación de lote actualizada',
      '${lot.code} · ${location.trim()}',
    );
    return null;
  }
}
