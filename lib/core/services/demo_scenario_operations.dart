part of 'pharmacy_controller.dart';

/// Instalación aditiva y atómica del historial ficticio. Nunca reemplaza los
/// lotes, clientes, precios ni asignaciones que el usuario haya modificado.
extension DemoScenarioOperations on PharmacyController {
  /// Completa únicamente metadatos vacíos de IDs conocidos de demostración.
  /// También sirve para respaldos anteriores: no reinicia historial, puestos,
  /// contactos nuevos ni los valores ya editados por el usuario.
  void _enrichDemoPeople() {
    for (var i = 0; i < _contacts.length; i++) {
      final old = _contacts[i];
      final demo = DemoPeople.records[old.id];
      if (demo == null) continue;
      var supplierCode = old.code;
      if (old.kind == ContactKind.supplier && supplierCode.isEmpty) {
        var n = i + 1;
        do {
          supplierCode = 'PRV-${n.toString().padLeft(4, '0')}';
          n++;
        } while (_contacts.any((c) => c.code.toUpperCase() == supplierCode));
      }
      _contacts[i] = old.copyWith(
        code: supplierCode,
        supplierType:
            old.kind == ContactKind.supplier && old.supplierType.isEmpty
            ? 'Distribuidor'
            : old.supplierType,
        origin: old.kind == ContactKind.supplier && old.origin.isEmpty
            ? 'Nicaragua'
            : old.origin,
        description: old.kind == ContactKind.supplier && old.description.isEmpty
            ? 'Distribución de productos farmacéuticos y artículos de cuidado personal.'
            : old.description,
        photoAsset: old.photoAsset.isEmpty ? demo.photo : old.photoAsset,
        identification: old.identification.isEmpty
            ? demo.document
            : old.identification,
        representative: old.representative.isEmpty
            ? demo.representative
            : old.representative,
        phone: old.phone.isEmpty
            ? '+505 0000-${(1000 + i).toString()}'
            : old.phone,
      );
    }
    for (var i = 0; i < _staff.length; i++) {
      final old = _staff[i];
      final demo = DemoPeople.records[old.id];
      if (demo == null) continue;
      _staff[i] = StaffMember(
        id: old.id,
        name: old.name,
        username: old.username,
        role: old.role,
        branchId: old.branchId,
        registerId: old.registerId,
        jobTitle: old.jobTitle,
        active: old.active,
        photoAsset: old.photoAsset.isEmpty ? demo.photo : old.photoAsset,
        identification: old.identification.isEmpty
            ? demo.document
            : old.identification,
      );
    }
  }

  bool _installDemoHistory() {
    if (hasDemoHistory) return false;
    final scenario = PharmacyDemoScenario.build(
      now: now,
      products: _products.where((p) => p.active).take(8).toList(),
      existingBranches: _branches,
      existingRegisters: _registers,
      existingStaff: _staff,
    );
    final candidate = _snapshotJson();
    void append<T>(String key, List<T> records, JsonMap Function(T) encode) {
      candidate[key] = [...candidate[key] as List, ...records.map(encode)];
    }

    append('branches', scenario.branches, (p) => p.toJson());
    append('registers', scenario.registers, (p) => p.toJson());
    append('staff', scenario.staff, (p) => p.toJson());
    // Solo habilita catálogos de las sedes nuevas. Respeta las habilitaciones
    // existentes, incluidas fichas retiradas de la sucursal principal.
    append(
      'branchProducts',
      scenario.branchProducts
          .where((p) => scenario.branches.any((b) => b.id == p.branchId))
          .toList(),
      (p) => p.toJson(),
    );
    append('contacts', scenario.contacts, (p) => p.toJson());
    append('purchases', scenario.purchases, (p) => p.toJson());
    final links = {
      for (final r in _productSuppliers) '${r.productId}|${r.supplierId}': r,
    };
    for (final p in scenario.purchases) {
      for (final l in p.lines) {
        links.putIfAbsent(
          '${l.productId}|${p.supplierId}',
          () => ProductSupplier(
            productId: l.productId,
            supplierId: p.supplierId,
            referenceCost: l.unitCost,
          ),
        );
      }
    }
    candidate['productSuppliers'] = links.values
        .map((r) => r.toJson())
        .toList();
    append('lots', scenario.lots, (p) => p.toJson());
    append('sales', scenario.sales, (p) => p.toJson());
    append('movements', scenario.movements, (p) => p.toJson());
    append('audit', scenario.audit, (p) => p.toJson());
    candidate['demoScenarioVersion'] = PharmacyDemoScenario.version;
    // El mismo validador de respaldos comprueba todas las relaciones antes
    // de tocar el estado vivo. Un conflicto deja los datos anteriores intactos.
    final validated = _AdministrationSnapshot.decode(jsonEncode(candidate));
    _applySnapshot(validated);
    demoDataError = null;
    return true;
  }

  /// Acción de recuperación para entradas alternativas del prototipo.
  String? addDemoHistory() {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    if (hasDemoHistory) {
      return 'El historial ya está instalado.';
    }
    try {
      _installDemoHistory();
      _commit(
        'Historial añadido',
        'Historial ficticio vinculado de seis meses',
      );
      return null;
    } on FormatException catch (error) {
      return demoDataError = 'No se añadieron datos: ${error.message}';
    }
  }
}
