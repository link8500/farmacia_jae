import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';

/// Marco reutilizable de cada grupo de preferencias; sin lógica de guardado.
class PreferencesSection extends StatelessWidget {
  const PreferencesSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    super.key,
  });
  final String title, description;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.palette.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

/// Interruptor accesible con explicación del efecto real, no un control simulado.
class PreferenceToggle extends StatelessWidget {
  const PreferenceToggle({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String title, description;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: onChanged,
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        description,
        style: TextStyle(
          color: context.palette.muted,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    ),
  );
}
