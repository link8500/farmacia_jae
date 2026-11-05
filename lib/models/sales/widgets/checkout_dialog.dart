import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../contacts/models/contact.dart';
import '../models/sale_receipt.dart';

/// Cobro explícito: efectivo muestra recibido/cambio; tarjeta y transferencia
/// registran el método, sin simular una autorización bancaria.
class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({required this.controller, super.key});
  final PharmacyController controller;
  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _tendered;
  PaymentMethod _method = PaymentMethod.cash;
  String _customer = '';
  String? _error;
  @override
  void initState() {
    super.initState();
    _tendered = TextEditingController(
      text: widget.controller.cartTotal.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _tendered.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final data = widget.controller;
    final error = data.checkoutSale(
      method: _method,
      tendered: _method == PaymentMethod.cash
          ? parseAmount(_tendered.text)!
          : data.cartTotal,
      customerId: _customer,
    );
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.pop(context, data.sales.last);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller;
    final received = parseAmount(_tendered.text) ?? 0;
    final change = received - data.cartTotal;
    return FormDialog(
      title: 'Confirmar cobro',
      description:
          '${data.workingBranch?.name ?? 'Sin sucursal'} · ${data.currentRegister?.name ?? 'Sin caja'} · ${data.actorName}',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver a la venta'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Registrar venta'),
        ),
      ],
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.palette.paleBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL DE LA FACTURA',
                    style: TextStyle(
                      color: context.palette.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    formatCordobas(data.cartTotal),
                    style: TextStyle(
                      color: context.palette.ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              key: const Key('sale-customer'),
              isExpanded: true,
              initialValue: '',
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Consumidor final'),
                ),
                for (final c in data.contacts.where(
                  (c) => c.active && c.kind == ContactKind.customer,
                ))
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => _customer = v ?? '',
            ),
            const SizedBox(height: 22),
            const Text(
              'Método de pago',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              key: const Key('sale-method'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in PaymentMethod.values)
                  ChoiceChip(
                    avatar: Icon(switch (method) {
                      PaymentMethod.cash => Icons.payments_outlined,
                      PaymentMethod.card => Icons.credit_card_outlined,
                      PaymentMethod.transfer => Icons.account_balance_outlined,
                    }, size: 18),
                    label: Text(method.label),
                    selected: _method == method,
                    onSelected: (_) => setState(() {
                      _method = method;
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            if (_method == PaymentMethod.cash) ...[
              TextFormField(
                key: const Key('sale-tendered'),
                controller: _tendered,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Efectivo recibido',
                  prefixText: 'C\$ ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final invalid = positiveAmount(v);
                  if (invalid != null) return invalid;
                  return parseAmount(v!)! < data.cartTotal
                      ? 'El efectivo no cubre el total de la factura.'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              Text(
                change < 0
                    ? 'Falta recibir: ${formatCordobas(-change)}'
                    : 'Cambio a entregar: ${formatCordobas(change)}',
                style: TextStyle(
                  color: context.palette.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else
              Text(
                'Se registrará ${_method.label.toLowerCase()} por ${formatCordobas(data.cartTotal)}. Este prototipo no procesa pagos bancarios.',
                style: TextStyle(color: context.palette.muted, height: 1.5),
              ),
            const SizedBox(height: 18),
            Text(
              'Comprobante interno, sin validez fiscal. El stock se descontará al registrar la venta.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: context.palette.muted,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
