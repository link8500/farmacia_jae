/// Valores iniciales del catálogo compartido entre sucursales. Administración
/// puede agregar opciones sin tener que editar una ficha de producto.
enum ProductClassification {
  category('Categoría', 'Categorías', [
    'Analgésicos',
    'Antialérgicos',
    'Antibióticos',
    'Antiinflamatorios',
    'Antisépticos',
    'Cardiovascular',
    'Cuidado personal',
    'Dermatología',
    'Gastrointestinal',
    'Material de curación',
    'Respiratorio',
    'Vitaminas',
    'Otros productos',
  ]),
  presentation('Presentación', 'Presentaciones', [
    'Tabletas / pastillas',
    'Tabletas masticables',
    'Tabletas efervescentes',
    'Tabletas sublinguales',
    'Cápsulas',
    'Cápsulas blandas',
    'Gomas / gomitas',
    'Pastillas para chupar',
    'Jarabe',
    'Solución oral',
    'Suspensión oral',
    'Polvo para suspensión',
    'Gotas orales',
    'Gotas oftálmicas',
    'Gotas óticas',
    'Crema',
    'Gel',
    'Pomada',
    'Loción',
    'Solución tópica',
    'Espuma',
    'Champú',
    'Jabón',
    'Polvo / granulado',
    'Sobres',
    'Inyectable',
    'Aerosol',
    'Spray nasal',
    'Inhalador',
    'Solución para nebulizar',
    'Supositorio',
    'Óvulo',
    'Parche',
    'Gasa / apósito',
    'Otro',
  ]);

  const ProductClassification(this.label, this.plural, this.defaults);

  final String label, plural;
  final List<String> defaults;

  static String clean(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ');

  static bool validName(String name) => name.isNotEmpty && name.length <= 64;
}
