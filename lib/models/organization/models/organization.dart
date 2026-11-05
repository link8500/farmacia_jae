import '../../../core/utils/json_value.dart';
import '../../auth/models/session_user.dart';

/// Identidad estable para migrar el inventario anterior, que tenía una sola sede.
const mainBranchId = 'branch-main';

/// Sede física. No es un rol: el permiso y la ubicación son conceptos separados.
class PharmacyBranch {
  const PharmacyBranch({
    required this.id,
    required this.name,
    this.address = '',
    this.active = true,
  });
  final String id, name, address;
  final bool active;
  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'active': active,
  };
  factory PharmacyBranch.fromJson(JsonMap j) => PharmacyBranch(
    id: jsonText(j, 'id'),
    name: jsonText(j, 'name'),
    address: jsonText(j, 'address'),
    active: jsonBool(j, 'active'),
  );
}

/// Puesto de facturación perteneciente a UNA sede, no un arqueo de efectivo.
class BillingRegister {
  const BillingRegister({
    required this.id,
    required this.branchId,
    required this.name,
    this.active = true,
  });
  final String id, branchId, name;
  final bool active;
  Map<String, Object> toJson() => {
    'id': id,
    'branchId': branchId,
    'name': name,
    'active': active,
  };
  factory BillingRegister.fromJson(JsonMap j) => BillingRegister(
    id: jsonText(j, 'id'),
    branchId: jsonText(j, 'branchId'),
    name: jsonText(j, 'name'),
    active: jsonBool(j, 'active'),
  );
}

/// Personal administrado, sin contraseña ni registro público. La asignación
/// actual puede cambiar; las facturas guardan una fotografía histórica propia.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.username,
    this.role = UserRole.employee,
    this.branchId = '',
    this.registerId = '',
    this.jobTitle = 'Dependiente',
    this.photoAsset = '',
    this.identification = '',
    this.active = true,
  });
  final String id, name, username, branchId, registerId, jobTitle;
  final String photoAsset, identification;
  final UserRole role;
  final bool active;
  SessionUser get session => SessionUser(
    id: id,
    name: name,
    username: username,
    email: '',
    role: role,
    employeeCode: id,
    avatarAsset: photoAsset,
  );
  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'role': role.name,
    'branchId': branchId,
    'registerId': registerId,
    'jobTitle': jobTitle,
    'photoAsset': photoAsset,
    'identification': identification,
    'active': active,
  };
  factory StaffMember.fromJson(JsonMap j) => StaffMember(
    id: jsonText(j, 'id'),
    name: jsonText(j, 'name'),
    username: jsonText(j, 'username'),
    role: jsonEnum(j, 'role', UserRole.values),
    branchId: jsonText(j, 'branchId'),
    registerId: jsonText(j, 'registerId'),
    jobTitle: jsonText(j, 'jobTitle'),
    photoAsset: jsonText(j, 'photoAsset', fallback: ''),
    identification: jsonText(j, 'identification', fallback: ''),
    active: jsonBool(j, 'active'),
  );
}

/// Habilitación de una ficha maestra en una sede; NO representa existencias.
class BranchProduct {
  const BranchProduct(this.branchId, this.productId);
  final String branchId, productId;
  Map<String, Object> toJson() => {
    'branchId': branchId,
    'productId': productId,
  };
  factory BranchProduct.fromJson(JsonMap j) =>
      BranchProduct(jsonText(j, 'branchId'), jsonText(j, 'productId'));
}

/// Valores iniciales/migración. No se inventan sucursales con stock duplicado.
abstract final class OrganizationDefaults {
  static const branches = [
    PharmacyBranch(
      id: mainBranchId,
      name: 'Sucursal principal',
      address: 'La Paz Centro, León',
    ),
  ];
  static const registers = [
    BillingRegister(
      id: 'register-main-1',
      branchId: mainBranchId,
      name: 'Caja 1',
    ),
    BillingRegister(
      id: 'register-main-2',
      branchId: mainBranchId,
      name: 'Caja 2',
    ),
  ];
  static const staff = [
    StaffMember(
      id: 'demo-admin',
      name: 'Ana Martínez',
      username: 'admin',
      role: UserRole.administrator,
      branchId: mainBranchId,
      registerId: 'register-main-2',
      jobTitle: 'Administrador',
    ),
    StaffMember(
      id: 'demo-employee',
      name: 'Daniel López',
      username: 'usuario',
      branchId: mainBranchId,
      registerId: 'register-main-1',
    ),
  ];
}
