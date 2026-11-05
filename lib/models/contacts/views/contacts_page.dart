import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/contact.dart';
import '../widgets/contact_editor.dart';
import '../../../shared/widgets/person_avatar.dart';
import 'contact_details_page.dart';

/// Directorio paginado de filas breves; dirección e historial están en Detalle.
class ContactsPage extends StatefulWidget {
  const ContactsPage({
    required this.controller,
    required this.kind,
    this.onOpen,
    super.key,
  });
  final PharmacyController controller;
  final ContactKind kind;
  final ValueChanged<String>? onOpen;
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String _query = '', _filter = 'Activos';
  String? _selected;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Contact c) {
    if (widget.onOpen != null) {
      widget.onOpen!(c.id);
    } else {
      setState(() => _selected = c.id);
    }
  }

  @override
  void didUpdateWidget(covariant ContactsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _query = '';
      _search.clear();
      _filter = 'Activos';
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller,
          customer = widget.kind == ContactKind.customer;
      if (_selected != null) {
        return ContactDetailsPage(
          controller: data,
          kind: widget.kind,
          contactId: _selected!,
          onBack: () => setState(() => _selected = null),
        );
      }
      final list = data.contacts
          .where(
            (c) =>
                c.kind == widget.kind &&
                (_filter == 'Todos' || c.active == (_filter == 'Activos')) &&
                [
                  c.name,
                  c.phone,
                  c.email,
                  c.identification,
                  c.representative,
                  c.code,
                  c.supplierType,
                  c.origin,
                ].any((text) => text.toLowerCase().contains(_query)),
          )
          .toList();
      return CompactWorkspace(
        title: customer ? 'Clientes' : 'Proveedores',
        subtitle: '${list.length} contactos',
        actions: [
          FilledButton.icon(
            onPressed: () => editContact(context, data, widget.kind),
            icon: const Icon(Icons.add, size: 18),
            label: Text(customer ? 'Nuevo cliente' : 'Nuevo proveedor'),
          ),
        ],
        toolbar: RecordToolbar(
          search: TextField(
            key: const Key('contacts-search'),
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar nombre, correo o teléfono',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          filters: [
            RecordFilter(
              label: 'Estado',
              value: _filter,
              options: const ['Activos', 'Archivados', 'Todos'],
              onChanged: (v) => setState(() => _filter = v),
            ),
          ],
        ),
        child: CompactRecords(
          itemCount: list.length,
          resetKey: '${widget.kind}|$_query|$_filter',
          emptyText: 'No hay contactos para este filtro.',
          columns: [
            RecordColumn(customer ? 'Nombre' : 'Proveedor / código', flex: 2.5),
            const RecordColumn('Teléfono', flex: 1.2),
            const RecordColumn('Correo', flex: 2),
            RecordColumn(customer ? 'Estado' : 'Tipo'),
            const RecordColumn('', flex: .45),
          ],
          rowBuilder: (i) {
            final c = list[i];
            Widget menu() => RecordActions(
              recordKey: 'contact-actions-${c.id}',
              actions: [
                ('Ver detalle', () => _open(c)),
                ('Editar', () => editContact(context, data, widget.kind, c)),
                (
                  c.active ? 'Archivar' : 'Reactivar',
                  () => confirmCommand(
                    context,
                    c.active ? '¿Archivar contacto?' : '¿Reactivar contacto?',
                    'Se conserva todo el historial asociado.',
                    () => data.toggleContact(c.id),
                  ),
                ),
              ],
            );
            return RecordRow(
              onOpen: () => _open(c),
              cells: [
                RecordIdentity(
                  title: c.name,
                  subtitle: customer
                      ? c.identification
                      : '${c.code} · ${c.representative}',
                  leading: PersonAvatar(
                    name: c.name,
                    asset: c.photoAsset,
                    size: 32,
                  ),
                ),
                RecordText(c.phone.isEmpty ? '—' : c.phone),
                RecordText(c.email.isEmpty ? '—' : c.email),
                RecordText(
                  customer
                      ? (c.active ? 'Activo' : 'Archivado')
                      : c.supplierType,
                ),
                menu(),
              ],
              mobile: RecordTile(
                leading: PersonAvatar(name: c.name, asset: c.photoAsset),
                title: c.name,
                subtitle: c.email.isEmpty ? c.phone : c.email,
                metadata:
                    '${c.identification} · ${c.active ? 'Activo' : 'Archivado'}',
                trailing: menu(),
                onOpen: () => _open(c),
              ),
            );
          },
        ),
      );
    },
  );
}
