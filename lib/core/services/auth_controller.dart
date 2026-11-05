import 'dart:convert';
import '../config/demo_people.dart';
import 'package:flutter/foundation.dart';
import 'preferences_store.dart';
import '../../models/auth/models/session_user.dart';
import '../../models/profile/models/profile_appearance.dart';

/// Sesión temporal del prototipo. NO es autenticación de producción.
///
/// Las credenciales de ejemplo se validan en el cliente. No hay tokens,
/// servidor ni almacenamiento de contraseñas. Recargar elimina la sesión.
/// En producción, NestJS deberá autenticar y autorizar cada petición.
class AuthController extends ChangeNotifier {
  AuthController({PreferencesStore? profiles})
    : _profiles = profiles ?? MemoryPreferencesStore();
  final PreferencesStore _profiles;

  /// Directorio local administrado; no es un proveedor de identidad seguro.
  Future<List<SessionUser>> Function()? accountProvider;
  final Map<String, Map<String, String>> _profileData = {};
  bool _profilesLoaded = false;
  Future<void> _profileWrites = Future.value();
  String? profileStorageError;
  SessionUser? _user;
  bool _signingIn = false;
  bool _disposed = false;
  SessionUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isSigningIn => _signingIn;

  // Credenciales simples exclusivamente para probar el prototipo sin backend.
  static const demoPassword = '1234';
  static const demoUsers = [
    SessionUser(
      id: 'demo-admin',
      name: 'Ana Martínez',
      username: 'admin',
      email: 'admin@farmaciajae.demo',
      role: UserRole.administrator,
      employeeCode: 'JAE-001',
      avatarAsset: 'images/people/demo-admin.jpg',
    ),
    SessionUser(
      id: 'demo-employee',
      name: 'Daniel López',
      username: 'usuario',
      email: 'usuario@farmaciajae.demo',
      role: UserRole.employee,
      employeeCode: 'JAE-002',
      avatarAsset: 'images/people/demo-employee.jpg',
    ),
  ];

  /// Devuelve un error visible ante credenciales inválidas. No existe registro.
  Future<String?> signIn(String username, String password) async {
    if (_signingIn) return 'Ya hay un inicio de sesión en curso.';
    _signingIn = true;
    notifyListeners();
    // Simula exclusivamente el estado visual de espera del formulario.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (_disposed) return 'La sesión ya no está disponible.';
    final normalized = username.trim().toLowerCase();
    List<SessionUser> accounts;
    try {
      accounts = accountProvider == null ? demoUsers : await accountProvider!();
    } catch (_) {
      _signingIn = false;
      if (!_disposed) notifyListeners();
      return 'No se pudo cargar el personal local. Revisa los datos antes de iniciar sesión.';
    }
    if (_disposed) return 'La sesión ya no está disponible.';
    final matches = accounts.where((user) => user.username == normalized);
    if (password != demoPassword || matches.isEmpty) {
      _signingIn = false;
      notifyListeners();
      return 'El usuario o la contraseña no son correctos.';
    }
    if (!_profilesLoaded) {
      try {
        final raw = await _profiles.read();
        if (_disposed) return 'La sesión ya no está disponible.';
        if (raw != null) {
          final json = jsonDecode(raw);
          if (json is Map &&
              (json['version'] == 1 || json['version'] == 2) &&
              json['users'] is Map) {
            for (final demo in accounts) {
              final saved = json['users'][demo.id];
              if (saved is Map &&
                  saved['name'] is String &&
                  ProfileFields.name(saved['name'] as String) == null &&
                  saved['phone'] is String) {
                _profileData[demo.id] = {
                  'name': saved['name'] as String,
                  'phone': ProfileFields.phone(saved['phone'] as String) == null
                      ? saved['phone'] as String
                      : '',
                  if (saved['contactEmail'] is String &&
                      ProfileFields.email(saved['contactEmail'] as String) ==
                          null)
                    'contactEmail': saved['contactEmail'] as String,
                  if (saved['avatarSymbol'] is String &&
                      ProfileSymbol.values.any(
                        (v) => v.name == saved['avatarSymbol'],
                      ))
                    'avatarSymbol': saved['avatarSymbol'] as String,
                  if (saved['avatarTone'] is String &&
                      ProfileTone.values.any(
                        (v) => v.name == saved['avatarTone'],
                      ))
                    'avatarTone': saved['avatarTone'] as String,
                  if (saved['avatarPhoto'] is String &&
                      ProfilePhoto.decode(saved['avatarPhoto'] as String) !=
                          null)
                    'avatarPhoto': saved['avatarPhoto'] as String,
                  if (saved['avatarAsset'] is String &&
                      DemoPeople.validPhoto(saved['avatarAsset'] as String))
                    'avatarAsset': saved['avatarAsset'] as String,
                };
              }
            }
          }
        }
      } catch (_) {
        profileStorageError =
            'No se pudo recuperar el perfil local. La cuenta demo sigue disponible.';
      }
      _profilesLoaded = true;
    }
    final saved = _profileData[matches.single.id];
    _user = matches.single.copyWith(
      name: saved?['name'],
      phone: saved?['phone'],
      contactEmail: saved?['contactEmail'],
      avatarSymbol: ProfileSymbol.values
          .where((v) => v.name == saved?['avatarSymbol'])
          .firstOrNull,
      avatarTone: ProfileTone.values
          .where((v) => v.name == saved?['avatarTone'])
          .firstOrNull,
      avatarPhoto: saved?['avatarPhoto'],
      avatarAsset: saved?['avatarAsset'],
    );
    _signingIn = false;
    notifyListeners();
    return null;
  }

  /// Guarda solo datos personales de la cuenta demo, sin conceder permisos.
  String? updateProfile({
    required String name,
    required String phone,
    String? contactEmail,
    ProfileSymbol? avatarSymbol,
    ProfileTone? avatarTone,
    String? avatarPhoto,
    String? avatarAsset,
  }) {
    if (_disposed || _user == null) {
      return 'Inicia sesión para editar tu perfil.';
    }
    final error =
        ProfileFields.name(name) ??
        ProfileFields.phone(phone) ??
        (contactEmail == null ? null : ProfileFields.email(contactEmail));
    if (error != null) return error;
    if (avatarAsset != null && !DemoPeople.validPhoto(avatarAsset)) {
      return 'Selecciona una foto local válida.';
    }
    if (avatarPhoto != null &&
        avatarPhoto.isNotEmpty &&
        ProfilePhoto.decode(avatarPhoto) == null) {
      return 'Selecciona una foto válida de hasta 128 KB después de optimizarla.';
    }
    _user = _user!.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      contactEmail: contactEmail?.trim(),
      avatarSymbol: avatarSymbol,
      avatarTone: avatarTone,
      avatarPhoto: avatarPhoto,
      avatarAsset: avatarAsset,
    );
    _profileData[_user!.id] = {
      'name': _user!.name,
      'phone': _user!.phone,
      'contactEmail': _user!.displayEmail,
      'avatarSymbol': _user!.avatarSymbol.name,
      'avatarTone': _user!.avatarTone.name,
      'avatarPhoto': _user!.avatarPhoto,
      'avatarAsset': _user!.avatarAsset,
    };
    final raw = jsonEncode({'version': 2, 'users': _profileData});
    _profileWrites = _profileWrites.then((_) async {
      try {
        await _profiles.write(raw);
        if (!_disposed) profileStorageError = null;
      } catch (_) {
        if (!_disposed) {
          profileStorageError =
              'El perfil cambió en esta sesión, pero no se guardó localmente.';
        }
      }
      if (!_disposed) notifyListeners();
    });
    notifyListeners();
    return null;
  }

  /// Revoca inmediatamente la sesión y fuerza la reevaluación del guard.
  void signOut() {
    _user = null;
    notifyListeners();
  }

  Future<void> flushProfile() => _profileWrites;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
