import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';

/// Plantilla para módulos operativos que compartirán tablas y formularios.
///
/// Compras, proveedores y clientes se mantienen separados en navegación, pero
/// pueden evolucionar desde esta base sin duplicar la estructura visual.
class InfoPage extends StatelessWidget {
  /// Crea una página informativa para un módulo operativo.
  const InfoPage({required this.title, required this.pageIndex, super.key});

  /// Nombre visible del módulo.
  final String title;

  /// Índice utilizado para elegir la descripción contextual.
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final description = pageIndex == 3
        ? 'Controla tus entradas de mercancía y proveedores.'
        : 'Consulta contactos e historial de compras.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: title,
            description: description,
            action: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo registro'),
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar ${title.toLowerCase()}',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.blue,
                  ),
                  title: Text('Registro listo para usar'),
                  subtitle: Text(
                    'Aquí podrás consultar, crear y actualizar registros.',
                  ),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.analytics_outlined,
                    color: AppColors.green,
                  ),
                  title: Text('Información organizada'),
                  subtitle: Text(
                    'Los movimientos quedan asociados al usuario y a la fecha.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
