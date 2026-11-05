import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_paths.dart';
import '../../../shared/widgets/adaptive_grid.dart';
import '../../products/widgets/product_thumbnail.dart';
import '../widgets/presentation_shell.dart';
import '../widgets/public_editorial.dart';
import '../models/public_articles.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({this.category, super.key});
  final String? category;
  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late String _category;
  String _search = '';
  @override
  void initState() {
    super.initState();
    _category = widget.category ?? 'Todas';
  }

  @override
  void didUpdateWidget(covariant ServicesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _category = widget.category ?? 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = publicArticles
        .where(
          (p) =>
              (_category == 'Todas' || p.category == _category) &&
              '${p.name} ${p.ingredient} ${p.strength} ${p.pack}'
                  .toLowerCase()
                  .contains(_search),
        )
        .toList();
    return PresentationShell(
      path: AppPaths.presentationServices,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PublicTitle(
            eyebrow: 'Productos y atención',
            title: 'Encuentra tu área de cuidado.',
            description:
                'Explora una selección de artículos y sus presentaciones. Consulta disponibilidad, precio y condiciones de dispensación directamente en la farmacia.',
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('public-product-search'),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre, concentración o presentación',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in [
                'Todas',
                'Medicamentos',
                'Cuidado personal',
                'Vitaminas y bienestar',
                'Primeros auxilios',
              ])
                ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_category == 'Cuidado personal')
            LayoutBuilder(
              builder: (context, box) {
                const image = PublicPhoto(
                  asset: 'images/promotions/cuidado.jpg',
                  label: 'Selección de productos de cuidado personal',
                  height: 250,
                );
                final text = Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu rutina también merece cuidado.',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: PublicStyle.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Higiene, cuidado corporal y artículos de uso diario. Consulta las marcas y presentaciones disponibles al visitarnos.',
                        style: TextStyle(height: 1.7, color: PublicStyle.muted),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            context.go(AppPaths.presentationContact),
                        child: const Text('Consultar en la farmacia →'),
                      ),
                    ],
                  ),
                );
                return box.maxWidth < 650
                    ? Column(children: [image, text])
                    : Row(
                        children: [
                          const Expanded(child: image),
                          Expanded(child: text),
                        ],
                      );
              },
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No hay artículos que coincidan. Prueba otro nombre o categoría.',
              ),
            )
          else
            AdaptiveGrid(
              minItemWidth: 260,
              maxColumns: 3,
              children: [
                for (final article in items)
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xffdde7e0)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProductThumbnail(
                            illustrationKey: article.image,
                            height: 130,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            article.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: PublicStyle.green,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${article.name} ${article.strength}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: PublicStyle.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            article.pack,
                            style: const TextStyle(
                              fontSize: 12,
                              color: PublicStyle.muted,
                            ),
                          ),
                          const Divider(height: 24, color: Color(0xffe0e9e3)),
                          TextButton.icon(
                            key: Key('public-article-${article.image}'),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Text(
                                  '${article.name} ${article.strength}',
                                ),
                                scrollable: true,
                                content: SizedBox(
                                  width: 420,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ProductThumbnail(
                                        illustrationKey: article.image,
                                        height: 160,
                                      ),
                                      const SizedBox(height: 18),
                                      SelectableText(
                                        'Categoría: ${article.category}\nComponente: ${article.ingredient}\nConcentración / contenido: ${article.strength}\nPresentación: ${article.pack}',
                                        style: const TextStyle(
                                          height: 1.9,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'La información identifica el artículo. Consulta el prospecto y al personal de la farmacia sobre su dispensación.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: PublicStyle.muted,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cerrar'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      context.go(AppPaths.presentationContact);
                                    },
                                    child: const Text('Consultar en farmacia'),
                                  ),
                                ],
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 15),
                            label: const Text('Ver presentación'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 28),
          const PublicVisitBanner(),
        ],
      ),
    );
  }
}
