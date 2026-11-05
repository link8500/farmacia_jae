import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/local_files.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/sale_receipt.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../products/widgets/product_thumbnail.dart';

String receiptHtml(SaleReceipt sale) {
  String esc(String value) => const HtmlEscape().convert(value);
  final trace =
      '<p>Sucursal: ${esc(sale.branchName.isEmpty ? 'Sin asignación histórica' : sale.branchName)} · Caja: ${esc(sale.registerName.isEmpty ? 'Sin asignación histórica' : sale.registerName)} · ID operador: ${esc(sale.actorId)}</p>';
  return '<!doctype html><html lang="es"><head><meta charset="utf-8"><title>${esc(sale.id)}</title><style>body{font:14px Arial;max-width:760px;margin:32px auto;padding:24px;color:#172033}table{width:100%;border-collapse:collapse}td,th{padding:12px;text-align:left;border-bottom:1px solid #ddd}.note{color:#555;font-size:12px}@media print{body{margin:0}}</style></head><body><h1>Farmacia JAE</h1><h2>Comprobante interno ${esc(sale.id)}</h2><p>${esc(formatDate(sale.createdAt))} · Cliente: ${esc(sale.customerName)}</p><p>Operador: ${esc(sale.actorName)} · Método registrado: ${esc(sale.method.label)}</p>$trace<table><thead><tr><th>Producto</th><th>Cantidad</th><th>Precio</th><th>Importe</th></tr></thead><tbody>${sale.lines.map((l) => '<tr><td>${esc(l.name)} (${esc(l.unit)})</td><td>${l.quantity}</td><td>${esc(formatCordobas(l.unitPrice))}</td><td>${esc(formatCordobas(l.total))}</td></tr>').join()}</tbody></table><h2>Total: ${esc(formatCordobas(sale.total))}</h2>${sale.method == PaymentMethod.cash ? '<p>Recibido: ${esc(formatCordobas(sale.cashReceived))} · Cambio: ${esc(formatCordobas(sale.change))}</p>' : ''}${sale.cancelled ? '<p>ANULADO: ${esc(sale.reason)}</p>' : ''}<p class="note">Comprobante interno. No es un documento fiscal ni acredita un pago bancario real.</p></body></html>';
}

/// Comprobante de consulta: datos de emisión, líneas alineadas y total. Las
/// acciones permanecen al pie aunque una factura tenga muchos productos.
Future<void> showReceipt(
  BuildContext context,
  SaleReceipt sale, {
  PharmacyController? controller,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => FormDialog(
    title: 'Comprobante ${sale.id}',
    maxWidth: 760,
    description: 'Documento interno. No es facturación fiscal.',
    actions: [
      OutlinedButton.icon(
        onPressed: () {
          if (!downloadText(
            '${sale.id}.html',
            receiptHtml(sale),
            type: 'text/html;charset=utf-8',
          )) {
            showCommandResult(
              dialogContext,
              'La descarga está disponible en la versión web.',
            );
          }
        },
        icon: const Icon(Icons.download, size: 17),
        label: const Text('Descargar comprobante'),
      ),
      FilledButton.icon(
        onPressed: () {
          if (!printDocument(receiptHtml(sale))) {
            showCommandResult(
              dialogContext,
              'El navegador bloqueó la ventana de impresión. Puedes descargar el comprobante.',
            );
          }
        },
        icon: const Icon(Icons.print, size: 17),
        label: const Text('Imprimir'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Cerrar'),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormFieldsGrid(
          fields: [
            Text('Cliente: ${sale.customerName}'),
            Text('Operador: ${sale.actorName}'),
            Text('Fecha: ${formatDate(sale.createdAt)}'),
            Text('Medio de pago: ${sale.method.label}'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Sucursal: ${sale.branchName.isEmpty ? 'Sin asignación histórica' : sale.branchName} · Caja: ${sale.registerName.isEmpty ? 'Sin asignación histórica' : sale.registerName}',
          style: TextStyle(fontSize: 12, color: dialogContext.palette.muted),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) {
            // La tabla conserva cantidades y precios alineados; móvil permite
            // desplazamiento horizontal sin comprimir ni ocultar los importes.
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: box.maxWidth < 470 ? 470 : box.maxWidth,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1.3),
                    3: FlexColumnWidth(1.3),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder(
                    horizontalInside: BorderSide(color: context.palette.border),
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: context.palette.canvas),
                      children: [
                        for (final h in [
                          'Producto',
                          'Cant.',
                          'Precio',
                          'Importe',
                        ])
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              h,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.palette.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (final line in sale.lines)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ProductThumbnail(
                                  illustrationKey:
                                      controller
                                          ?.productById(line.productId)
                                          ?.illustrationKey ??
                                      '',
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        line.unit,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.palette.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final value in [
                            '${line.quantity}',
                            formatCordobas(line.unitPrice),
                            formatCordobas(line.total),
                          ])
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total: ${formatCordobas(sale.total)}',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
        ),
        if (sale.method == PaymentMethod.cash)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Recibido: ${formatCordobas(sale.cashReceived)} · Cambio: ${formatCordobas(sale.change)}',
                style: TextStyle(
                  fontSize: 12,
                  color: dialogContext.palette.muted,
                ),
              ),
            ),
          ),
        if (sale.cancelled)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Anulado: ${sale.reason}',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
      ],
    ),
  ),
).then((_) {});
