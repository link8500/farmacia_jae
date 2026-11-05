import 'dart:convert';
import '../config/administration_features.dart';
import '../config/demo_people.dart';
import 'package:flutter/foundation.dart';
import '../utils/json_value.dart';
import '../utils/legacy_interface_text.dart';
import '../../models/auth/models/session_user.dart';
import '../../models/contacts/models/contact.dart';
import '../../models/purchases/models/purchase_order.dart';
import '../../models/sales/models/sale_receipt.dart';
import '../../models/cash/models/cash_session.dart';
import '../../models/incidents/models/support_case.dart';
import '../../models/audit/models/audit_entry.dart';
import '../../models/inventory/models/inventory_movement.dart';
import 'local_administration_store.dart';
import '../../models/products/models/product.dart';
import '../../models/products/models/product_supplier.dart';
import '../../models/products/models/product_illustration.dart';
import '../../models/inventory/models/inventory_lot.dart';
import '../../models/inventory/models/inventory_summary.dart';
import '../../models/sales/models/cart_line.dart';
import '../../models/organization/models/organization.dart';
import 'pharmacy_demo_data.dart';
import 'pharmacy_demo_scenario.dart';
part 'administration_operations.dart';
part 'supply_operations.dart';
part 'administration_persistence.dart';
part 'organization_operations.dart';
part 'demo_scenario_operations.dart';

/// Coordina catálogo, lotes y venta local sin acoplarlos a las vistas.
///
/// Cambio de dominio: registrar un producto NO registra existencias. Todo
/// stock se deriva de los lotes. El prototipo guarda datos locales, sin API ni servidor.
class PharmacyController extends ChangeNotifier {
  PharmacyController({
    bool seedDemo = true,
    this.seedDemoHistory = false,
    DateTime Function()? clock,
    this.store,
    this.userProvider,
    this.cashEnabled = AdministrationFeatures.cashEnabled,
  }) : _clock = clock ?? DateTime.now {
    isLoaded = store == null;
    if (seedDemo) {
      _products.addAll(PharmacyDemoData.products);
      _branchProducts.addAll(
        _products.map((p) => BranchProduct(mainBranchId, p.id)),
      );
      _lots.addAll(PharmacyDemoData.lots(today));
      _contacts.addAll(const [
        Contact(
          id: 'supplier-demo',
          kind: ContactKind.supplier,
          name: 'Proveedor general',
        ),
        Contact(
          id: 'customer-demo',
          kind: ContactKind.customer,
          name: 'Cliente general',
        ),
      ]);
      if (seedDemoHistory && store == null) _installDemoHistory();
    }
    if (seedDemo && _productSuppliers.isEmpty) {
      _productSuppliers.addAll(
        _products.map(
          (p) => ProductSupplier(productId: p.id, supplierId: 'supplier-demo'),
        ),
      );
    }
    _enrichDemoPeople();
  }

  final DateTime Function() _clock;
  final AdministrationStore? store;

  /// La entrada de demostración lo activa; otras entradas pueden usar datos mínimos.
  final bool seedDemoHistory;
  int _demoScenarioVersion = 0;
  bool get hasDemoHistory =>
      _demoScenarioVersion >= PharmacyDemoScenario.version;
  String? demoDataError;

  /// La suspensión de Caja no modifica ni limpia sus sesiones y movimientos.
  final bool cashEnabled;
  final SessionUser? Function()? userProvider;
  final List<Contact> _contacts = [];
  final List<PurchaseOrder> _purchases = [];
  final List<SaleReceipt> _sales = [];
  final List<CashSession> _cashSessions = [];
  final List<CashMovement> _cashMovements = [];
  final List<SupportCase> _incidents = [];
  final List<AuditEntry> _audit = [];
  final List<InventoryMovement> _movements = [];
  final List<PharmacyBranch> _branches = List.of(OrganizationDefaults.branches);
  final List<BillingRegister> _registers = List.of(
    OrganizationDefaults.registers,
  );
  final List<StaffMember> _staff = List.of(OrganizationDefaults.staff);
  final List<BranchProduct> _branchProducts = [];
  String _selectedBranchId = mainBranchId;
  bool isLoaded = true;
  bool loadFailed = false;
  bool _disposed = false;
  int _pendingWrites = 0;
  int _revision = 0;
  Future<void>? _initialization;
  Future<void> _writes = Future.value();
  String? storageError;
  DateTime? lastSavedAt, lastBackupAt;
  SessionUser? _sessionUser;
  bool get isSaving => _pendingWrites > 0;
  bool get isAdministrator =>
      userProvider == null ||
      (userProvider?.call()?.isAdministrator == true &&
          _staff.any(
            (s) =>
                s.id == userProvider?.call()?.id &&
                s.active &&
                s.role == UserRole.administrator,
          ));
  // Sin proveedor se permite el banco de pruebas local. Con proveedor pero sin
  // sesión NO se suplanta a la cuenta administradora para consultar existencias.
  String get actorId =>
      userProvider == null ? 'demo-admin' : userProvider?.call()?.id ?? '';
  String get actorName =>
      userProvider?.call()?.name ?? currentStaff?.name ?? 'Operador local';
  DateTime get now => _clock();
  void _notify() => notifyListeners();

  String _nextId(String prefix) =>
      '$prefix-${(++_sequence).toString().padLeft(6, '0')}';
  String? _permissionError({bool administrator = false}) {
    if (_disposed || !isLoaded || loadFailed) {
      return 'Los datos locales no están disponibles. Revisa el respaldo o reintenta la carga.';
    }
    if (userProvider != null && userProvider?.call() == null) {
      return 'Debes iniciar sesión.';
    }
    if (userProvider != null && currentStaff?.active != true) {
      return 'La cuenta no está activa en el personal de la farmacia.';
    }
    if (administrator && !isAdministrator) {
      return 'Esta acción requiere un administrador.';
    }
    return null;
  }

  void _commit(String action, String detail) {
    _audit.add(
      AuditEntry(
        id: _nextId('AUD'),
        at: now,
        actorId: actorId,
        actorName: actorName,
        action: action,
        detail: detail,
      ),
    );
    _revision++;
    notifyListeners();
    _queueSave();
  }

  void _stockMovement(InventoryLot lot, int delta, String reason) =>
      _movements.add(
        InventoryMovement(
          id: _nextId('IM'),
          lotId: lot.id,
          productId: lot.productId,
          at: now,
          delta: delta,
          balance: lot.quantity,
          reason: reason,
        ),
      );
  final List<ProductSupplier> _productSuppliers = [];
  final List<Product> _products = [];
  final List<InventoryLot> _lots = [];
  final List<CartLine> _cart = [];
  int _sequence = 0;

  /// Las vistas consultan colecciones de solo lectura; modifican mediante
  /// comandos para conservar validaciones y notificaciones en un solo lugar.
  List<Product> get products => List.unmodifiable(
    _products.where(
      (p) =>
          productEnabled(workingBranchId, p.id) &&
          workingBranch?.active == true,
    ),
  );
  List<InventoryLot> get lots => List.unmodifiable(
    _lots.where(
      (l) => l.branchId == workingBranchId && workingBranch?.active == true,
    ),
  );
  List<CartLine> get cart => List.unmodifiable(_cart);
  DateTime get today => InventoryLot.dayOnly(_clock());
  String inventorySearch = '';
  String inventoryFilter = 'Todos';

  Product? productById(String id) {
    for (final product in _products) {
      if (product.id == id &&
          (isAdministrator || products.any((p) => p.id == id))) {
        return product;
      }
    }
    return null;
  }

  /// El reporte global de administración puede resolver lotes históricos de
  /// otra sede; un empleado nunca obtiene esa lectura fuera de su asignación.
  InventoryLot? lotById(String id) {
    for (final lot in _lots) {
      if (lot.id == id &&
          (isAdministrator ||
              (currentStaff?.active == true &&
                  lot.branchId == workingBranchId))) {
        return lot;
      }
    }
    return null;
  }

  /// Saldo físico incluye vencidos; disponibilidad de venta los excluye.
  int get stockTotal => lots.fold(0, (total, lot) => total + lot.quantity);
  int get availableTotal => lots
      .where(
        (lot) =>
            productEnabled(workingBranchId, lot.productId) &&
            productById(lot.productId)?.active == true &&
            !lot.isExpired(today),
      )
      .fold(0, (n, lot) => n + lot.quantity);
  int availableStock(Product product) => lots
      .where(
        (lot) =>
            productEnabled(workingBranchId, product.id) &&
            product.active &&
            lot.productId == product.id &&
            !lot.isExpired(today),
      )
      .fold(0, (total, lot) => total + lot.quantity);

  /// Resumen calculado por producto; nunca se guarda un segundo stock mutable.
  InventorySummary summaryFor(Product product) {
    final entries = lots
        .where((lot) => lot.productId == product.id && lot.quantity > 0)
        .toList();
    final sellable =
        entries.where((lot) => product.active && !lot.isExpired(today)).toList()
          ..sort((a, b) => a.expiry.compareTo(b.expiry));
    return InventorySummary(
      product: product,
      totalQuantity: entries.fold(0, (n, lot) => n + lot.quantity),
      availableQuantity: sellable.fold(0, (n, lot) => n + lot.quantity),
      lotCount: entries.length,
      nextExpiry: sellable.isEmpty ? null : sellable.first.expiry,
      hasExpiringLots: entries.any((lot) => lot.isExpiring(today)),
      hasExpiredLots: entries.any((lot) => lot.isExpired(today)),
    );
  }

  List<InventorySummary> get inventory => products.map(summaryFor).toList();
  int get lowStockCount =>
      inventory.where((entry) => entry.product.active && entry.isLow).length;
  int get expiringCount => lots.where((lot) => lot.isExpiring(today)).length;
  int get expiredCount =>
      lots.where((lot) => lot.quantity > 0 && lot.isExpired(today)).length;

  bool _matchesProduct(Product product, String query) => [
    product.name,
    product.code,
    product.barcode,
    product.category,
    product.activeIngredient,
    product.presentation,
    product.dosage,
    product.manufacturer,
    product.origin,
  ].any((value) => value.toLowerCase().contains(query));

  /// Búsqueda compartida del resumen y sus lotes (incluye el código de lote).
  List<InventorySummary> get visibleInventory {
    final query = inventorySearch.trim().toLowerCase();
    return inventory.where((entry) {
      final matches =
          _matchesProduct(entry.product, query) ||
          lots.any(
            (lot) =>
                lot.productId == entry.product.id &&
                (lot.code.toLowerCase().contains(query) ||
                    lot.location.toLowerCase().contains(query) ||
                    (contactById(
                          lot.supplierId,
                        )?.name.toLowerCase().contains(query) ??
                        false)),
          );
      final matchesState = switch (inventoryFilter) {
        'Bajo mínimo' => entry.product.active && entry.isLow,
        'Por vencer' => entry.hasExpiringLots,
        'Vencidos' => entry.hasExpiredLots,
        _ => true,
      };
      return matches && matchesState;
    }).toList();
  }

  List<InventoryLot> get visibleLots {
    final ids = visibleInventory.map((entry) => entry.product.id).toSet();
    final query = inventorySearch.trim().toLowerCase();
    final result = lots.where((lot) {
      if (!ids.contains(lot.productId)) return false;
      final product = productById(lot.productId)!;
      if (!_matchesProduct(product, query) &&
          !lot.code.toLowerCase().contains(query) &&
          !lot.location.toLowerCase().contains(query) &&
          !(contactById(lot.supplierId)?.name.toLowerCase().contains(query) ??
              false)) {
        return false;
      }
      return switch (inventoryFilter) {
        'Por vencer' => lot.isExpiring(today),
        'Vencidos' => lot.quantity > 0 && lot.isExpired(today),
        _ => true,
      };
    }).toList()..sort((a, b) => a.expiry.compareTo(b.expiry));
    return result;
  }

  void setInventorySearch(String value) {
    inventorySearch = value;
    notifyListeners();
  }

  void setInventoryFilter(String value) {
    inventoryFilter = value;
    notifyListeners();
  }

  /// Identifica únicamente los ocho productos demo originales cuya imagen
  /// está ausente/desconocida. No adivina imágenes de otros medicamentos.
  String _recoverableIllustration(Product product) =>
      ProductIllustrations.legacyKey(
        id: product.id,
        code: product.code,
        name: product.name,
        presentation: product.presentation,
      );
  List<Product> get productsWithRecoverableIllustration => !isAdministrator
      ? const []
      : List.unmodifiable(
          _products.where(
            (product) =>
                ProductIllustrations.find(product.illustrationKey) == null &&
                _recoverableIllustration(product).isNotEmpty,
          ),
        );

  /// Reparación explícita: no se sobrescribe automáticamente «Sin imagen»,
  /// pues puede ser una selección deliberada. Una confirmación de la UI permite
  /// recuperar en lote asociaciones vacías de sesiones antiguas/hot reload.
  String? restoreMissingDemoIllustrations() {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final candidates = productsWithRecoverableIllustration;
    if (candidates.isEmpty) {
      return 'No hay imágenes pendientes de recuperar.';
    }
    for (final product in candidates) {
      _products[_products.indexOf(product)] = product.withIllustrationKey(
        _recoverableIllustration(product),
      );
    }
    _commit(
      'Imágenes de productos recuperadas',
      '${candidates.length} asociaciones visuales · ${candidates.map((p) => p.code).join(', ')}',
    );
    return null;
  }

  /// Registra SOLO la ficha. Devuelve el error sin modificar nada al fallar.
  String? registerProduct({
    String? id,
    required String code,
    required String name,
    required String category,
    required String presentation,
    required String unit,
    required int minimum,
    double? price,
    String? dosage,
    String? measurementUnit,
    String? origin,
    String? manufacturer,
    String? description,
    String? indications,
    String? contraindications,
    bool? requiresPrescription,
    int? packageUnits,
    String activeIngredient = '',
    String barcode = '',
    String? illustrationKey,
  }) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    if (workingBranch?.active != true) return 'Selecciona una sucursal activa.';
    final normalized = code.trim().toUpperCase();
    if ([
      normalized,
      name,
      category,
      presentation,
      unit,
    ].any((value) => value.trim().isEmpty)) {
      return 'Completa los datos obligatorios del producto.';
    }
    final effectivePrice =
        price ?? (id == null ? 0 : productById(id)?.price ?? 0);
    if ((packageUnits != null &&
            (packageUnits < 1 || packageUnits > 1000000)) ||
        minimum < 0 ||
        minimum > 1000000 ||
        !effectivePrice.isFinite ||
        effectivePrice < 0 ||
        effectivePrice > 1000000) {
      return 'Revisa el precio, las unidades por envase y el mínimo de reposición.';
    }
    if (_products.any(
      (product) => product.id != id && product.code.toUpperCase() == normalized,
    )) {
      return 'Ya existe un producto con ese código.';
    }
    if (barcode.trim().isNotEmpty &&
        _products.any(
          (product) => product.id != id && product.barcode == barcode.trim(),
        )) {
      return 'El código de barras ya pertenece a otro producto.';
    }
    final existing = id == null ? null : productById(id);
    if (id != null && existing == null) return 'Producto no encontrado.';
    // Omitir el parámetro conserva la selección al editar desde otros flujos.
    // Enviar vacío la elimina explícitamente, sin reactivarla al recargar.
    final imageKey = illustrationKey?.trim() ?? existing?.illustrationKey ?? '';
    if (imageKey.isNotEmpty && ProductIllustrations.find(imageKey) == null) {
      return 'Selecciona una imagen disponible del catálogo.';
    }
    if (existing != null &&
        (_lots.any((lot) => lot.productId == id) ||
            _purchases.any((p) => p.lines.any((l) => l.productId == id)) ||
            _cart.any((l) => l.product.id == id)) &&
        (existing.unit != unit.trim() ||
            (packageUnits != null && existing.packageUnits != packageUnits))) {
      return 'La unidad de venta no se cambia cuando existen lotes. Registra otra ficha.';
    }
    final record = Product(
      id: id ?? _nextId('local-product'),
      code: normalized,
      name: name.trim(),
      category: category.trim(),
      presentation: presentation.trim(),
      unit: unit.trim(),
      minimum: minimum,
      price: money(effectivePrice),
      dosage: dosage?.trim() ?? existing?.dosage ?? '',
      measurementUnit:
          measurementUnit?.trim() ?? existing?.measurementUnit ?? '',
      origin: origin?.trim() ?? existing?.origin ?? '',
      manufacturer: manufacturer?.trim() ?? existing?.manufacturer ?? '',
      description: description?.trim() ?? existing?.description ?? '',
      indications: indications?.trim() ?? existing?.indications ?? '',
      contraindications:
          contraindications?.trim() ?? existing?.contraindications ?? '',
      requiresPrescription:
          requiresPrescription ?? existing?.requiresPrescription ?? false,
      packageUnits: packageUnits ?? existing?.packageUnits ?? 1,
      active: existing?.active ?? true,
      activeIngredient: activeIngredient.trim(),
      barcode: barcode.trim(),
      illustrationKey: imageKey,
    );
    if (existing == null) {
      _products.add(record);
      _branchProducts.add(BranchProduct(workingBranchId, record.id));
    } else {
      _products[_products.indexOf(existing)] = record;
    }
    _commit(
      id == null ? 'Producto registrado' : 'Producto editado',
      record.name,
    );
    return null;
  }

  /// Recibe unidades de un producto EXISTENTE. No crea fichas implícitamente.
  /// Un lote repetido se rechaza: reposiciones/ajustes requieren otro flujo,
  /// todavía pendiente, para no sumar accidentalmente una recepción dos veces.
  String? receiveLot({
    required String productId,
    required String code,
    required int quantity,
    required DateTime expiry,
    double unitCost = 0,
    String supplierId = '',
    DateTime? manufacturedAt,
    String location = '',
    double? salePrice,
  }) {
    final denied = _permissionError();
    if (denied != null) return denied;
    if (workingBranch?.active != true ||
        !productEnabled(workingBranchId, productId)) {
      return 'El producto no está habilitado en tu sucursal.';
    }
    if (productById(productId)?.active != true) {
      return 'Selecciona un producto registrado y activo.';
    }
    if (code.trim().isEmpty ||
        quantity <= 0 ||
        quantity > 1000000 ||
        !unitCost.isFinite ||
        unitCost < 0 ||
        unitCost > 1000000) {
      return 'Indica el lote y una cantidad mayor que cero.';
    }
    final supplier = supplierId.isEmpty ? null : contactById(supplierId);
    if (supplierId.isNotEmpty &&
        (supplier?.kind != ContactKind.supplier || supplier?.active != true)) {
      return 'Selecciona un proveedor activo.';
    }
    if (manufacturedAt != null &&
        (InventoryLot.dayOnly(manufacturedAt).isAfter(today) ||
            !InventoryLot.dayOnly(
              manufacturedAt,
            ).isBefore(InventoryLot.dayOnly(expiry)))) {
      return 'La fabricación debe ser anterior al vencimiento y no futura.';
    }
    if (salePrice != null &&
        (!salePrice.isFinite || money(salePrice) <= 0 || salePrice > 1000000)) {
      return 'Indica un precio unitario válido.';
    }
    if (salePrice != null &&
        (!isAdministrator || _cart.any((l) => l.product.id == productId))) {
      return 'El precio requiere un administrador y el producto fuera del carrito.';
    }
    final expiryDay = InventoryLot.dayOnly(expiry);
    if (expiryDay.isBefore(today)) {
      return 'No se pueden recibir lotes ya vencidos en este flujo.';
    }
    final normalized = code.trim().toUpperCase();
    if (_lots.any(
      (lot) =>
          lot.branchId == workingBranchId &&
          lot.productId == productId &&
          lot.code.toUpperCase() == normalized,
    )) {
      return 'Ese lote ya está registrado para el producto.';
    }
    _lots.add(
      InventoryLot(
        id: _nextId('local-lot'),
        productId: productId,
        branchId: workingBranchId,
        code: normalized,
        quantity: quantity,
        expiry: expiryDay,
        receivedAt: today,
        unitCost: money(unitCost),
        supplierId: supplierId,
        manufacturedAt: manufacturedAt == null
            ? null
            : InventoryLot.dayOnly(manufacturedAt),
        location: location.trim(),
      ),
    );
    if (salePrice != null) {
      final p = productById(productId)!;
      _products[_products.indexOf(p)] = p.withPrice(money(salePrice));
    }
    if (supplierId.isNotEmpty &&
        !_productSuppliers.any(
          (r) => r.productId == productId && r.supplierId == supplierId,
        )) {
      _productSuppliers.add(
        ProductSupplier(
          productId: productId,
          supplierId: supplierId,
          referenceCost: unitCost,
        ),
      );
    }
    _stockMovement(_lots.last, quantity, 'Recepción directa de lote');
    _commit('Lote recibido', '$normalized · $quantity unidades');
    return null;
  }

  /// Impide solicitar más unidades que las disponibles en lotes no vencidos.
  bool addToCart(Product product) {
    if (_permissionError() != null ||
        !productEnabled(workingBranchId, product.id) ||
        productById(product.id)?.active != true ||
        (productById(product.id)?.price ?? 0) <= 0) {
      return false;
    }
    final found = _cart.where((line) => line.product.id == product.id);
    final reserved = found.isEmpty ? 0 : found.first.quantity;
    if (reserved >= availableStock(product)) return false;
    if (found.isEmpty) {
      _cart.add(CartLine(product));
    } else {
      _cart[_cart.indexOf(found.first)] = found.first.withQuantity(
        reserved + 1,
      );
    }
    notifyListeners();
    return true;
  }

  void removeFromCart(CartLine line) {
    if (!_cart.contains(line)) return;
    if (line.quantity <= 1) {
      _cart.remove(line);
    } else {
      _cart[_cart.indexOf(line)] = line.withQuantity(line.quantity - 1);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Descarta una línea pendiente, sin tocar lotes ni comprobantes emitidos.
  void discardCartLine(CartLine line) {
    if (_permissionError() != null) return;
    _cart.removeWhere((entry) => entry.product.id == line.product.id);
    notifyListeners();
  }

  /// Acceso corto para el dominio; la vista usa checkoutSale con datos del cobro.
  bool finishSale() =>
      checkoutSale(method: PaymentMethod.cash, tendered: cartTotal) == null;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
