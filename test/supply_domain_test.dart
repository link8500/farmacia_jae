import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:farmacia_sae/models/purchases/models/purchase_order.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/models/reports/models/local_report.dart';

void main() {
  final today = DateTime(2026, 11, 4);
  PharmacyController fresh() {
    final data = PharmacyController(seedDemo: false, clock: () => today);
    addTearDown(data.dispose);
    data.saveContact(
      kind: ContactKind.supplier,
      name: 'Distribuidora del Norte',
      code: 'PRV-001',
      supplierType: 'Distribuidor',
      origin: 'León',
      representative: 'María Pérez',
      phone: '2222-2222',
      email: 'compras@example.com',
      description: 'Distribución farmacéutica.',
    );
    data.saveContact(
      kind: ContactKind.supplier,
      name: 'Laboratorio del Sur',
      code: 'PRV-002',
      supplierType: 'Laboratorio',
    );
    return data;
  }

  String product(PharmacyController data, String code) {
    expect(
      data.registerProduct(
        code: code,
        name: 'Medicamento $code',
        category: 'Medicamentos',
        presentation: 'Caja de 10 tabletas',
        unit: 'Tableta',
        minimum: 10,
        packageUnits: 10,
        dosage: '500 mg',
        measurementUnit: 'mg',
        origin: 'Nicaragua',
        manufacturer: 'Laboratorio de prueba',
        indications: 'Según prospecto',
        contraindications: 'Según prospecto',
        requiresPrescription: true,
      ),
      isNull,
    );
    return data.products.last.id;
  }

  PurchaseLine line(String id, {int quantity = 20, double cost = .4}) =>
      PurchaseLine(
        productId: id,
        productName: 'No confiable',
        quantity: quantity,
        unitCost: cost,
      );
  LotReceipt receipt(
    String id, {
    String code = 'FAB-24-A',
    double? price = 1.25,
    DateTime? manufactured,
    String location = 'A-01',
  }) => LotReceipt(
    productId: id,
    code: code,
    expiry: today.add(const Duration(days: 360)),
    manufacturedAt: manufactured ?? today.subtract(const Duration(days: 100)),
    location: location,
    salePrice: price,
  );

  test(
    'producto pendiente, proveedor N:M, precio unitario posterior y venta por FEFO conservan trazabilidad',
    () {
      final data = fresh();
      final id = product(data, 'MED-X');
      final suppliers = data.contacts
          .where((c) => c.kind == ContactKind.supplier)
          .toList();
      expect(data.products.single.price, 0);
      expect(data.setProductPrice(id, 1.25), isNotNull);
      for (final s in suppliers) {
        expect(
          data.saveProductSupplier(
            productId: id,
            supplierId: s.id,
            referenceCost: .4,
            supplierCode: 'REF-X',
            leadDays: 3,
          ),
          isNull,
        );
      }
      expect(data.suppliersForProduct(id), hasLength(2));
      expect(data.createPurchase(suppliers.first.id, [line(id)]), isNull);
      final order = data.purchases.single;
      expect(order.lines.single.productName, 'Medicamento MED-X');
      expect(order.lines.single.dosage, '500 mg');
      expect(order.lines.single.presentation, 'Caja de 10 tabletas');
      expect(order.lines.single.unit, 'Tableta');
      expect(order.total, 8);
      expect(data.receivePurchase(order.id, [receipt(id)]), isNull);
      final lot = data.lots.single;
      expect(lot.quantity, 20);
      expect(lot.code, 'FAB-24-A');
      expect(lot.manufacturedAt, today.subtract(const Duration(days: 100)));
      expect(lot.supplierId, suppliers.first.id);
      expect(lot.location, 'A-01');
      expect(data.products.single.price, 1.25);
      expect(data.addToCart(data.products.single), isTrue);
      expect(data.addToCart(data.products.single), isTrue);
      expect(
        data.checkoutSale(method: PaymentMethod.cash, tendered: 3),
        isNull,
      );
      expect(data.sales.single.total, 2.5);
      expect(data.lots.single.quantity, 18);
      expect(data.lots.single.manufacturedAt, lot.manufacturedAt);
      expect(data.lots.single.location, lot.location);
      expect(data.setProductPrice(id, 2), isNull);
      expect(data.sales.single.lines.single.unitPrice, 1.25);
      expect(data.purchases.single.lines.single.unitCost, .4);
      expect(data.relocateLot(lot.id, 'B-02'), isNull);
      expect(data.lots.single.quantity, 18);
      expect(data.lots.single.location, 'B-02');
      final movementCount = data.movements.length;
      expect(
        data.documentLot(
          lot.id,
          supplierId: suppliers.first.id,
          manufacturedAt: today.add(const Duration(days: 1)),
          location: 'B-02',
        ),
        isNotNull,
      );
      expect(
        data.documentLot(
          lot.id,
          supplierId: suppliers.first.id,
          manufacturedAt: today.subtract(const Duration(days: 90)),
          location: 'B-02',
        ),
        isNull,
      );
      expect(data.lots.single.quantity, 18);
      expect(data.lots.single.unitCost, .4);
      expect(data.movements.length, movementCount);
      final report = LocalReportBuilder.build(
        data,
        LocalReportKind.inventory,
        today,
        today,
      );
      expect(
        report.headers,
        containsAll(['Proveedor', 'Fabricación', 'Ubicación']),
      );
      expect(report.rows.single, contains('B-02'));
      final restored = fresh();
      expect(restored.restoreBackup(data.createBackup()), isNull);
      expect(restored.productSuppliers, hasLength(2));
      expect(restored.lots.single.location, 'B-02');
      expect(restored.products.single.requiresPrescription, isTrue);
      expect(restored.sales.single.total, 2.5);
    },
  );

  test(
    'recepción inválida no altera ninguna línea, precio, movimiento ni estado',
    () {
      final data = fresh();
      final x = product(data, 'MED-X'), y = product(data, 'MED-Y');
      expect(
        data.createPurchase(data.contacts.first.id, [line(x), line(y)]),
        isNull,
      );
      final order = data.purchases.single;
      final before = data.createBackup();
      expect(
        data.receivePurchase(order.id, [
          receipt(x),
          receipt(y, manufactured: today.add(const Duration(days: 1))),
        ]),
        isNotNull,
      );
      expect(data.lots, isEmpty);
      expect(data.movements, isEmpty);
      expect(data.products.every((p) => p.price == 0), isTrue);
      expect(data.purchases.single.status, PurchaseStatus.pending);
      final rawBefore = jsonDecode(before) as Map<String, dynamic>;
      final rawAfter = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      for (final field in ['lots', 'products', 'purchases', 'movements']) {
        expect(rawAfter[field], rawBefore[field]);
      }
      expect(
        data.receivePurchase(order.id, [
          receipt(x),
          receipt(y, code: 'FAB-24-B'),
        ]),
        isNull,
      );
      expect(
        data.receivePurchase(order.id, [receipt(x), receipt(y)]),
        isNotNull,
      );
      expect(data.lots, hasLength(2));
    },
  );

  test(
    'códigos de proveedor únicos y vínculo suspendido bloquean una compra nueva',
    () {
      final data = fresh();
      final p = product(data, 'MED-X');
      expect(
        data.saveContact(
          kind: ContactKind.supplier,
          name: 'Otro',
          code: 'prv-001',
        ),
        isNotNull,
      );
      expect(data.contacts, hasLength(2));
      expect(
        data.saveProductSupplier(
          productId: p,
          supplierId: data.contacts.first.id,
          active: false,
        ),
        isNull,
      );
      expect(data.suppliersForProduct(p), isEmpty);
      expect(data.createPurchase(data.contacts.first.id, [line(p)]), isNotNull);
      expect(data.purchases, isEmpty);
      expect(
        data.saveProductSupplier(productId: p, supplierId: 'missing'),
        isNotNull,
      );
      expect(
        data.saveProductSupplier(
          productId: p,
          supplierId: data.contacts.first.id,
          leadDays: 366,
        ),
        isNotNull,
      );
    },
  );

  test(
    'respaldo anterior reconstruye vínculos solo desde compras y rechaza referencias rotas',
    () {
      final data = fresh();
      final id = product(data, 'MED-X');
      data.createPurchase(data.contacts.first.id, [line(id)]);
      final raw = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      raw.remove('productSuppliers');
      for (final p in raw['products'] as List) {
        for (final field in [
          'dosage',
          'measurementUnit',
          'origin',
          'manufacturer',
          'description',
          'indications',
          'contraindications',
          'requiresPrescription',
          'packageUnits',
        ]) {
          (p as Map).remove(field);
        }
      }
      final restored = fresh();
      expect(restored.restoreBackup(jsonEncode(raw)), isNull);
      expect(restored.productSuppliers, hasLength(1));
      expect(restored.products.single.packageUnits, 1);
      expect(restored.products.single.price, 0);
      final corrupt =
          jsonDecode(restored.createBackup()) as Map<String, dynamic>;
      (corrupt['productSuppliers'] as List).first['supplierId'] = 'missing';
      expect(restored.restoreBackup(jsonEncode(corrupt)), isNotNull);
      expect(
        restored.productSuppliers.single.supplierId,
        data.contacts.first.id,
      );
    },
  );

  test(
    'un producto sin precio no puede entrar en facturación y las fechas no se deducen del código',
    () {
      final data = fresh();
      final id = product(data, 'MED-X');
      expect(
        data.receiveLot(
          productId: id,
          code: 'ABC-NO-FECHA',
          quantity: 10,
          expiry: today.add(const Duration(days: 90)),
          manufacturedAt: today.subtract(const Duration(days: 30)),
          supplierId: data.contacts.first.id,
          location: 'C-1',
        ),
        isNull,
      );
      expect(data.addToCart(data.products.single), isFalse);
      expect(data.setProductPrice(id, .75), isNull);
      expect(data.addToCart(data.products.single), isTrue);
      expect(data.setProductPrice(id, .8), isNotNull);
      expect(data.lots.single.code, 'ABC-NO-FECHA');
    },
  );
}
