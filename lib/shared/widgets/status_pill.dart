import 'package:flutter/material.dart';

/// Etiqueta compacta para estados como "Disponible", "Por vencer" o "Pendiente".
class StatusPill extends StatelessWidget {
  /// Crea una etiqueta con texto y color configurables.
  const StatusPill({required this.text, required this.color, super.key});

  /// Texto corto que se mostrará dentro de la etiqueta.
  final String text;

  /// Color semántico del estado.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
