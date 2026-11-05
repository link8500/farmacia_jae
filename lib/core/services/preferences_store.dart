import 'package:shared_preferences/shared_preferences.dart';

/// Puerto de almacenamiento: permite probar preferencias sin plugins o red.
abstract interface class PreferencesStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// Solo guarda UN documento de preferencias en una clave propia. No utiliza
/// clear() ni accede a credenciales, registros de farmacia u otras aplicaciones.
class LocalPreferencesStore implements PreferencesStore {
  static const key = 'farmacia_jae.administration.preferences.v1';
  SharedPreferencesAsync? _storage;
  // Inicialización diferida: abrir presentación no inicializa el plugin. Si el
  // navegador lo bloquea, el controlador puede capturar también este error.
  SharedPreferencesAsync get _preferences =>
      _storage ??= SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

/// Adaptador de pruebas/vistas aisladas; no se presenta como almacenamiento real.
class MemoryPreferencesStore implements PreferencesStore {
  MemoryPreferencesStore([this.data]);
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async {
    data = value;
  }
}

/// Datos personales y avatar de perfiles locales. Conserva la clave v1 para
/// migrar los perfiles anteriores, sin guardar roles, sesiones o contraseñas.
class LocalDemoProfilesStore implements PreferencesStore {
  SharedPreferencesAsync? _storage;
  SharedPreferencesAsync get _instance => _storage ??= SharedPreferencesAsync();
  static const key = 'farmacia_jae.demo_profiles.v1';
  @override
  Future<String?> read() => _instance.getString(key);
  @override
  Future<void> write(String value) => _instance.setString(key, value);
}
