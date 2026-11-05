part of 'pharmacy_controller.dart';

/// Comandos del prototipo: validan primero, modifican después y registran historial.
/// Están separados de persistencia y presentación, listos para una futura API.
extension AdministrationOperations on PharmacyController {
  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<PurchaseOrder> get purchases => List.unmodifiable(
    _purchases.where((p) => isAdministrator && p.branchId == workingBranchId),
  );
  List<SaleReceipt> get sales => List.unmodifiable(
    _sales.where(
      (s) =>
          isAdministrator ||
          (currentStaff?.active == true &&
              s.branchId == workingBranchId &&
              s.actorId == actorId),
    ),
  );
  List<CashSession> get cashSessions =>
      isAdministrator ? List.unmodifiable(_cashSessions) : const [];
  List<CashMovement> get cashMovements =>
      isAdministrator ? List.unmodifiable(_cashMovements) : const [];
  List<SupportCase> get incidents => List.unmodifiable(_incidents);
  List<AuditEntry> get audit => List.unmodifiable(
    _audit.where((a) => isAdministrator || a.actorId == actorId),
  );
  List<InventoryMovement> get movements => List.unmodifiable(
    _movements.where((m) => lots.any((l) => l.id == m.lotId)),
  );
  double get cartTotal =>
      money(_cart.fold<double>(0, (n, l) => n + l.subtotal));
  double get inventoryValue =>
      money(lots.fold<double>(0, (n, l) => n + l.quantity * l.unitCost));
  double get revenueToday => money(
    sales
        .where(
          (s) =>
              !s.cancelled &&
              s.branchId == workingBranchId &&
              InventoryLot.dayOnly(s.createdAt) == today,
        )
        .fold<double>(0, (n, s) => n + s.total),
  );
  int get alertsCount => lowStockCount + expiringCount + expiredCount;
  CashSession? get openCash {
    for (final session in _cashSessions.reversed) {
      if (session.isOpen) return session;
    }
    return null;
  }

  double expectedCash(CashSession session) => money(
    session.openingBalance +
        _cashMovements
            .where((m) => m.sessionId == session.id)
            .fold<double>(0, (n, m) => n + m.amount),
  );
  Contact? contactById(String id) {
    for (final contact in _contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  String? saveContact({
    String? id,
    required ContactKind kind,
    required String name,
    String phone = '',
    String email = '',
    String address = '',
    String? identification,
    String? representative,
    String? code,
    String? supplierType,
    String? origin,
    String? description,
  }) {
    final denied = _permissionError(
      administrator: kind == ContactKind.supplier,
    );
    if (denied != null) return denied;
    if (name.trim().isEmpty) return 'El nombre es obligatorio.';
    if (email.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      return 'Revisa el correo electrónico.';
    }
    final old = id == null ? null : contactById(id);
    if (id != null && (old == null || old.kind != kind)) {
      return 'Contacto no encontrado.';
    }
    final supplierCode = (code ?? old?.code ?? '').trim().toUpperCase();
    if (kind == ContactKind.supplier &&
        supplierCode.isNotEmpty &&
        _contacts.any(
          (c) =>
              c.id != id &&
              c.kind == kind &&
              c.code.toUpperCase() == supplierCode,
        )) {
      return 'Ese código de proveedor ya existe.';
    }
    var resolvedCode = supplierCode;
    if (kind == ContactKind.supplier && resolvedCode.isEmpty) {
      var number = 1;
      do {
        resolvedCode = 'PRV-${number.toString().padLeft(6, '0')}';
        number++;
      } while (_contacts.any(
        (c) =>
            c.kind == ContactKind.supplier &&
            c.code.toUpperCase() == resolvedCode,
      ));
    }
    final record = Contact(
      id: id ?? _nextId('CNT'),
      kind: kind,
      name: name.trim(),
      code: kind == ContactKind.supplier ? resolvedCode : '',
      supplierType: supplierType?.trim() ?? old?.supplierType ?? '',
      origin: origin?.trim() ?? old?.origin ?? '',
      description: description?.trim() ?? old?.description ?? '',
      phone: phone.trim(),
      email: email.trim(),
      address: address.trim(),
      identification: identification?.trim() ?? old?.identification ?? '',
      representative: representative?.trim() ?? old?.representative ?? '',
      photoAsset: old?.photoAsset ?? '',
      active: old?.active ?? true,
    );
    if (old == null) {
      _contacts.add(record);
    } else {
      _contacts[_contacts.indexOf(old)] = record;
    }
    _commit(
      old == null ? 'Contacto registrado' : 'Contacto editado',
      record.name,
    );
    return null;
  }

  String? toggleContact(String id) {
    final old = contactById(id);
    if (old == null) return 'Contacto no encontrado.';
    final denied = _permissionError(
      administrator: old.kind == ContactKind.supplier,
    );
    if (denied != null) return denied;
    _contacts[_contacts.indexOf(old)] = old.copyWith(active: !old.active);
    _commit(
      old.active ? 'Contacto archivado' : 'Contacto reactivado',
      old.name,
    );
    return null;
  }

  String? toggleProduct(String id) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final old = productById(id);
    if (old == null) return 'Producto no encontrado.';
    if (_cart.any((line) => line.product.id == id)) {
      return 'Quita primero el producto de la venta pendiente.';
    }
    _products[_products.indexOf(old)] = old.withActive(!old.active);
    _commit(
      old.active ? 'Producto archivado' : 'Producto reactivado',
      old.name,
    );
    return null;
  }

  String? adjustLot(String id, int delta, String reason) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final index = _lots.indexWhere((l) => l.id == id);
    if (index < 0) return 'Lote no encontrado.';
    if (_lots[index].branchId != workingBranchId) {
      return 'El lote no pertenece a la sucursal seleccionada.';
    }
    if (delta == 0 || reason.trim().isEmpty) {
      return 'Indica un ajuste distinto de cero y su motivo.';
    }
    final next = _lots[index].quantity + delta;
    if (next < 0 || next > 1000000) {
      return 'El saldo debe estar entre cero y un millón de unidades.';
    }
    _lots[index] = _lots[index].withQuantity(next);
    _stockMovement(_lots[index], delta, reason.trim());
    _commit(
      'Inventario ajustado',
      '${_lots[index].code} · $delta · ${reason.trim()}',
    );
    return null;
  }

  String? openCashSession(double amount) {
    final denied = _permissionError();
    if (denied != null) return denied;
    if (!cashEnabled) return 'Caja está desactivada temporalmente.';
    if (openCash != null) return 'Ya existe una caja abierta.';
    if (!amount.isFinite || amount < 0 || amount > 1000000000) {
      return 'Indica un fondo inicial válido.';
    }
    _cashSessions.add(
      CashSession(
        id: _nextId('CJ'),
        openedAt: now,
        openingBalance: money(amount),
        actorId: actorId,
        actorName: actorName,
      ),
    );
    _commit('Caja abierta', 'Fondo inicial: ${money(amount)}');
    return null;
  }

  String? closeCashSession(double counted) {
    final denied = _permissionError();
    if (denied != null) return denied;
    if (!cashEnabled) return 'Caja está desactivada temporalmente.';
    final session = openCash;
    if (session == null) return 'No hay caja abierta.';
    if (!isAdministrator && session.actorId != actorId) {
      return 'Solo el responsable de la caja o un administrador puede cerrarla.';
    }
    if (_cart.isNotEmpty) {
      return 'Finaliza o vacía la venta pendiente antes de cerrar caja.';
    }
    if (!counted.isFinite || counted < 0 || counted > 1000000000) {
      return 'Indica el efectivo contado.';
    }
    _cashSessions[_cashSessions.indexOf(session)] = session.close(
      now,
      money(counted),
    );
    _commit(
      'Caja cerrada',
      'Contado: ${money(counted)} · Diferencia: ${money(counted - expectedCash(session))}',
    );
    return null;
  }

  String? cashAdjustment(double amount, String concept) {
    final denied = _permissionError();
    if (denied != null) return denied;
    if (!cashEnabled) return 'Caja está desactivada temporalmente.';
    if (openCash == null) return 'Abre caja antes de registrar movimientos.';
    if (!amount.isFinite ||
        amount.abs() > 1000000000 ||
        money(amount) == 0 ||
        concept.trim().isEmpty) {
      return 'Indica un importe distinto de cero y un concepto.';
    }
    if (expectedCash(openCash!) + money(amount) < 0) {
      return 'La salida supera el efectivo disponible.';
    }
    _addCash(money(amount), concept.trim());
    _commit('Movimiento de caja', '${concept.trim()} · ${money(amount)}');
    return null;
  }

  void _addCash(double amount, String concept, [String reference = '']) =>
      _cashMovements.add(
        CashMovement(
          id: _nextId('CM'),
          sessionId: openCash!.id,
          createdAt: now,
          amount: money(amount),
          concept: concept,
          reference: reference,
        ),
      );

  /// Comando atómico en memoria: prepara el descuento FEFO antes de aplicarlo.
  String? checkoutSale({
    required PaymentMethod method,
    required double tendered,
    String customerId = '',
  }) {
    final denied = _permissionError();
    if (denied != null) return denied;
    if (_cart.isEmpty) return 'El carrito está vacío.';
    final assignmentError = billingAssignmentError;
    if (assignmentError != null) return assignmentError;
    // Sin Caja se mantienen todas las validaciones de stock, importe y cliente,
    // pero no se exige ni se abre un turno oculto.
    if (cashEnabled && openCash == null) {
      return 'Abre caja antes de cobrar una venta.';
    }
    final customer = customerId.isEmpty ? null : contactById(customerId);
    if (customerId.isNotEmpty &&
        (customer == null ||
            !customer.active ||
            customer.kind != ContactKind.customer)) {
      return 'Selecciona un cliente activo.';
    }
    if (!tendered.isFinite || tendered < 0 || tendered > 1000000000) {
      return 'Importe recibido inválido.';
    }
    if (method == PaymentMethod.cash && money(tendered) < cartTotal) {
      return 'El efectivo recibido no cubre el total.';
    }
    if (cartTotal > 1000000000) {
      return 'El importe excede el límite del prototipo.';
    }
    if (_cart.any(
      (line) =>
          productById(line.product.id)?.active != true ||
          line.product.price <= 0 ||
          !productEnabled(workingBranchId, line.product.id) ||
          line.quantity <= 0 ||
          line.quantity > availableStock(line.product),
    )) {
      return 'Hay productos inactivos o cantidades sin existencias vigentes.';
    }
    final nextLots = List<InventoryLot>.of(_lots);
    final lines = <SaleLine>[];
    for (final line in _cart) {
      var pending = line.quantity;
      final candidates =
          nextLots
              .where(
                (lot) =>
                    lot.branchId == workingBranchId &&
                    lot.productId == line.product.id &&
                    lot.quantity > 0 &&
                    !lot.isExpired(today),
              )
              .toList()
            ..sort((a, b) {
              final expiry = a.expiry.compareTo(b.expiry);
              return expiry != 0
                  ? expiry
                  : a.receivedAt.compareTo(b.receivedAt);
            });
      final allocations = <LotAllocation>[];
      for (final lot in candidates) {
        if (pending == 0) break;
        final amount = pending < lot.quantity ? pending : lot.quantity;
        nextLots[nextLots.indexWhere((l) => l.id == lot.id)] = lot.withQuantity(
          lot.quantity - amount,
        );
        allocations.add(LotAllocation(lotId: lot.id, quantity: amount));
        pending -= amount;
      }
      if (pending != 0) {
        return 'El stock de la sucursal cambió. Revisa la venta.';
      }
      lines.add(
        SaleLine(
          productId: line.product.id,
          name: line.product.name,
          unit: line.product.unit,
          quantity: line.quantity,
          unitPrice: line.product.price,
          allocations: List.unmodifiable(allocations),
        ),
      );
    }
    final receipt = SaleReceipt(
      id: _nextId('FV'),
      createdAt: now,
      customerId: customerId,
      customerName: customer?.name ?? 'Consumidor final',
      actorName: actorName,
      actorId: actorId,
      branchId: workingBranchId,
      branchName: workingBranch!.name,
      registerId: currentRegister!.id,
      registerName: currentRegister!.name,
      lines: List.unmodifiable(lines),
      method: method,
      cashReceived: method == PaymentMethod.cash ? money(tendered) : cartTotal,
    );
    _lots
      ..clear()
      ..addAll(nextLots);
    for (final line in lines) {
      for (final allocation in line.allocations) {
        _stockMovement(
          _lots.firstWhere((l) => l.id == allocation.lotId),
          -allocation.quantity,
          'Venta ${receipt.id}',
        );
      }
    }
    _sales.add(receipt);
    if (cashEnabled && method == PaymentMethod.cash) {
      _addCash(receipt.total, 'Venta en efectivo', receipt.id);
    }
    _cart.clear();
    _commit(
      'Venta registrada',
      '${receipt.id} · ${receipt.total} · ${method.label} · ${receipt.branchName}/${receipt.registerName} · ${receipt.actorName}',
    );
    return null;
  }

  /// Identifica cobros anteriores registrados en Caja sin cambiar el respaldo
  /// existente. Una venta nueva sin Caja no debe inventar un reembolso de caja
  /// cuando el módulo se reactive.
  bool hasRecordedCashPayment(SaleReceipt sale) =>
      sale.method == PaymentMethod.cash &&
      _cashMovements.any((m) => m.reference == sale.id && m.amount > 0);

  String? cancelSale(String id, String reason) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final index = _sales.indexWhere((s) => s.id == id);
    if (index < 0) return 'Venta no encontrada.';
    final sale = _sales[index];
    if (sale.cancelled) return 'La venta ya está anulada.';
    if (reason.trim().isEmpty) return 'Indica el motivo de anulación.';
    final refundThroughCash = hasRecordedCashPayment(sale);
    if (refundThroughCash && !cashEnabled) {
      return 'Esta venta tiene un cobro en el historial de Caja. Reactiva Caja para registrar su devolución sin alterar ese historial.';
    }
    if (refundThroughCash &&
        (openCash == null || expectedCash(openCash!) < sale.total)) {
      return 'Se necesita una caja abierta con efectivo suficiente para registrar la devolución.';
    }
    // Validar todos los saldos antes de devolver una sola unidad.
    for (final line in sale.lines) {
      for (final allocation in line.allocations) {
        final lot = _lots.firstWhere((l) => l.id == allocation.lotId);
        if (lot.quantity + allocation.quantity > 1000000) {
          return 'La devolución excede el límite del lote. Revisa los ajustes previos.';
        }
      }
    }
    for (final line in sale.lines) {
      for (final allocation in line.allocations) {
        final lotIndex = _lots.indexWhere((l) => l.id == allocation.lotId);
        _lots[lotIndex] = _lots[lotIndex].withQuantity(
          _lots[lotIndex].quantity + allocation.quantity,
        );
        _stockMovement(
          _lots[lotIndex],
          allocation.quantity,
          'Anulación $id: ${reason.trim()}',
        );
      }
    }
    _sales[index] = sale.cancel(now, reason.trim());
    if (refundThroughCash) {
      _addCash(-sale.total, 'Devolución por anulación', id);
    }
    _commit('Venta anulada', '$id · ${reason.trim()}');
    return null;
  }

  String? createPurchase(String supplierId, List<PurchaseLine> lines) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    if (workingBranch?.active != true) return 'Selecciona una sucursal activa.';
    final supplier = contactById(supplierId);
    if (supplier == null ||
        !supplier.active ||
        supplier.kind != ContactKind.supplier) {
      return 'Selecciona un proveedor activo.';
    }
    if (lines.any(
      (l) => supplierTerms(l.productId, supplierId)?.active == false,
    )) {
      return 'Hay un vínculo producto–proveedor suspendido. Reactívalo desde el catálogo comercial.';
    }
    if (lines.isEmpty ||
        lines.any(
          (l) =>
              productById(l.productId)?.active != true ||
              !productEnabled(workingBranchId, l.productId) ||
              l.quantity <= 0 ||
              l.quantity > 1000000 ||
              !l.unitCost.isFinite ||
              l.unitCost > 1000000 ||
              l.unitCost < 0 ||
              money(l.unitCost) <= 0,
        ) ||
        lines.map((l) => l.productId).toSet().length != lines.length) {
      return 'Revisa productos, cantidades y costos. No repitas productos en la orden.';
    }
    final normalized = lines
        .map(
          (l) => PurchaseLine(
            productId: l.productId,
            productName: productById(l.productId)!.name,
            quantity: l.quantity,
            unitCost: l.unitCost,
            dosage: productById(l.productId)!.dosage,
            presentation: productById(l.productId)!.presentation,
            unit: productById(l.productId)!.unit,
            packageUnits: productById(l.productId)!.packageUnits,
          ),
        )
        .toList();
    if (normalized.fold<double>(0, (n, l) => n + l.total) > 1000000000) {
      return 'Importe fuera del límite local.';
    }
    final order = PurchaseOrder(
      id: _nextId('OC'),
      supplierId: supplierId,
      branchId: workingBranchId,
      supplierName: supplier.name,
      createdAt: now,
      lines: List.unmodifiable(normalized),
    );
    _purchases.add(order);
    // Una compra confirmada incorpora la relación comercial que faltase.
    for (final line in normalized) {
      if (!_productSuppliers.any(
        (r) => r.productId == line.productId && r.supplierId == supplierId,
      )) {
        _productSuppliers.add(
          ProductSupplier(
            productId: line.productId,
            supplierId: supplierId,
            referenceCost: line.unitCost,
          ),
        );
      }
    }
    _commit('Orden de compra creada', order.id);
    return null;
  }

  String? cancelPurchase(String id, String reason) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final index = _purchases.indexWhere((p) => p.id == id);
    if (index < 0 || _purchases[index].status != PurchaseStatus.pending) {
      return 'Solo se cancela una orden pendiente.';
    }
    if (_purchases[index].branchId != workingBranchId) {
      return 'Selecciona la sucursal de la compra.';
    }
    if (reason.trim().isEmpty) return 'Indica el motivo.';
    _purchases[index] = _purchases[index].cancelled(reason.trim());
    _commit('Compra cancelada', '$id · ${reason.trim()}');
    return null;
  }

  String? receivePurchase(String id, List<LotReceipt> receipts) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final index = _purchases.indexWhere((p) => p.id == id);
    if (index < 0 || _purchases[index].status != PurchaseStatus.pending) {
      return 'La compra no está pendiente de recepción.';
    }
    final order = _purchases[index];
    if (order.branchId != workingBranchId || workingBranch?.active != true) {
      return 'Selecciona la sucursal activa de la compra.';
    }
    if (receipts.length != order.lines.length ||
        receipts.map((r) => r.productId).toSet().length != receipts.length) {
      return 'Completa el lote y vencimiento de cada línea.';
    }
    final prepared = <InventoryLot>[];
    for (final line in order.lines) {
      final matches = receipts.where((r) => r.productId == line.productId);
      if (matches.isEmpty) return 'Falta el lote de ${line.productName}.';
      final received = matches.single;
      final code = received.code.trim().toUpperCase();
      if (code.isEmpty ||
          InventoryLot.dayOnly(received.expiry).isBefore(today)) {
        return 'Hay un lote sin código o vencido.';
      }
      if (received.manufacturedAt != null &&
          (InventoryLot.dayOnly(received.manufacturedAt!).isAfter(today) ||
              !InventoryLot.dayOnly(
                received.manufacturedAt!,
              ).isBefore(InventoryLot.dayOnly(received.expiry)))) {
        return 'Revisa la fecha de fabricación de ${line.productName}.';
      }
      if (received.salePrice != null &&
          (!received.salePrice!.isFinite ||
              money(received.salePrice!) <= 0 ||
              received.salePrice! > 1000000 ||
              _cart.any((l) => l.product.id == line.productId))) {
        return 'Revisa el precio de venta y retira el producto del carrito.';
      }
      final old = _lots.where(
        (l) =>
            l.branchId == order.branchId &&
            l.productId == line.productId &&
            l.code.toUpperCase() == code,
      );
      if (old.isNotEmpty &&
          InventoryLot.dayOnly(old.single.expiry) !=
              InventoryLot.dayOnly(received.expiry)) {
        return 'El lote $code ya existe con otro vencimiento.';
      }
      if (old.isNotEmpty &&
          ((old.single.supplierId.isNotEmpty &&
                  old.single.supplierId != order.supplierId) ||
              (old.single.manufacturedAt != null &&
                  received.manufacturedAt != null &&
                  InventoryLot.dayOnly(old.single.manufacturedAt!) !=
                      InventoryLot.dayOnly(received.manufacturedAt!)) ||
              (old.single.location.isNotEmpty &&
                  received.location.trim().isNotEmpty &&
                  old.single.location != received.location.trim()))) {
        return 'El lote $code tiene otro proveedor, fabricación o ubicación. Conserva su trazabilidad.';
      }
      if (old.isNotEmpty &&
          received.manufacturedAt != null &&
          InventoryLot.dayOnly(
            received.manufacturedAt!,
          ).isAfter(InventoryLot.dayOnly(old.single.receivedAt))) {
        return 'La fabricación no puede ser posterior a la primera recepción del lote $code.';
      }
      final quantity = (old.isEmpty ? 0 : old.single.quantity) + line.quantity;
      if (quantity > 1000000) return 'Cantidad fuera del límite local.';
      prepared.add(
        InventoryLot(
          id: old.isEmpty ? '' : old.single.id,
          productId: line.productId,
          branchId: order.branchId,
          code: code,
          supplierId: order.supplierId,
          manufacturedAt:
              old.firstOrNull?.manufacturedAt ?? received.manufacturedAt,
          location: received.location.trim().isEmpty
              ? (old.firstOrNull?.location ?? '')
              : received.location.trim(),
          quantity: quantity,
          expiry: InventoryLot.dayOnly(received.expiry),
          receivedAt: old.isEmpty ? today : old.single.receivedAt,
          unitCost: old.isEmpty
              ? line.unitCost
              : (old.single.quantity * old.single.unitCost + line.total) /
                    quantity,
        ),
      );
    }
    // Solo tras validar toda la recepción se asignan IDs y se suman los saldos.
    for (var i = 0; i < prepared.length; i++) {
      final lot = prepared[i];
      final record = InventoryLot(
        id: lot.id.isEmpty ? _nextId('local-lot') : lot.id,
        productId: lot.productId,
        branchId: lot.branchId,
        code: lot.code,
        quantity: lot.quantity,
        expiry: lot.expiry,
        receivedAt: lot.receivedAt,
        unitCost: lot.unitCost,
        supplierId: lot.supplierId,
        manufacturedAt: lot.manufacturedAt,
        location: lot.location,
      );
      final oldIndex = _lots.indexWhere((l) => l.id == record.id);
      if (oldIndex < 0) {
        _lots.add(record);
      } else {
        _lots[oldIndex] = record;
      }
      _stockMovement(record, order.lines[i].quantity, 'Recepción $id');
    }
    for (final r in receipts) {
      if (r.salePrice != null) {
        final p = productById(r.productId)!;
        _products[_products.indexOf(p)] = p.withPrice(money(r.salePrice!));
      }
    }
    _purchases[index] = order.received(now);
    _commit('Compra recibida', '$id · lotes incorporados');
    return null;
  }

  String? payPurchase(String id, PaymentMethod method) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final index = _purchases.indexWhere((p) => p.id == id);
    if (index < 0 ||
        _purchases[index].status != PurchaseStatus.received ||
        _purchases[index].paidAt != null) {
      return 'Solo se paga una compra recibida y pendiente de pago.';
    }
    final order = _purchases[index];
    if (order.branchId != workingBranchId) {
      return 'Selecciona la sucursal de la compra.';
    }
    if (cashEnabled &&
        method == PaymentMethod.cash &&
        (openCash == null || expectedCash(openCash!) < order.total)) {
      return 'Abre caja con suficiente efectivo o registra otro método de pago.';
    }
    _purchases[index] = order.paid(now, method.label);
    // Con Caja suspendida el pago es un registro manual, no una salida de caja.
    if (cashEnabled && method == PaymentMethod.cash) {
      _addCash(-order.total, 'Pago a proveedor', id);
    }
    _commit('Compra pagada', '$id · ${method.label}');
    return null;
  }

  String? saveIncident({
    String? id,
    required String title,
    required String description,
    required String priority,
    IncidentStatus status = IncidentStatus.open,
    String resolution = '',
  }) {
    final denied = _permissionError();
    if (denied != null) return denied;
    if (title.trim().isEmpty ||
        description.trim().isEmpty ||
        !['Baja', 'Media', 'Alta'].contains(priority)) {
      return 'Completa el incidente y su prioridad.';
    }
    if (status == IncidentStatus.resolved && resolution.trim().isEmpty) {
      return 'Describe la solución para cerrar el incidente.';
    }
    final index = id == null ? -1 : _incidents.indexWhere((i) => i.id == id);
    if (id != null && index < 0) return 'Incidente no encontrado.';
    final old = index < 0
        ? SupportCase(
            id: _nextId('INC'),
            title: title.trim(),
            description: description.trim(),
            priority: priority,
            createdAt: now,
          )
        : _incidents[index];
    final record = old.update(
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      status: status,
      resolution: resolution.trim(),
      now: now,
    );
    if (index < 0) {
      _incidents.add(record);
    } else {
      _incidents[index] = record;
    }
    _commit(
      index < 0 ? 'Incidente registrado' : 'Incidente actualizado',
      '${record.id} · ${record.status.name}',
    );
    return null;
  }

  void recordSessionChange(SessionUser? user) {
    if (!isLoaded || loadFailed) {
      _sessionUser = user;
      return;
    }
    final previous = _sessionUser;
    _sessionUser = user;
    if (previous?.id != user?.id) {
      _cart.clear();
      _selectedBranchId = staffById(user?.id ?? '')?.branchId ?? mainBranchId;
    }
    if (user != null && previous?.id != user.id) {
      _commit('Acceso al sistema', 'Sesión local');
    } else if (user != null &&
        (previous?.name != user.name ||
            previous?.phone != user.phone ||
            previous?.contactEmail != user.contactEmail ||
            previous?.avatarPhoto != user.avatarPhoto ||
            previous?.avatarSymbol != user.avatarSymbol ||
            previous?.avatarTone != user.avatarTone)) {
      _commit('Perfil actualizado', 'Datos personales del perfil local');
    }
  }
}
