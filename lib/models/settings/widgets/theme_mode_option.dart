import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';

/// Opción de tema reutilizable, con selección comunicada por texto y semántica.
class ThemeModeOption extends StatelessWidget {
  const ThemeModeOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label, description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Tema $label',
    child: Material(
      color: selected ? context.palette.paleBlue : context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? context.palette.blue : context.palette.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? context.palette.blue : context.palette.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? context.palette.blue : context.palette.muted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
