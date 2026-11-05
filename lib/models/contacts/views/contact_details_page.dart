import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_detail.dart';
import '../../sales/widgets/receipt_dialog.dart';
import '../../purchases/widgets/purchase_actions.dart';
import '../models/contact.dart';
import '../widgets/contact_editor.dart';
import '../../../shared/widgets/person_avatar.dart';
import '../../purchases/views/purchase_details_page.dart';
import '../../products/widgets/supplier_catalog.dart';
import '../../../shared/widgets/workspace_sections.dart';

class ContactDetailsPage extends StatefulWidget {
  const ContactDetailsPage({
    required this.controller,
    required this.kind,
    required this.contactId,
    required this.onBack,
    this.onPurchase,
    super.key,
  });
  final PharmacyController controller;
  final ContactKind kind;
  final String contactId;
  final VoidCallback onBack;
  final ValueChanged<String>? onPurchase;
  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  String? _purchase;
  int _tab = 0;
  @override
  void didUpdateWidget(covariant ContactDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contactId != widget.contactId ||
        oldWidget.kind != widget.kind) {
      _purchase = null;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final kind = widget.kind;
      final contactId = widget.contactId;
      final onBack = widget.onBack;
      if (_purchase != null) {
        return PurchaseDetailsPage(
          controller: controller,
          purchaseId: _purchase!,
          backLabel: 'Volver al proveedor',
          onBack: () => setState(() => _purchase = null),
        );
      }
      final c = controller.contactById(contactId);
      if (c == null || c.kind != kind) {
        return RecordDetail(
          title: 'Contacto no disponible',
          onBack: onBack,
          fields: const [],
        );
      }
      final customer = kind == ContactKind.customer;
      final sales = controller.sales.where((s) => s.customerId == c.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final orders =
          controller.purchases.where((p) => p.supplierId == c.id).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return RecordDetail(
        title: c.name,
        subtitle: customer ? 'Detalle del cliente' : 'Detalle del proveedor',
        media: PersonAvatar(name: c.name, asset: c.photoAsset, size: 88),
        onBack: onBack,
        actions: [
          FilledButton.icon(
            onPressed: () => editContact(context, controller, kind, c),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Editar contacto'),
          ),
        ],
        fields: [
          ('Nombre', c.name),
          if (!customer) ...[
            ('Código del proveedor', c.code),
            ('Tipo', c.supplierType),
            ('Representante', c.representative),
            ('Origen', c.origin),
          ],
          ('Cédula / identificación', c.identification),
          ('Teléfono', c.phone),
          ('Correo', c.email),
          ('Dirección', c.address),
          ('Estado', c.active ? 'Activo' : 'Archivado'),
          if (!customer)
            ('Descripción / condiciones comerciales', c.description),
        ],
        children: [
          if (!customer)
            WorkspaceTabs(
              labels: const ['Historial de compras', 'Catálogo de productos'],
              selected: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          if (!customer && _tab == 1)
            SupplierCatalog(controller: controller, supplierId: c.id),
          if (customer || _tab == 0) ...[
            Text(
              customer
                  ? 'Comprobantes asociados'
                  : 'Compras de la sucursal consultada',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(
              height: 380,
              child: CompactRecords(
                itemCount: customer ? sales.length : orders.length,
                resetKey: '${c.id}|${controller.workingBranchId}',
                emptyText: customer
                    ? 'Este cliente aún no tiene ventas registradas.'
                    : 'Sin compras en esta sucursal.',
                columns: const [
                  RecordColumn('Documento', flex: 2),
                  RecordColumn('Fecha'),
                  RecordColumn('Estado'),
                  RecordColumn('Total'),
                ],
                rowBuilder: (i) {
                  final id = customer ? sales[i].id : orders[i].id;
                  final at = customer
                      ? sales[i].createdAt
                      : orders[i].createdAt;
                  final state = customer
                      ? (sales[i].cancelled ? 'Anulada' : 'Vigente')
                      : purchaseStatusLabel(orders[i].status);
                  final total = customer ? sales[i].total : orders[i].total;
                  void open() {
                    if (customer) {
                      showReceipt(context, sales[i], controller: controller);
                    } else if (widget.onPurchase != null) {
                      widget.onPurchase!(id);
                    } else {
                      setState(() => _purchase = id);
                    }
                  }

                  return RecordRow(
                    onOpen: open,
                    cells: [
                      RecordText(id, bold: true),
                      RecordText(formatDate(at)),
                      RecordText(state),
                      RecordText(formatCordobas(total)),
                    ],
                    mobile: RecordTile(
                      title: id,
                      subtitle: '${formatDate(at)} · $state',
                      metadata: formatCordobas(total),
                      onOpen: open,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    },
  );
}
