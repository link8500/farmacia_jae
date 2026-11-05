import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../widgets/data_tools.dart';

/// Herramientas de administración, separadas de las preferencias personales.
class SystemToolsPage extends StatelessWidget {
  const SystemToolsPage({
    required this.controller,
    required this.onPreferences,
    super.key,
  });
  final PharmacyController controller;
  final VoidCallback onPreferences;
  @override
  Widget build(BuildContext context) {
    if (!controller.isAdministrator) {
      return const Center(
        child: Text('Este apartado requiere administración.'),
      );
    }
    return CompactWorkspace(
      title: 'Datos y mantenimiento',
      subtitle: 'Conserva respaldos y recupera los datos de este navegador.',
      actions: [
        OutlinedButton.icon(
          onPressed: onPreferences,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Ir a mis preferencias'),
        ),
      ],
      child: SingleChildScrollView(child: DataTools(controller: controller)),
    );
  }
}
