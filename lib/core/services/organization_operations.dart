part of 'pharmacy_controller.dart';

/// Organización multisedes. Todas las escrituras pasan por permisos y
/// validaciones de pertenencia; filtrar widgets por sí solo no sería suficiente.
extension OrganizationOperations on PharmacyController {
  /// Solo para el login DEMO: sin contraseñas guardadas ni alta pública.
  Future<List<SessionUser>> localLoginAccounts() async {
    await initialize();
    if (loadFailed) throw StateError('Personal local no disponible');
    return [for (final s in _staff.where((s) => s.active)) s.session];
  }

  StaffMember? staffById(String id) {
    if (!isAdministrator && id != actorId) return null;
    for (final member in _staff) {
      if (member.id == id) return member;
    }
    return null;
  }

  PharmacyBranch? branchById(String id) {
    if (!isAdministrator && id != currentStaff?.branchId) return null;
    for (final branch in _branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  BillingRegister? registerById(String id) {
    if (!isAdministrator && id != currentStaff?.registerId) return null;
    for (final register in _registers) {
      if (register.id == id) return register;
    }
    return null;
  }

  StaffMember? get currentStaff => staffById(actorId);
  String get workingBranchId => isAdministrator
      ? _selectedBranchId
      : (currentStaff?.active == true ? currentStaff!.branchId : '');
  PharmacyBranch? get workingBranch => branchById(workingBranchId);
  BillingRegister? get currentRegister {
    final member = currentStaff;
    final register = registerById(member?.registerId ?? '');
    return member?.active == true &&
            member?.branchId == workingBranchId &&
            register?.branchId == workingBranchId &&
            register?.active == true &&
            workingBranch?.active == true
        ? register
        : null;
  }

  List<PharmacyBranch> get branches => List.unmodifiable(
    _branches.where(
      (b) =>
          isAdministrator ||
          (currentStaff?.active == true && b.id == currentStaff?.branchId),
    ),
  );
  List<BillingRegister> get registers => List.unmodifiable(
    _registers.where(
      (r) =>
          isAdministrator ||
          (currentStaff?.active == true &&
              r.id == currentStaff?.registerId &&
              r.branchId == workingBranchId),
    ),
  );
  List<StaffMember> get staff => List.unmodifiable(
    _staff.where((s) => isAdministrator || s.id == actorId),
  );
  List<Product> get masterProducts =>
      isAdministrator ? List.unmodifiable(_products) : products;
  bool productEnabled(String branchId, String productId) => _branchProducts.any(
    (p) => p.branchId == branchId && p.productId == productId,
  );
  StaffMember? operatorFor(String registerId) {
    for (final s in staff) {
      if (s.active && s.registerId == registerId) return s;
    }
    return null;
  }

  /// Cambiar contexto vacía el carrito: nunca se trasladan reservas entre sedes.
  String? selectBranch(String id) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    if (branchById(id)?.active != true) {
      return 'Selecciona una sucursal activa.';
    }
    if (_selectedBranchId == id) return null;
    _selectedBranchId = id;
    _cart.clear();
    inventorySearch = '';
    inventoryFilter = 'Todos';
    _notify();
    return null;
  }

  String? get billingAssignmentError {
    if (currentStaff?.active != true) {
      return 'Tu cuenta no tiene una asignación activa.';
    }
    if (workingBranch?.active != true) return 'Tu sucursal no está activa.';
    if (currentRegister == null) {
      return 'Necesitas una caja activa asignada en esta sucursal para facturar. Solicítala al administrador.';
    }
    return null;
  }

  String? saveBranch({
    String? id,
    required String name,
    String address = '',
    bool active = true,
  }) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    if (name.trim().isEmpty) return 'Indica el nombre de la sucursal.';
    if (_branches.any(
      (b) => b.id != id && b.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      return 'Ya existe una sucursal con ese nombre.';
    }
    if (id != null && branchById(id) == null) return 'Sucursal no encontrada.';
    if (!active &&
        (_staff.any((s) => s.active && s.branchId == id) ||
            _purchases.any(
              (p) => p.branchId == id && p.status == PurchaseStatus.pending,
            ))) {
      return 'Reasigna al personal y resuelve las compras pendientes antes de desactivar la sucursal.';
    }
    final record = PharmacyBranch(
      id: id ?? _nextId('BR'),
      name: name.trim(),
      address: address.trim(),
      active: active,
    );
    if (id == null) {
      _branches.add(record);
    } else {
      _branches[_branches.indexWhere((b) => b.id == id)] = record;
    }
    _cart.clear();
    _commit(
      'Sucursal guardada',
      '${record.id} · ${record.name} · ${active ? 'Activa' : 'Inactiva'}',
    );
    return null;
  }

  String? saveRegister({
    String? id,
    required String branchId,
    required String name,
    bool active = true,
  }) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    if (branchById(branchId)?.active != true || name.trim().isEmpty) {
      return 'Indica una sucursal activa y el nombre de caja.';
    }
    final old = id == null ? null : registerById(id);
    if (id != null && old == null) return 'Caja no encontrada.';
    if (old != null && old.branchId != branchId) {
      return 'No se traslada una caja entre sucursales. Crea otra caja.';
    }
    if (_registers.any(
      (r) =>
          r.id != id &&
          r.branchId == branchId &&
          r.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      return 'Ese nombre de caja ya existe en la sucursal.';
    }
    if (!active && _staff.any((s) => s.active && s.registerId == id)) {
      return 'Libera o reasigna al operador antes de desactivar esta caja.';
    }
    final record = BillingRegister(
      id: id ?? _nextId('REG'),
      branchId: branchId,
      name: name.trim(),
      active: active,
    );
    if (id == null) {
      _registers.add(record);
    } else {
      _registers[_registers.indexWhere((r) => r.id == id)] = record;
    }
    _commit(
      'Caja de facturación guardada',
      '${record.name} · ${branchById(branchId)!.name} · ${active ? 'Activa' : 'Inactiva'}',
    );
    return null;
  }

  /// Una sola asignación vigente por empleado y un operador por caja.
  /// Rol, estado y asignación se validan juntos, solo por un administrador.
  /// Cambiar el directorio no reescribe los datos históricos de las facturas.
  String? saveStaff({
    String? id,
    required String name,
    required String username,
    required String branchId,
    String registerId = '',
    String jobTitle = 'Dependiente',
    UserRole? role,
    bool active = true,
  }) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    final old = id == null ? null : staffById(id);
    if (id != null && old == null) return 'Empleado no encontrado.';
    final login = username.trim().toLowerCase();
    if (name.trim().isEmpty ||
        jobTitle.trim().isEmpty ||
        !RegExp(r'^[a-z0-9._-]{3,40}$').hasMatch(login)) {
      return 'Indica nombre, puesto y un usuario de 3 a 40 caracteres (letras, números, punto, guion).';
    }
    if (_staff.any((s) => s.id != id && s.username == login)) {
      return 'El usuario ya existe.';
    }
    if (old != null && old.username != login) {
      return 'El usuario de acceso no se modifica.';
    }
    final nextRole = role ?? old?.role ?? UserRole.employee;
    // Se conserva la cuenta de recuperación exigida por los respaldos v2.
    // Tampoco se permite quitarse el propio acceso durante una sesión activa.
    if ((id == 'demo-admin' || id == actorId) &&
        (!active || nextRole != UserRole.administrator)) {
      return 'La cuenta principal y tu propia sesión deben conservar el acceso de administrador activo.';
    }
    if (branchById(branchId) == null ||
        (active && branchById(branchId)?.active != true)) {
      return 'Selecciona una sucursal activa.';
    }
    if (!active && registerId.isNotEmpty) {
      return 'Libera la caja al desactivar al empleado.';
    }
    if (registerId.isNotEmpty) {
      final register = registerById(registerId);
      if (register?.active != true || register?.branchId != branchId) {
        return 'La caja debe estar activa y pertenecer a la sucursal elegida.';
      }
      if (_staff.any(
        (s) => s.id != id && s.active && s.registerId == registerId,
      )) {
        return 'La caja ya tiene otro operador. Libérala antes de reasignarla.';
      }
    }
    final record = StaffMember(
      id: id ?? _nextId('EMP'),
      name: name.trim(),
      username: login,
      branchId: branchId,
      registerId: registerId,
      jobTitle: jobTitle.trim(),
      photoAsset: old?.photoAsset ?? '',
      identification: old?.identification ?? '',
      role: nextRole,
      active: active,
    );
    if (old == null) {
      _staff.add(record);
    } else {
      _staff[_staff.indexOf(old)] = record;
    }
    if (id == actorId &&
        old != null &&
        (old.branchId != branchId || old.registerId != registerId)) {
      _selectedBranchId = branchId;
      _cart.clear();
      inventorySearch = '';
      inventoryFilter = 'Todos';
    }
    _commit(
      'Personal y asignación actualizados',
      '${record.id} · ${record.name}: ${old?.branchId ?? 'Nuevo'}/${old?.registerId ?? ''} → $branchId/$registerId · Rol: ${old?.role.label ?? 'Nuevo'} → ${nextRole.label} · ${active ? 'Activo' : 'Inactivo'}',
    );
    return null;
  }

  String? setBranchProduct(String branchId, String productId, bool enabled) {
    final denied = _permissionError(administrator: true);
    if (denied != null) return denied;
    if (branchById(branchId)?.active != true ||
        !_products.any((p) => p.id == productId)) {
      return 'Producto o sucursal no válidos.';
    }
    if (enabled == productEnabled(branchId, productId)) return null;
    if (!enabled &&
        (_lots.any(
              (l) =>
                  l.branchId == branchId &&
                  l.productId == productId &&
                  l.quantity > 0,
            ) ||
            _purchases.any(
              (p) =>
                  p.branchId == branchId &&
                  p.status == PurchaseStatus.pending &&
                  p.lines.any((l) => l.productId == productId),
            ))) {
      return 'Resuelve las existencias y compras pendientes antes de retirar el producto de la sucursal.';
    }
    if (enabled) {
      _branchProducts.add(BranchProduct(branchId, productId));
    } else {
      _branchProducts.removeWhere(
        (p) => p.branchId == branchId && p.productId == productId,
      );
    }
    _cart.clear();
    _commit(
      'Catálogo de sucursal actualizado',
      '$branchId · $productId · ${enabled ? 'Habilitado' : 'Retirado'}',
    );
    return null;
  }
}
