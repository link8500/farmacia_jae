import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/settings/models/app_preferences.dart';
import 'preferences_store.dart';

/// Preferencias personales aisladas por ID, con escrituras serializadas.
/// El documento v2 guarda perfiles, no credenciales, sesión ni datos operativos.
class PreferencesController extends ChangeNotifier {
  PreferencesController(this._store);
  final PreferencesStore _store;
  final Map<String, AppPreferences> _profiles = {};
  final Set<String> _edited = {};
  String _owner = 'guest';
  String? get accountId => _owner == 'guest' ? null : _owner.substring(5);
  AppPreferences get value => _profiles[_owner] ?? const AppPreferences();
  bool isLoaded = false;
  bool get isSaving => _pending > 0;
  String? storageError;
  int _pending = 0;
  int _revision = 0;
  bool _disposed = false;
  Future<void>? _initialization;
  Future<void> _writes = Future.value();

  /// El login usa guest; cambiar de usuario no hereda sus ajustes. No carga
  /// almacenamiento aquí: la presentación pública debe permanecer independiente.
  void useAccount(String? id) {
    final owner = id == null ? 'guest' : 'user:$id';
    if (_disposed || _owner == owner) return;
    _owner = owner;
    notifyListeners();
  }

  /// Carga una vez, solo al abrir login/administración, nunca la presentación.
  Future<void> initialize() => _initialization ??= _load();
  Future<void> _load() async {
    try {
      final raw = await _store.read();
      if (_disposed) return;
      if (raw != null) {
        try {
          final json = jsonDecode(raw);
          final saved = <String, AppPreferences>{};
          if (json is Map<String, dynamic> &&
              json['version'] == 2 &&
              json['profiles'] is Map) {
            final profiles = json['profiles'] as Map;
            if (profiles.length > 5000) {
              throw const FormatException('Demasiados perfiles');
            }
            for (final entry in profiles.entries) {
              if (entry.key is String &&
                  (entry.key == 'guest' ||
                      (entry.key as String).startsWith('user:')) &&
                  entry.value is Map<String, dynamic>) {
                saved[entry.key as String] = AppPreferences.fromJson(
                  entry.value as Map<String, dynamic>,
                );
              }
            }
          } else if (json is Map<String, dynamic> && json['version'] == 1) {
            // El formato anterior era global: no se adivina su propietario.
            saved['guest'] = AppPreferences.fromJson(json);
          }
          for (final entry in saved.entries) {
            if (!_edited.contains(entry.key)) {
              _profiles[entry.key] = entry.value;
            }
          }
        } on FormatException {
          /* Los datos corruptos no bloquean el acceso. */
        }
      }
    } catch (_) {
      if (!_disposed) {
        storageError =
            'No se pudo leer el almacenamiento local. Puedes usar los ajustes durante esta sesión.';
      }
    }
    if (!_disposed) {
      isLoaded = true;
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) => _apply(value.copyWith(themeMode: mode));
  void setTextSize(AppTextSize size) => _apply(value.copyWith(textSize: size));
  void setAccent(AppAccent accent) => _apply(value.copyWith(accent: accent));
  void setCatalogLayout(CatalogLayout layout) =>
      _apply(value.copyWith(catalogLayout: layout));
  void setDensity(WorkspaceDensity density) =>
      _apply(value.copyWith(density: density));
  void setHighContrast(bool enabled) =>
      _apply(value.copyWith(highContrast: enabled));
  void setReduceMotion(bool enabled) =>
      _apply(value.copyWith(reduceMotion: enabled));
  void setConfirmClearSale(bool enabled) =>
      _apply(value.copyWith(confirmClearSale: enabled));
  void setNotificationBadges(bool enabled) =>
      _apply(value.copyWith(showNotificationBadges: enabled));
  void restoreDefaults() => _apply(const AppPreferences());
  void retrySave() => _apply(value);

  void _apply(AppPreferences value) {
    if (_disposed) return;
    _profiles[_owner] = value;
    _edited.add(_owner);
    storageError = null;
    final revision = ++_revision;
    _pending++;
    notifyListeners();
    _writes = _writes.then((_) async {
      // Primero recuperar perfiles no leídos, luego guardar el mapa completo.
      await initialize();
      try {
        await _store.write(
          jsonEncode({
            'version': 2,
            'profiles': {
              for (final entry in _profiles.entries)
                entry.key: entry.value.toJson(),
            },
          }),
        );
        if (!_disposed && revision == _revision) storageError = null;
      } catch (_) {
        if (!_disposed && revision == _revision) {
          storageError =
              'El ajuste se aplicó, pero no se pudo guardar. Se perderá al recargar si no reintentas.';
        }
      } finally {
        _pending--;
        if (!_disposed) notifyListeners();
      }
    });
  }

  /// Punto de sincronización para pruebas y guardados pendientes, no para UI.
  Future<void> flush() => _writes;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
