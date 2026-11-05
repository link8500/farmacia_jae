import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/administration_page.dart';
import '../../../shared/widgets/record_form_dialog.dart';

/// Apertura, efectivo, arqueo y cierres reales del estado local, no del banco.
class CashPage extends StatelessWidget {
  const CashPage({required this.controller, super.key});
  final PharmacyController controller;
  void _amount(BuildContext context, {required bool close}) => showDialog<bool>(
    context: context,
    builder: (_) => RecordFormDialog(
      title: close ? 'Cerrar caja' : 'Abrir caja',
      description: close
          ? 'Cuenta el efectivo físico. La diferencia se conservará en el arqueo.'
          : 'Indica el fondo inicial de este turno.',
      fields: [
        RecordField(
          'cash-amount',
          close ? 'Efectivo contado (C\$)' : 'Fondo inicial (C\$)',
          validator: (value) {
            final n = parseAmount(value ?? '');
            return n == null || !n.isFinite || n < 0
                ? 'Importe inválido.'
                : null;
          },
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
      onSave: (values) => close
          ? controller.closeCashSession(parseAmount(values['cash-amount']!)!)
          : controller.openCashSession(parseAmount(values['cash-amount']!)!),
    ),
  );
  void _movement(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => RecordFormDialog(
      title: 'Movimiento de efectivo',
      description:
          'Entrada o salida manual con motivo. No registra cobros bancarios.',
      fields: [
        const RecordField(
          'cash-direction',
          'Tipo',
          initial: 'in',
          options: [('in', 'Entrada'), ('out', 'Salida')],
        ),
        RecordField(
          'cash-value',
          'Importe (C\$)',
          validator: positiveAmount,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const RecordField('cash-concept', 'Concepto / motivo', lines: 2),
      ],
      onSave: (values) => controller.cashAdjustment(
        parseAmount(values['cash-value']!)! *
            (values['cash-direction'] == 'out' ? -1 : 1),
        values['cash-concept']!,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final open = controller.openCash;
    return AdministrationPage(
      title: 'Caja y arqueos',
      description:
          'Control local del efectivo por turno. Tarjetas y transferencias se registran sin procesar pagos reales.',
      action: FilledButton.icon(
        onPressed: () => _amount(context, close: open != null),
        icon: const Icon(Icons.point_of_sale),
        label: Text(open == null ? 'Abrir caja' : 'Cerrar caja'),
      ),
      children: [
        OperationCard(
          title: open == null ? 'Caja cerrada' : 'Caja abierta · ${open.id}',
          subtitle: open == null
              ? 'Abre un turno antes de cobrar ventas.'
              : 'Responsable: ${open.actorName} · ${formatDate(open.openedAt)}',
          details: [
            if (open != null)
              Text(
                'Efectivo esperado: ${formatCordobas(controller.expectedCash(open))}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
          actions: [
            if (open != null)
              OutlinedButton.icon(
                onPressed: () => _movement(context),
                icon: const Icon(Icons.swap_vert),
                label: const Text('Entrada / salida'),
              ),
          ],
        ),
        for (final session in controller.cashSessions.reversed)
          OperationCard(
            title: session.id,
            subtitle:
                '${session.isOpen ? 'Abierta' : 'Cerrada'} · ${session.actorName}',
            details: [
              Text('Fondo inicial: ${formatCordobas(session.openingBalance)}'),
              Text(
                'Esperado: ${formatCordobas(controller.expectedCash(session))}',
              ),
              if (!session.isOpen)
                Text(
                  'Contado: ${formatCordobas(session.counted!)} · Diferencia: ${formatCordobas(session.counted! - controller.expectedCash(session))}',
                ),
              for (final movement
                  in controller.cashMovements
                      .where((m) => m.sessionId == session.id)
                      .toList()
                      .reversed)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${formatDate(movement.createdAt)} · ${movement.concept} · ${formatCordobas(movement.amount)}${movement.reference.isEmpty ? '' : ' · ${movement.reference}'}',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
