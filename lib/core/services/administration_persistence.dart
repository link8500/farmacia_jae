part of 'pharmacy_controller.dart';

/// Persistencia local y respaldo versionado. Un documento se valida completo
/// antes de reemplazar el estado; las escrituras se serializan y nunca se ocultan errores.
extension AdministrationPersistence on PharmacyController {
  Future<void> initialize() => _initialization ??= _loadData();
  Future<void> _loadData() async {
    if (store == null) return;
    try {
      final raw = await store!.read();
      if (_disposed) return;
      if (raw != null) _applySnapshot(_AdministrationSnapshot.decode(raw));
      isLoaded = true;
      loadFailed = false;
      storageError = null;
      var addedDemo = false;
      if (seedDemoHistory && !hasDemoHistory) {
        try {
          addedDemo = _installDemoHistory();
        } on FormatException catch (error) {
          demoDataError = 'No se pudo añadir el historial: ${error.message}';
        }
      }
      _sessionUser = null;
      recordSessionChange(userProvider?.call());
      if (raw == null || addedDemo) _queueSave();
    } catch (_) {
      if (_disposed) return;
      isLoaded = true;
      loadFailed = true;
      storageError =
          'No se pudieron cargar los datos locales. No se sobrescribirán. Reintenta la carga o restaura un respaldo válido.';
    }
    if (!_disposed) _notify();
  }

  Future<void> retryLoading() {
    if (!loadFailed) return Future.value();
    _initialization = null;
    isLoaded = false;
    _notify();
    return initialize();
  }

  void retrySaving() {
    if (!loadFailed) _queueSave();
  }

  Future<void> flush() => _writes;
  Map<String, Object?> _snapshotJson() => {
    'version': 2,
    'sequence': _sequence,
    'demoScenarioVersion': _demoScenarioVersion,
    'lastBackupAt': lastBackupAt?.toIso8601String(),
    'branches': _branches.map((b) => b.toJson()).toList(),
    'registers': _registers.map((r) => r.toJson()).toList(),
    'staff': _staff.map((s) => s.toJson()).toList(),
    'branchProducts': _branchProducts.map((p) => p.toJson()).toList(),
    'productSuppliers': _productSuppliers.map((p) => p.toJson()).toList(),
    'products': _products.map((p) => p.toJson()).toList(),
    'lots': _lots.map((l) => l.toJson()).toList(),
    'contacts': _contacts.map((c) => c.toJson()).toList(),
    'purchases': _purchases.map((p) => p.toJson()).toList(),
    'sales': _sales.map((s) => s.toJson()).toList(),
    'cashSessions': _cashSessions.map((s) => s.toJson()).toList(),
    'cashMovements': _cashMovements.map((m) => m.toJson()).toList(),
    'incidents': _incidents.map((i) => i.toJson()).toList(),
    'audit': _audit.map((a) => a.toJson()).toList(),
    'movements': _movements.map((m) => m.toJson()).toList(),
  };
  void _queueSave() {
    if (store == null || _disposed || !isLoaded || loadFailed) return;
    final raw = jsonEncode(_snapshotJson());
    final revision = _revision;
    _pendingWrites++;
    _writes = _writes.then((_) async {
      try {
        await store!.write(raw);
        if (!_disposed && revision == _revision) {
          storageError = null;
          lastSavedAt = now;
        }
      } catch (_) {
        if (!_disposed && revision == _revision) {
          storageError =
              'Los cambios están en esta sesión, pero no se guardaron. Exporta un respaldo antes de cerrar o recargar.';
        }
      } finally {
        _pendingWrites--;
        if (!_disposed) _notify();
      }
    });
  }

  String createBackup() {
    if (!isAdministrator ||
        (userProvider != null && userProvider?.call() == null)) {
      throw StateError(
        'El respaldo completo requiere un administrador con sesión.',
      );
    }
    if (!loadFailed) {
      lastBackupAt = now;
      _commit('Respaldo exportado', 'JSON local generado');
    }
    return const JsonEncoder.withIndent('  ').convert(_snapshotJson());
  }

  String? restoreBackup(String raw) {
    if (!isAdministrator ||
        (userProvider != null && userProvider?.call() == null)) {
      return 'La restauración requiere un administrador con sesión.';
    }
    try {
      final snapshot = _AdministrationSnapshot.decode(raw);
      _applySnapshot(snapshot);
      _cart.clear();
      loadFailed = false;
      isLoaded = true;
      storageError = null;
      _commit(
        'Respaldo restaurado',
        'Datos validados y reemplazados por confirmación del usuario',
      );
      return null;
    } on FormatException catch (error) {
      return 'Respaldo rechazado: ${error.message}';
    }
  }

  void _applySnapshot(_AdministrationSnapshot data) {
    _branches
      ..clear()
      ..addAll(data.branches);
    _registers
      ..clear()
      ..addAll(data.registers);
    _staff
      ..clear()
      ..addAll(data.staff);
    _branchProducts
      ..clear()
      ..addAll(data.branchProducts);
    if (branchById(_selectedBranchId)?.active != true) {
      _selectedBranchId = _branches.where((b) => b.active).first.id;
    }
    _productSuppliers
      ..clear()
      ..addAll(data.productSuppliers);
    _products
      ..clear()
      ..addAll(data.products);
    _lots
      ..clear()
      ..addAll(data.lots);
    _contacts
      ..clear()
      ..addAll(data.contacts);
    _purchases
      ..clear()
      ..addAll(data.purchases);
    _sales
      ..clear()
      ..addAll(data.sales);
    _cashSessions
      ..clear()
      ..addAll(data.cashSessions);
    _cashMovements
      ..clear()
      ..addAll(data.cashMovements);
    _incidents
      ..clear()
      ..addAll(data.incidents);
    _audit
      ..clear()
      ..addAll(data.audit);
    _movements
      ..clear()
      ..addAll(data.movements);
    _sequence = data.sequence;
    _demoScenarioVersion = data.demoScenarioVersion;
    lastBackupAt = data.lastBackupAt;
    _enrichDemoPeople();
  }
}

class _AdministrationSnapshot {
  _AdministrationSnapshot(JsonMap json)
    : sequence = jsonInteger(json, 'sequence'),
      demoScenarioVersion = jsonInteger(
        json,
        'demoScenarioVersion',
        fallback: 0,
      ),
      branches = json['version'] == 1
          ? List.of(OrganizationDefaults.branches)
          : jsonList(json, 'branches', PharmacyBranch.fromJson),
      registers = json['version'] == 1
          ? List.of(OrganizationDefaults.registers)
          : jsonList(json, 'registers', BillingRegister.fromJson),
      staff = json['version'] == 1
          ? List.of(OrganizationDefaults.staff)
          : jsonList(json, 'staff', StaffMember.fromJson),
      branchProducts = json['version'] == 1
          ? [
              for (final p in jsonList(json, 'products', Product.fromJson))
                BranchProduct(mainBranchId, p.id),
            ]
          : jsonList(json, 'branchProducts', BranchProduct.fromJson),
      products = jsonList(json, 'products', Product.fromJson),
      lots = jsonList(json, 'lots', InventoryLot.fromJson),
      contacts = jsonList(json, 'contacts', Contact.fromJson),
      purchases = jsonList(json, 'purchases', PurchaseOrder.fromJson),
      productSuppliers = json.containsKey('productSuppliers')
          ? jsonList(json, 'productSuppliers', ProductSupplier.fromJson)
          : _legacySupplierLinks(json),
      sales = jsonList(json, 'sales', SaleReceipt.fromJson),
      cashSessions = jsonList(json, 'cashSessions', CashSession.fromJson),
      cashMovements = jsonList(json, 'cashMovements', CashMovement.fromJson),
      incidents = jsonList(json, 'incidents', SupportCase.fromJson),
      audit = jsonList(json, 'audit', AuditEntry.fromJson),
      movements = jsonList(json, 'movements', InventoryMovement.fromJson),
      lastBackupAt = json['lastBackupAt'] == null
          ? null
          : jsonDate(json, 'lastBackupAt');
  final int sequence;
  final int demoScenarioVersion;
  final List<PharmacyBranch> branches;
  final List<BillingRegister> registers;
  final List<StaffMember> staff;
  final List<BranchProduct> branchProducts;
  final List<Product> products;
  final List<ProductSupplier> productSuppliers;

  /// Respaldos antiguos no tenían tabla N:M. Se reconstruye únicamente desde
  /// compras documentadas, sin asignar proveedores supuestos a otros artículos.
  static List<ProductSupplier> _legacySupplierLinks(JsonMap json) {
    final result = <String, ProductSupplier>{};
    for (final p in jsonList(json, 'purchases', PurchaseOrder.fromJson)) {
      for (final l in p.lines) {
        result['${l.productId}|${p.supplierId}'] = ProductSupplier(
          productId: l.productId,
          supplierId: p.supplierId,
          referenceCost: l.unitCost,
        );
      }
    }
    return result.values.toList();
  }

  final List<InventoryLot> lots;
  final List<Contact> contacts;
  final List<PurchaseOrder> purchases;
  final List<SaleReceipt> sales;
  final List<CashSession> cashSessions;
  final List<CashMovement> cashMovements;
  final List<SupportCase> incidents;
  final List<AuditEntry> audit;
  final List<InventoryMovement> movements;
  final DateTime? lastBackupAt;

  static _AdministrationSnapshot decode(String raw) {
    if (raw.length > 5 * 1024 * 1024) {
      throw const FormatException('El respaldo supera 5 MB.');
    }
    final json = cleanLegacyInterfaceDocument(jsonObject(jsonDecode(raw)));
    if (json['version'] != 1 && json['version'] != 2) {
      throw const FormatException('Versión no compatible.');
    }
    // Completar campos añadidos solo cuando no existían en fichas de ejemplo
    // reconocidas. Un valor vacío guardado explícitamente no se sobrescribe.
    for (final rawProduct
        in (json['products'] is List ? json['products'] as List : const [])) {
      final raw = jsonObject(rawProduct);
      final fixture = PharmacyDemoData.products
          .where((p) => p.id == raw['id'] && p.code == raw['code'])
          .firstOrNull;
      if (fixture != null) {
        final source = fixture.toJson();
        for (final key in [
          'dosage',
          'measurementUnit',
          'origin',
          'manufacturer',
          'description',
          'indications',
          'contraindications',
          'requiresPrescription',
        ]) {
          raw.putIfAbsent(key, () => source[key]);
        }
      }
    }
    final result = _AdministrationSnapshot(json);
    result.validate();
    return result;
  }

  void validate() {
    void require(bool valid, String message) {
      if (!valid) throw FormatException(message);
    }

    void unique(Iterable<String> values) {
      final list = values.toList();
      require(
        list.every((v) => v.isNotEmpty) && list.toSet().length == list.length,
        'Hay identificadores vacíos o duplicados.',
      );
    }

    final groups = [
      branches.map((b) => b.id),
      registers.map((r) => r.id),
      staff.map((s) => s.id),
      products.map((p) => p.id),
      lots.map((l) => l.id),
      contacts.map((c) => c.id),
      purchases.map((p) => p.id),
      sales.map((s) => s.id),
      cashSessions.map((s) => s.id),
      cashMovements.map((m) => m.id),
      incidents.map((i) => i.id),
      audit.map((a) => a.id),
      movements.map((m) => m.id),
    ];
    for (final group in groups) {
      unique(group);
    }
    unique(products.map((p) => p.code.toUpperCase()));
    unique(branches.map((b) => b.name.trim().toLowerCase()));
    unique(staff.map((s) => s.username));
    unique(
      registers.map((r) => '${r.branchId}|${r.name.trim().toLowerCase()}'),
    );
    unique(branchProducts.map((p) => '${p.branchId}|${p.productId}'));
    unique(productSuppliers.map((r) => '${r.productId}|${r.supplierId}'));
    unique(
      contacts
          .where((c) => c.kind == ContactKind.supplier && c.code.isNotEmpty)
          .map((c) => c.code.toUpperCase()),
    );
    unique(
      staff
          .where((s) => s.active && s.registerId.isNotEmpty)
          .map((s) => s.registerId),
    );
    unique(products.where((p) => p.barcode.isNotEmpty).map((p) => p.barcode));
    unique(
      lots.map((l) => '${l.branchId}|${l.productId}|${l.code.toUpperCase()}'),
    );
    final productMap = {for (final p in products) p.id: p};
    final lotMap = {for (final l in lots) l.id: l};
    final contactMap = {for (final c in contacts) c.id: c};
    final sessionIds = cashSessions.map((s) => s.id).toSet();
    final branchMap = {for (final b in branches) b.id: b};
    final registerMap = {for (final r in registers) r.id: r};
    final staffMap = {for (final s in staff) s.id: s};
    require(branches.any((b) => b.active), 'Debe existir una sucursal activa.');
    require(
      staffMap['demo-admin']?.role == UserRole.administrator &&
          staffMap['demo-admin']?.active == true &&
          staffMap['demo-admin']?.username == 'admin',
      'Falta la cuenta administradora local.',
    );
    for (final b in branches) {
      require(b.name.trim().isNotEmpty, 'Sucursal sin nombre.');
    }
    for (final r in registers) {
      require(
        branchMap.containsKey(r.branchId) && r.name.trim().isNotEmpty,
        'Caja sin sucursal o nombre válido.',
      );
    }
    for (final p in branchProducts) {
      require(
        branchMap.containsKey(p.branchId) &&
            productMap.containsKey(p.productId),
        'Catálogo de sucursal inválido.',
      );
    }
    for (final s in staff) {
      require(
        s.name.trim().isNotEmpty &&
            branchMap.containsKey(s.branchId) &&
            s.jobTitle.trim().isNotEmpty &&
            RegExp(r'^[a-z0-9._-]{3,40}$').hasMatch(s.username) &&
            (!s.active || branchMap[s.branchId]?.active == true),
        'Personal o sucursal asignada inválidos.',
      );
      require(
        s.registerId.isEmpty ||
            (s.active &&
                registerMap[s.registerId]?.active == true &&
                registerMap[s.registerId]?.branchId == s.branchId),
        'Caja asignada de otra sucursal, inactiva o empleado inactivo.',
      );
    }
    require(sequence >= 0, 'Secuencia inválida.');
    require(
      demoScenarioVersion >= 0 &&
          demoScenarioVersion <= PharmacyDemoScenario.version,
      'Versión del historial inválida.',
    );
    for (final id in groups.expand((g) => g)) {
      if (RegExp(
        r'^(local-|AUD-|IM-|CJ-|CM-|CNT-|FV-|OC-|INC-|BR-|REG-|EMP-)',
      ).hasMatch(id)) {
        final suffix = int.tryParse(id.split('-').last);
        require(
          suffix != null && suffix <= sequence,
          'Secuencia menor que sus registros.',
        );
      }
    }
    for (final p in products) {
      require(
        p.name.trim().isNotEmpty &&
            p.unit.trim().isNotEmpty &&
            p.price >= 0 &&
            p.packageUnits >= 1 &&
            p.packageUnits <= 1000000 &&
            p.price <= 1000000 &&
            p.minimum >= 0,
        'Ficha de producto inválida.',
      );
    }
    for (final r in productSuppliers) {
      require(
        productMap.containsKey(r.productId) &&
            contactMap[r.supplierId]?.kind == ContactKind.supplier &&
            r.referenceCost >= 0 &&
            r.referenceCost <= 1000000 &&
            r.leadDays >= 0 &&
            r.leadDays <= 365,
        'Relación producto–proveedor inválida.',
      );
    }
    for (final l in lots) {
      require(
        productMap.containsKey(l.productId) &&
            branchMap.containsKey(l.branchId) &&
            l.code.isNotEmpty &&
            l.quantity >= 0 &&
            l.quantity <= 1000000 &&
            l.unitCost >= 0 &&
            l.unitCost <= 1000000 &&
            (l.supplierId.isEmpty ||
                contactMap[l.supplierId]?.kind == ContactKind.supplier) &&
            (l.manufacturedAt == null ||
                (InventoryLot.dayOnly(
                      l.manufacturedAt!,
                    ).isBefore(InventoryLot.dayOnly(l.expiry)) &&
                    !InventoryLot.dayOnly(
                      l.manufacturedAt!,
                    ).isAfter(InventoryLot.dayOnly(l.receivedAt)))),
        'Lote o referencia inválidos.',
      );
    }
    for (final c in contacts) {
      require(c.name.trim().isNotEmpty, 'Contacto sin nombre.');
    }
    for (final p in purchases) {
      require(
        branchMap.containsKey(p.branchId) &&
            contactMap[p.supplierId]?.kind == ContactKind.supplier &&
            p.lines.isNotEmpty &&
            p.total <= 1000000000,
        'Compra sin proveedor o líneas válidas.',
      );
      unique(p.lines.map((l) => l.productId));
      for (final l in p.lines) {
        require(
          productMap.containsKey(l.productId) &&
              l.quantity > 0 &&
              l.quantity <= 1000000 &&
              l.unitCost > 0 &&
              l.unitCost <= 1000000 &&
              l.packageUnits >= 1,
          'Línea de compra inválida.',
        );
      }
      require(
        (p.status == PurchaseStatus.received) == (p.receivedAt != null),
        'Estado de recepción incoherente.',
      );
      require(
        p.paidAt == null || p.status == PurchaseStatus.received,
        'Pago de compra no recibida.',
      );
    }
    for (final s in sales) {
      final traced = [
        s.actorId,
        s.branchId,
        s.branchName,
        s.registerId,
        s.registerName,
      ];
      require(
        traced.every((v) => v.isEmpty) ||
            (traced.every((v) => v.trim().isNotEmpty) &&
                staffMap.containsKey(s.actorId) &&
                branchMap.containsKey(s.branchId) &&
                registerMap[s.registerId]?.branchId == s.branchId),
        'Trazabilidad de venta incompleta o caja de otra sucursal.',
      );
      require(
        s.lines.isNotEmpty &&
            s.total <= 1000000000 &&
            s.cashReceived >= s.total &&
            (s.customerId.isEmpty ||
                contactMap[s.customerId]?.kind == ContactKind.customer),
        'Comprobante inválido.',
      );
      unique(s.lines.map((l) => l.productId));
      for (final l in s.lines) {
        require(
          productMap.containsKey(l.productId) &&
              l.quantity > 0 &&
              l.unitPrice > 0 &&
              l.allocations.fold<int>(0, (n, a) => n + a.quantity) ==
                  l.quantity,
          'Cantidades de venta incoherentes.',
        );
        for (final a in l.allocations) {
          require(
            a.quantity > 0 &&
                lotMap[a.lotId]?.productId == l.productId &&
                (s.branchId.isEmpty || lotMap[a.lotId]?.branchId == s.branchId),
            'Asignación de lote inválida.',
          );
        }
      }
      require(
        !s.cancelled ||
            (s.reason.trim().isNotEmpty &&
                !s.cancelledAt!.isBefore(s.createdAt)),
        'Anulación sin motivo o fecha válida.',
      );
    }
    require(
      cashSessions.where((s) => s.isOpen).length <= 1,
      'No puede haber dos cajas abiertas.',
    );
    for (final s in cashSessions) {
      require(
        s.openingBalance >= 0 &&
            (s.isOpen
                ? s.counted == null
                : s.counted != null &&
                      s.counted! >= 0 &&
                      !s.closedAt!.isBefore(s.openedAt)),
        'Arqueo de caja inválido.',
      );
    }
    for (final m in cashMovements) {
      require(
        sessionIds.contains(m.sessionId) &&
            m.amount != 0 &&
            m.concept.trim().isNotEmpty,
        'Movimiento de caja inválido.',
      );
    }
    for (final m in movements) {
      require(
        lotMap[m.lotId]?.productId == m.productId &&
            m.balance >= 0 &&
            m.reason.trim().isNotEmpty,
        'Movimiento de inventario inválido.',
      );
    }
    for (final i in incidents) {
      require(
        i.title.trim().isNotEmpty &&
            ['Baja', 'Media', 'Alta'].contains(i.priority) &&
            (i.status == IncidentStatus.resolved
                ? i.resolvedAt != null && i.resolution.trim().isNotEmpty
                : i.resolvedAt == null),
        'Incidente incoherente.',
      );
    }
  }
}
