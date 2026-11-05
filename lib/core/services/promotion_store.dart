import 'package:shared_preferences/shared_preferences.dart';

/// Dos documentos: el sitio público solo lee la proyección publicada y nunca
/// abre inventario, perfiles, autenticación ni el documento de borradores.
abstract interface class PromotionStore {
  Future<String?> read({bool published = false});
  Future<void> write(String data, {bool published = false});
}

class LocalPromotionStore implements PromotionStore {
  SharedPreferencesAsync? _instance;
  SharedPreferencesAsync get _storage => _instance ??= SharedPreferencesAsync();
  static String key(bool published) => published
      ? 'farmacia_jae.promotions.public.v1'
      : 'farmacia_jae.promotions.editor.v1';
  @override
  Future<String?> read({bool published = false}) =>
      _storage.getString(key(published));
  @override
  Future<void> write(String data, {bool published = false}) =>
      _storage.setString(key(published), data);
}

class MemoryPromotionStore implements PromotionStore {
  MemoryPromotionStore({this.editorData, this.publicData});
  String? editorData, publicData;
  @override
  Future<String?> read({bool published = false}) async =>
      published ? publicData : editorData;
  @override
  Future<void> write(String data, {bool published = false}) async {
    if (published) {
      publicData = data;
    } else {
      editorData = data;
    }
  }
}
