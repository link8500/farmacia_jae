import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/promotion_store.dart';
import 'package:farmacia_sae/core/services/promotions_controller.dart';
import 'package:farmacia_sae/models/promotions/models/promotion.dart';

class RecordingPromotionStore extends MemoryPromotionStore {
  RecordingPromotionStore({super.editorData, super.publicData});
  final reads = <bool>[], writes = <bool>[];
  bool failPublic = false, failPrivate = false;
  @override
  Future<String?> read({bool published = false}) async {
    reads.add(published);
    return super.read(published: published);
  }

  @override
  Future<void> write(String data, {bool published = false}) async {
    writes.add(published);
    if (published ? failPublic : failPrivate) {
      throw StateError('Storage unavailable');
    }
    return super.write(data, published: published);
  }
}

void main() {
  final today = DateTime(2026, 10, 27);
  Promotion promotion({
    String id = '',
    PromotionStatus status = PromotionStatus.published,
    DateTime? start,
    DateTime? end,
    String title = 'Campaña confirmada',
  }) => Promotion(
    id: id,
    title: title,
    description: 'Contenido de prueba',
    startsAt: start ?? today,
    endsAt: end ?? today,
    status: status,
  );
  String encode(List<Promotion> list) => jsonEncode({
    'version': 1,
    'promotions': list.map((p) => p.toJson()).toList(),
  });
  PromotionsController controller(
    PromotionStore store, {
    bool Function()? allowed,
  }) {
    final data = PromotionsController(
      store: store,
      canManage: allowed ?? () => true,
      clock: () => today,
    );
    addTearDown(data.dispose);
    return data;
  }

  test(
    'publicar, editar y archivar actualiza la proyección pública sin borrar el historial',
    () async {
      final store = RecordingPromotionStore(),
          data = controller(RecordingPromotionStore());
      final editor = controller(store);
      await editor.loadEditor();
      final result = await editor.save(promotion());
      expect(result.error, isNull);
      expect(result.id, 'promo-1');
      expect(editor.visible.single.title, 'Campaña confirmada');
      await editor.save(promotion(id: result.id!, title: 'Nombre corregido'));
      expect(editor.entries.length, 1);
      expect(editor.visible.single.title, 'Nombre corregido');
      expect(
        (await editor.save(
          promotion(id: result.id!, status: PromotionStatus.archived),
        )).error,
        isNull,
      );
      expect(editor.visible, isEmpty);
      expect(editor.entries.single.status, PromotionStatus.archived);
      expect(store.publicData, isNot(contains('Nombre corregido')));
      expect(data.entries, isEmpty);
    },
  );
  test(
    'consulta pública no abre borradores y filtra vigencia inclusiva',
    () async {
      final store = RecordingPromotionStore(
        editorData: encode([
          promotion(
            id: 'promo-9',
            status: PromotionStatus.draft,
            title: 'Privado',
          ),
        ]),
        publicData: encode([
          promotion(id: 'promo-1'),
          promotion(
            id: 'promo-2',
            start: today.add(const Duration(days: 1)),
            end: today.add(const Duration(days: 3)),
          ),
          promotion(
            id: 'promo-3',
            start: today.subtract(const Duration(days: 3)),
            end: today.subtract(const Duration(days: 1)),
          ),
        ]),
      );
      final data = controller(store, allowed: () => false);
      await data.loadPublic();
      await data.loadEditor();
      expect(store.reads, [true]);
      expect(data.visible.map((p) => p.id), ['promo-1']);
      expect(data.entries, isEmpty);
      expect((await data.save(promotion())).error, isNotNull);
      expect(store.writes, isEmpty);
    },
  );
  test(
    'guardar un borrador no lo publica; fechas y contenido inválidos no se guardan',
    () async {
      final store = RecordingPromotionStore(), data = controller(store);
      expect((await data.save(promotion())).error, isNotNull);
      await data.loadEditor();
      expect(
        (await data.save(promotion(status: PromotionStatus.draft))).error,
        isNull,
      );
      expect(data.visible, isEmpty);
      expect(store.publicData, isNot(contains('Campaña confirmada')));
      final writes = store.writes.length;
      expect((await data.save(promotion(title: ' '))).error, isNotNull);
      expect(
        (await data.save(
          promotion(end: today.subtract(const Duration(days: 1))),
        )).error,
        isNotNull,
      );
      expect(store.writes.length, writes);
    },
  );
  test(
    'fallo de publicación conserva identidad y se puede recuperar tras reiniciar',
    () async {
      final store = RecordingPromotionStore(), data = controller(store);
      await data.loadEditor();
      store.failPublic = true;
      final failed = await data.save(promotion());
      expect(failed.error, isNotNull);
      expect(failed.id, isNotNull);
      expect(data.entries.length, 1);
      expect(data.visible, isEmpty);
      expect(data.publishPending, isTrue);
      expect((await data.save(promotion(id: failed.id!))).id, failed.id);
      expect(data.entries.length, 1);
      final reopened = controller(store);
      await reopened.loadEditor();
      expect(reopened.publishPending, isTrue);
      store.failPublic = false;
      expect(await reopened.retryPublication(), isNull);
      expect(reopened.visible.single.id, failed.id);
      expect(reopened.publishPending, isFalse);
      final public = controller(store, allowed: () => false);
      await public.loadPublic();
      expect(public.visible.single.id, failed.id);
    },
  );
  test(
    'fallo de lectura privada no permite sobrescribir contenido desconocido',
    () async {
      final store = RecordingPromotionStore(editorData: '{malformed');
      final data = controller(store);
      await data.loadEditor();
      expect(data.editorLoaded, isFalse);
      expect(data.editorError, isNotNull);
      expect((await data.save(promotion())).error, isNotNull);
      expect(store.writes, isEmpty);
      store.editorData = encode([]);
      await data.loadEditor(retry: true);
      expect(data.editorLoaded, isTrue);
      expect(data.editorError, isNull);
    },
  );
  test(
    'fallo de guardado privado conserva los datos anteriores y no publica',
    () async {
      final store = RecordingPromotionStore(), data = controller(store);
      await data.loadEditor();
      store.failPrivate = true;
      expect((await data.save(promotion())).error, isNotNull);
      expect(data.entries, isEmpty);
      expect(store.writes, [false]);
      store.failPrivate = false;
      expect((await data.save(promotion())).error, isNull);
    },
  );
  test('cambio de permisos bloquea mutaciones posteriores', () async {
    var allowed = true;
    final store = RecordingPromotionStore(),
        data = controller(store, allowed: () => allowed);
    await data.loadEditor();
    await data.save(promotion());
    allowed = false;
    expect(data.entries, isEmpty);
    expect((await data.save(promotion())).error, isNotNull);
    expect(await data.retryPublication(), isNotNull);
    expect(store.writes.length, 2);
  });
}
