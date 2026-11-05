import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia exclusiva del prototipo. No es una base central multiusuario.
abstract interface class AdministrationStore {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalAdministrationStore implements AdministrationStore {
  // Se conserva la clave original. La versión del DOCUMENTO interno ahora es 2
  // y se migra al leer; cambiar esta clave haría parecer perdidos los datos v1.
  static const key = 'farmacia_jae.administration.data.v1';
  SharedPreferencesAsync? _storage;
  SharedPreferencesAsync get _instance => _storage ??= SharedPreferencesAsync();
  @override
  Future<String?> read() => _instance.getString(key);
  @override
  Future<void> write(String value) => _instance.setString(key, value);
}

class MemoryAdministrationStore implements AdministrationStore {
  MemoryAdministrationStore([this.data]);
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async {
    data = value;
  }
}
