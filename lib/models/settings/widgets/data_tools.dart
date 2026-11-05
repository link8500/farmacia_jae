import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/services/local_files.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import 'preferences_section.dart';

/// Respaldo e importación solo local. No sube archivos ni limpia preferencias.
class DataTools extends StatelessWidget {
  const DataTools({required this.controller, super.key});
  final PharmacyController controller;
  Future<void> _restore(BuildContext context) async {
    String? raw;
    try {
      raw = await selectBackupFile();
    } catch (_) {
      if (context.mounted) {
        showCommandResult(
          context,
          'No se pudo leer el archivo. Usa un respaldo JSON de hasta 5 MB.',
        );
      }
      return;
    }
    if (raw == null || !context.mounted) return;
    await confirmCommand(
      context,
      '¿Reemplazar los datos locales?',
      'Se sustituirán sucursales, personal, asignaciones, productos, lotes, contactos, compras, ventas, caja e historial de este navegador. Exporta antes tu respaldo actual. Las preferencias personales no cambian; las cuentas y sus asignaciones se recuperan del respaldo.',
      () => controller.restoreBackup(raw!),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => PreferencesSection(
      title: 'Datos locales y respaldos',
      description:
          'Solo este navegador. No hay sincronización ni una base de datos de servidor.',
      icon: Icons.storage_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.loadFailed
                ? 'Lectura fallida: operaciones bloqueadas para proteger los datos existentes.'
                : controller.isSaving
                ? 'Guardando cambios…'
                : 'Datos disponibles en este navegador.',
          ),
          if (controller.lastSavedAt != null)
            Text(
              'Último guardado: ${formatDate(controller.lastSavedAt!)} · ${controller.lastSavedAt!.hour.toString().padLeft(2, '0')}:${controller.lastSavedAt!.minute.toString().padLeft(2, '0')}',
            ),
          if (controller.storageError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(controller.storageError!),
            ),
          const SizedBox(height: 16),
          if (controller.hasDemoHistory)
            const Text(
              'Historial vinculado disponible: ventas, clientes, proveedores, compras, lotes y sucursales.',
            ),
          if (controller.demoDataError != null) Text(controller.demoDataError!),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (controller.isAdministrator &&
                  !controller.hasDemoHistory &&
                  !controller.loadFailed)
                OutlinedButton.icon(
                  onPressed: () =>
                      showCommandResult(context, controller.addDemoHistory()),
                  icon: const Icon(Icons.dataset_outlined),
                  label: const Text('Añadir historial'),
                ),
              if (!controller.loadFailed)
                OutlinedButton.icon(
                  onPressed: () {
                    final raw = controller.createBackup();
                    if (!downloadText(
                      'farmacia-jae-respaldo-${controller.today.toIso8601String().substring(0, 10)}.json',
                      raw,
                      type: 'application/json;charset=utf-8',
                    )) {
                      showCommandResult(
                        context,
                        'La descarga está disponible en la versión web.',
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar respaldo JSON'),
                ),
              if (controller.isAdministrator)
                OutlinedButton.icon(
                  onPressed: () => _restore(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Restaurar archivo JSON'),
                ),
              if (controller.isAdministrator)
                TextButton(
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => RecordFormDialog(
                      title: 'Restaurar JSON copiado',
                      description:
                          'Reemplaza todo el estado local. Guarda primero tu respaldo actual; el documento debe ser un respaldo completo y válido.',
                      fields: const [
                        RecordField(
                          'backup-json',
                          'Contenido JSON del respaldo',
                          lines: 8,
                        ),
                      ],
                      saveLabel: 'Validar y restaurar',
                      onSave: (v) =>
                          controller.restoreBackup(v['backup-json']!),
                    ),
                  ),
                  child: const Text('Pegar respaldo'),
                ),
              if (controller.storageError != null)
                TextButton(
                  onPressed: () {
                    if (controller.loadFailed) {
                      controller.retryLoading();
                    } else {
                      controller.retrySaving();
                    }
                  },
                  child: const Text('Reintentar'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'El respaldo no incluye contraseñas ni sesiones. No introduzcas datos reales: este prototipo no reemplaza los controles de producción.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
