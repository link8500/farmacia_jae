import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/promotions/models/promotion.dart';
import '../utils/json_value.dart';
import '../utils/legacy_interface_text.dart';
import 'promotion_store.dart';
import 'demo_promotions.dart';

/// Conserva la identidad incluso si se guardó el editor y falló la publicación.
/// Reintentar desde el formulario actualiza el mismo registro, sin duplicarlo.
class PromotionSaveResult {
  const PromotionSaveResult({this.id, this.error});
  final String? id, error;
}

/// Publicación LOCAL para el prototipo. Los comandos comprueban permisos, y
/// las pantallas públicas reciben únicamente contenido publicado y vigente.
/// No hay sincronización entre navegadores ni un servidor de publicaciones.
class PromotionsController extends ChangeNotifier {
  PromotionsController({
    required this.store,
    required this._canManage,
    DateTime Function()? clock,
    this.seedDemo = false,
  }) : _clock = clock ?? DateTime.now;
  final PromotionStore store;
  final bool Function() _canManage;
  final DateTime Function() _clock;
  final bool seedDemo;
  List<Promotion> _entries = [], _published = [];
  Future<void>? _publicLoad, _editorLoad;
  bool publicLoaded = false,
      editorLoaded = false,
      isSaving = false,
      publishPending = false,
      _disposed = false;
  String? publicError, editorError, storageError;
  int _revision = 0;
  DateTime get today => Promotion.day(_clock());
  bool get canManage => _canManage();
  List<Promotion> get entries =>
      canManage ? List.unmodifiable(_entries) : const [];
  List<Promotion> get visible => List.unmodifiable(
    _published.where((p) => p.isVisible(today)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt)),
  );
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static List<Promotion> _decode(String? raw) {
    if (raw == null) return [];
    final json = cleanLegacyInterfaceDocument(jsonObject(jsonDecode(raw)));
    if (json['version'] != 1) {
      throw const FormatException('Versión de promociones no compatible.');
    }
    final list = jsonList(json, 'promotions', Promotion.fromJson);
    if (list.map((p) => p.id).toSet().length != list.length) {
      throw const FormatException('Identificadores repetidos.');
    }
    return list;
  }

  static String _encode(List<Promotion> values) => jsonEncode({
    'version': 1,
    'promotions': values.map((p) => p.toJson()).toList(),
  });

  Future<void> loadPublic({bool retry = false}) {
    if (retry) _publicLoad = null;
    return _publicLoad ??= _readPublic();
  }

  Future<void> _readPublic() async {
    final revision = _revision;
    try {
      final raw = await store.read(published: true);
      final list = raw == null && seedDemo
          ? DemoPromotions.build(today)
          : _decode(raw);
      if (_disposed || revision != _revision) return;
      _published = list
          .where((p) => p.status == PromotionStatus.published)
          .toList();
      publicLoaded = true;
      publicError = null;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      publicError =
          'No se pudieron cargar las promociones. Reintenta la consulta.';
    }
    _notify();
  }

  Future<void> loadEditor({bool retry = false}) {
    if (!canManage) return Future.value();
    if (retry) _editorLoad = null;
    return _editorLoad ??= _readEditor();
  }

  Future<void> _readEditor() async {
    try {
      var list = _decode(await store.read());
      final additions = seedDemo
          ? DemoPromotions.build(
              today,
            ).where((p) => !list.any((old) => old.id == p.id)).toList()
          : <Promotion>[];
      if (_disposed || !canManage) return;
      if (additions.isNotEmpty) {
        // Añade solo IDs demo ausentes; una campaña editada o archivada se
        // conserva. Las fechas de instalación se guardan una sola vez.
        list = [...list, ...additions];
        await store.write(_encode(list));
      }
      if (_disposed || !canManage) return;
      _entries = list;
      editorLoaded = true;
      editorError = null;
      try {
        final published = _decode(await store.read(published: true));
        if (_disposed || !canManage) return;
        publishPending =
            _encode(published) !=
            _encode(
              _entries
                  .where((p) => p.status == PromotionStatus.published)
                  .toList(),
            );
        storageError = publishPending
            ? 'Hay cambios guardados que todavía no aparecen en la vista pública.'
            : null;
      } catch (_) {
        publishPending = true;
        storageError =
            'El editor se recuperó. Reintenta la publicación para actualizar la vista pública.';
      }
      if (additions.isNotEmpty) await _publish();
    } catch (_) {
      if (_disposed) return;
      editorError =
          'No se pudo leer el contenido guardado. No se sobrescribirá; reintenta la carga.';
    }
    _notify();
  }

  String? get _denied => _disposed || !canManage
      ? 'Solo administración puede gestionar promociones.'
      : !editorLoaded || editorError != null
      ? 'Primero recupera las promociones guardadas.'
      : isSaving
      ? 'Hay un guardado en curso.'
      : null;

  Future<PromotionSaveResult> save(Promotion draft) async {
    final denied = _denied;
    if (denied != null) return PromotionSaveResult(error: denied);
    final invalid = draft.validate();
    if (invalid != null) return PromotionSaveResult(error: invalid);
    if (draft.id.isNotEmpty && !_entries.any((p) => p.id == draft.id)) {
      return const PromotionSaveResult(
        error: 'La promoción ya no está disponible.',
      );
    }
    var sequence = _entries.length + 1;
    while (_entries.any((p) => p.id == 'promo-$sequence')) {
      sequence++;
    }
    final item = draft.withIdentity(
      draft.id.isEmpty ? 'promo-$sequence' : draft.id,
    );
    final next = [..._entries.where((p) => p.id != item.id), item];
    isSaving = true;
    storageError = null;
    _notify();
    try {
      await store.write(_encode(next));
      if (_disposed) {
        return PromotionSaveResult(
          id: item.id,
          error: 'El editor ya se cerró.',
        );
      }
      _entries = next;
      if (!canManage) {
        publishPending = true;
        storageError =
            'La sesión cambió. Un administrador debe completar la publicación.';
        return PromotionSaveResult(id: item.id, error: storageError);
      }
      return PromotionSaveResult(id: item.id, error: await _publish());
    } catch (_) {
      storageError =
          'No se guardaron los cambios. Reintenta sin cerrar el formulario.';
      return PromotionSaveResult(error: storageError);
    } finally {
      isSaving = false;
      _notify();
    }
  }

  Future<String?> _publish() async {
    final projection = _entries
        .where((p) => p.status == PromotionStatus.published)
        .toList();
    try {
      await store.write(_encode(projection), published: true);
      if (_disposed) return 'El editor ya se cerró.';
      _revision++;
      _published = projection;
      publicLoaded = true;
      publicError = null;
      publishPending = false;
      storageError = null;
      return null;
    } catch (_) {
      publishPending = true;
      return storageError =
          'El borrador se guardó, pero la vista pública no se actualizó. Reintenta la publicación.';
    }
  }

  Future<String?> retryPublication() async {
    final denied = _denied;
    if (denied != null) return denied;
    isSaving = true;
    _notify();
    try {
      return await _publish();
    } finally {
      isSaving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
