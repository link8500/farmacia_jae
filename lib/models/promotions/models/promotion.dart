import '../../../core/utils/json_value.dart';
import '../../products/models/product_illustration.dart';
import 'promotion_image.dart';

enum PromotionStatus {
  draft('Borrador'),
  published('Publicada'),
  archived('Archivada');

  const PromotionStatus(this.label);
  final String label;
}

/// Contenido editorial, independiente del catálogo operativo. Una promoción
/// no aplica descuentos, cambia precios ni reserva existencias en facturación.
class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    this.badge = 'Novedad',
    this.conditions = '',
    this.illustrationKey = '',
    this.status = PromotionStatus.draft,
  });
  final String id, title, description, badge, conditions, illustrationKey;
  final DateTime startsAt, endsAt;
  final PromotionStatus status;
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  bool isVisible(DateTime today) =>
      status == PromotionStatus.published &&
      !day(today).isBefore(day(startsAt)) &&
      !day(today).isAfter(day(endsAt));
  String phase(DateTime today) {
    if (status != PromotionStatus.published) return status.label;
    if (day(today).isBefore(day(startsAt))) return 'Programada';
    if (day(today).isAfter(day(endsAt))) return 'Finalizada';
    return 'Activa';
  }

  String? validate() {
    if (title.trim().isEmpty || title.trim().length > 100) {
      return 'Indica un título de hasta 100 caracteres.';
    }
    if (description.trim().isEmpty || description.trim().length > 600) {
      return 'Indica una descripción de hasta 600 caracteres.';
    }
    if (badge.trim().isEmpty || badge.trim().length > 32) {
      return 'La etiqueta debe tener entre 1 y 32 caracteres.';
    }
    if (conditions.length > 1500) {
      return 'Las condiciones no pueden superar 1500 caracteres.';
    }
    if (day(endsAt).isBefore(day(startsAt))) {
      return 'La fecha final no puede ser anterior al inicio.';
    }
    if (illustrationKey.isNotEmpty &&
        !PromotionImages.values.containsKey(illustrationKey) &&
        ProductIllustrations.find(illustrationKey) == null) {
      return 'Selecciona una ilustración del catálogo local.';
    }
    return null;
  }

  Promotion withIdentity(String value, {PromotionStatus? status}) => Promotion(
    id: value,
    title: title.trim(),
    description: description.trim(),
    badge: badge.trim(),
    conditions: conditions.trim(),
    startsAt: day(startsAt),
    endsAt: day(endsAt),
    illustrationKey: illustrationKey,
    status: status ?? this.status,
  );
  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'badge': badge,
    'conditions': conditions,
    'illustrationKey': illustrationKey,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'status': status.name,
  };
  factory Promotion.fromJson(JsonMap json) {
    final item = Promotion(
      id: jsonText(json, 'id'),
      title: jsonText(json, 'title'),
      description: jsonText(json, 'description'),
      badge: jsonText(json, 'badge'),
      conditions: jsonText(json, 'conditions'),
      illustrationKey: jsonText(json, 'illustrationKey'),
      startsAt: jsonDate(json, 'startsAt'),
      endsAt: jsonDate(json, 'endsAt'),
      status: jsonEnum(json, 'status', PromotionStatus.values),
    );
    if (!RegExp(r'^promo-\d+$').hasMatch(item.id) || item.validate() != null) {
      throw const FormatException('Promoción no válida.');
    }
    return item;
  }
}
