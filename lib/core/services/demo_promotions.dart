import '../../models/promotions/models/promotion.dart';

/// Campañas ficticias con fechas relativas a su instalación. No aplican
/// descuentos automáticos ni modifican los precios operativos.
abstract final class DemoPromotions {
  static List<Promotion> build(DateTime now) {
    final day = Promotion.day(now);
    return [
      Promotion(
        id: 'promo-900001',
        title: 'Semana del bienestar',
        badge: 'Hasta 10%',
        description:
            'Una selección de vitaminas y artículos de bienestar para completar tu rutina de cuidado.',
        conditions:
            'Promoción ficticia. Selección y existencias sujetas a consulta en sucursal. La imagen es ilustrativa; no indica marcas disponibles. No aplica descuentos automáticos en facturación.',
        illustrationKey: 'campana-bienestar',
        status: PromotionStatus.published,
        startsAt: day.subtract(const Duration(days: 3)),
        endsAt: day.add(const Duration(days: 27)),
      ),
      Promotion(
        id: 'promo-900002',
        title: 'Tu botiquín, siempre preparado',
        badge: 'Combo familiar',
        description:
            'Prepara tu botiquín con artículos de curación y cuidado básico: consulta las opciones del mes en la farmacia.',
        conditions:
            'Campaña ficticia. El contenido del combo se confirma en sucursal. La foto es ilustrativa y no determina los artículos incluidos.',
        illustrationKey: 'campana-botiquin',
        status: PromotionStatus.published,
        startsAt: day.subtract(const Duration(days: 2)),
        endsAt: day.add(const Duration(days: 21)),
      ),
      Promotion(
        id: 'promo-900003',
        title: 'Pequeños hábitos, gran cuidado',
        badge: 'Cuidado diario',
        description:
            'Encuentra una selección de artículos de higiene y cuidado personal para tu día a día.',
        conditions:
            'Contenido editorial. Marcas, precios y disponibilidad se consultan en sucursal. La fotografía no representa el inventario real.',
        illustrationKey: 'campana-cuidado',
        status: PromotionStatus.published,
        startsAt: day.subtract(const Duration(days: 1)),
        endsAt: day.add(const Duration(days: 35)),
      ),
      Promotion(
        id: 'promo-900004',
        title: 'Fin de semana de cuidado familiar',
        badge: 'Próximamente',
        description:
            'Una campaña especial de artículos de higiene para toda la familia.',
        conditions:
            'Ejemplo programado: se mostrará al llegar la fecha de inicio.',
        illustrationKey: 'campana-cuidado',
        status: PromotionStatus.published,
        startsAt: day.add(const Duration(days: 7)),
        endsAt: day.add(const Duration(days: 14)),
      ),
      Promotion(
        id: 'promo-900005',
        title: 'Renueva tu botiquín',
        badge: 'En preparación',
        description:
            'Borrador de campaña para revisar los artículos de curación del hogar.',
        conditions: 'Borrador. Pendiente de revisión y publicación.',
        illustrationKey: 'campana-botiquin',
        startsAt: day,
        endsAt: day.add(const Duration(days: 30)),
      ),
    ];
  }
}
