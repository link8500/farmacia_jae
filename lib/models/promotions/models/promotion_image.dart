/// Fotografías editoriales locales con claves estables para los respaldos.
abstract final class PromotionImages {
  static const values = <String, ({String name, String asset})>{
    'campana-bienestar': (
      name: 'Bienestar y vitaminas',
      asset: 'images/promotions/bienestar.jpg',
    ),
    'campana-botiquin': (
      name: 'Botiquín familiar',
      asset: 'images/promotions/botiquin.jpg',
    ),
    'campana-cuidado': (
      name: 'Cuidado e higiene',
      asset: 'images/promotions/cuidado.jpg',
    ),
  };
}
