import 'package:flutter/material.dart';
import '../themes/app_palette.dart';

/// Tarjeta de indicador reutilizable para dashboards y reportes.
class StatCard extends StatelessWidget {
  /// Crea una tarjeta con etiqueta, valor, detalle e icono.
  const StatCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.background,
    this.width = 220,
    super.key,
  });

  /// Nombre del indicador.
  final String label;

  /// Valor principal del indicador.
  final String value;

  /// Variación o explicación secundaria.
  final String detail;

  /// Icono del indicador.
  final IconData icon;

  /// Color principal del indicador.
  final Color color;

  /// Fondo suave del icono.
  final Color background;

  /// Ancho deseado de la tarjeta.
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        detail,
                        maxLines: 2,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: detail.contains('%')
                              ? AppColors.green
                              : context.palette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                label,
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
