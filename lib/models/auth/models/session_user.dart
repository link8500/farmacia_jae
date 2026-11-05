import '../../profile/models/profile_appearance.dart';

/// Roles del personal. La presentación pública nunca necesita un rol.
enum UserRole {
  administrator('Administrador', 'Administración general'),
  employee('Empleado', 'Ventas y atención al cliente');

  const UserRole(this.label, this.department);
  final String label;
  final String department;
}

/// Datos de la sesión y del perfil, independientes de los widgets.
/// El personal de este prototipo utiliza datos y autenticación de demostración.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.employeeCode,
    this.phone = '',
    this.contactEmail,
    this.avatarSymbol = ProfileSymbol.initials,
    this.avatarTone = ProfileTone.navy,
    this.avatarPhoto = '',
    this.avatarAsset = '',
  });

  final String id;
  final String name;

  /// Identificador de acceso demo, separado del correo de contacto y del rol.
  final String username;
  final String email;
  final UserRole role;
  final String employeeCode;
  final String phone;

  /// Correo personal, independiente del identificador y correo del directorio.
  final String? contactEmail;
  String get displayEmail => contactEmail ?? email;
  final ProfileSymbol avatarSymbol;
  final ProfileTone avatarTone;
  final String avatarPhoto;

  /// Retrato local de demostración; la foto subida por el usuario tiene prioridad.
  final String avatarAsset;
  bool get isAdministrator => role == UserRole.administrator;
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .where((part) => part.isNotEmpty)
      .map((part) => String.fromCharCode(part.runes.first))
      .join()
      .toUpperCase();

  /// Permite editar datos de contacto sin cambiar el rol ni la identidad.
  SessionUser copyWith({
    String? name,
    String? phone,
    String? contactEmail,
    ProfileSymbol? avatarSymbol,
    ProfileTone? avatarTone,
    String? avatarPhoto,
    String? avatarAsset,
  }) => SessionUser(
    id: id,
    name: name ?? this.name,
    username: username,
    email: email,
    role: role,
    employeeCode: employeeCode,
    phone: phone ?? this.phone,
    contactEmail: contactEmail ?? this.contactEmail,
    avatarSymbol: avatarSymbol ?? this.avatarSymbol,
    avatarTone: avatarTone ?? this.avatarTone,
    avatarPhoto: avatarPhoto ?? this.avatarPhoto,
    avatarAsset: avatarAsset ?? this.avatarAsset,
  );

  /// Solo el directorio autorizado suministra este rol al iniciar sesión.
  /// Se mantiene separado de copyWith para que editar el perfil no dé permisos.
  SessionUser withDirectoryRole(UserRole directoryRole) => SessionUser(
    id: id,
    name: name,
    username: username,
    email: email,
    role: directoryRole,
    employeeCode: employeeCode,
    phone: phone,
    contactEmail: contactEmail,
    avatarSymbol: avatarSymbol,
    avatarTone: avatarTone,
    avatarPhoto: avatarPhoto,
    avatarAsset: avatarAsset,
  );
}
