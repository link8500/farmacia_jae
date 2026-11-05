import 'package:flutter/material.dart';
import 'page_header.dart';
import 'section_card.dart';
import '../themes/app_palette.dart';

/// Marco adaptable para vistas operativas; evita duplicar cabeceras y márgenes.
class AdministrationPage extends StatelessWidget {
  const AdministrationPage({
    required this.title,
    required this.description,
    required this.children,
    this.action,
    super.key,
  });
  final String title, description;
  final Widget? action;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: title, description: description, action: action),
        const SizedBox(height: 16),
        for (final child in children)
          Padding(padding: const EdgeInsets.only(bottom: 14), child: child),
      ],
    ),
  );
}

class OperationCard extends StatelessWidget {
  const OperationCard({
    required this.title,
    required this.subtitle,
    this.details = const [],
    this.actions = const [],
    super.key,
  });
  final String title, subtitle;
  final List<Widget> details, actions;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: context.palette.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        if (details.isNotEmpty) ...[const SizedBox(height: 14), ...details],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 8, children: actions),
        ],
      ],
    ),
  );
}
