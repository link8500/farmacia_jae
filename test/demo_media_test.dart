import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/config/demo_people.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/preferences_store.dart';
import 'package:farmacia_sae/core/services/promotion_store.dart';
import 'package:farmacia_sae/core/services/promotions_controller.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:farmacia_sae/models/contacts/views/contact_details_page.dart';
import 'package:farmacia_sae/models/inventory/views/lot_details_page.dart';
import 'package:farmacia_sae/models/dashboard/widgets/dashboard_sections.dart';
import 'package:farmacia_sae/models/products/views/product_details_page.dart';
import 'package:farmacia_sae/models/products/widgets/product_thumbnail.dart';
import 'package:farmacia_sae/models/promotions/models/promotion.dart';
import 'package:farmacia_sae/models/promotions/models/promotion_image.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/person_avatar.dart';
import 'package:farmacia_sae/shared/widgets/user_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'las 31 fotos son imágenes decodificables incluidas en el bundle',
    () async {
      final assets = [
        for (final p in DemoPeople.records.values) p.photo,
        for (final p in PromotionImages.values.values) p.asset,
      ];
      expect(assets.toSet(), hasLength(31));
      for (final asset in assets) {
        final bytes = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          targetWidth: 40,
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 40, reason: asset);
        expect(frame.image.height, greaterThan(0), reason: asset);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test(
    'un respaldo anterior recibe fotos sin duplicar ventas ni cambiar puestos',
    () async {
      final data = PharmacyController(seedDemoHistory: true);
      addTearDown(data.dispose);
      final snapshot = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      for (final key in ['contacts', 'staff']) {
        for (final item in snapshot[key] as List) {
          item.remove('photoAsset');
          item.remove('identification');
          item.remove('representative');
        }
      }
      final store = MemoryAdministrationStore(jsonEncode(snapshot));
      final restored = PharmacyController(store: store, seedDemoHistory: true);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.loadFailed, isFalse);
      expect(restored.sales.map((s) => s.id), data.sales.map((s) => s.id));
      expect(restored.stockTotal, data.stockTotal);
      expect(
        restored.staff.map((s) => s.registerId),
        data.staff.map((s) => s.registerId),
      );
      expect(
        restored.contacts.every(
          (c) =>
              c.photoAsset.isNotEmpty && c.identification.startsWith('DEMO-'),
        ),
        isTrue,
      );
      expect(restored.staff.every((s) => s.photoAsset.isNotEmpty), isTrue);
      final client = restored.contacts.firstWhere(
        (c) => c.kind == ContactKind.customer,
      );
      expect(
        restored.saveContact(
          id: client.id,
          kind: client.kind,
          name: 'Nombre editado',
          identification: 'DOCUMENTO EDITADO',
        ),
        isNull,
      );
      final again = PharmacyController(seedDemo: false);
      addTearDown(again.dispose);
      expect(again.restoreBackup(restored.createBackup()), isNull);
      expect(again.contactById(client.id)?.identification, 'DOCUMENTO EDITADO');
      expect(again.contactById(client.id)?.photoAsset, client.photoAsset);
      expect(again.contactById(client.id)?.name, 'Nombre editado');
    },
  );

  test(
    'las campañas se instalan una vez y respetan archivo, fechas y proyección pública',
    () async {
      final store = MemoryPromotionStore();
      final now = DateTime(2026, 10, 29);
      final editor = PromotionsController(
        store: store,
        canManage: () => true,
        clock: () => now,
        seedDemo: true,
      );
      addTearDown(editor.dispose);
      await editor.loadEditor();
      expect(editor.editorError, isNull);
      expect(editor.entries, hasLength(5));
      expect(editor.visible, hasLength(3));
      final original = editor.entries.first;
      expect(
        (await editor.save(
          original.withIdentity(original.id, status: PromotionStatus.archived),
        )).error,
        isNull,
      );
      final reloaded = PromotionsController(
        store: store,
        canManage: () => true,
        clock: () => now,
        seedDemo: true,
      );
      addTearDown(reloaded.dispose);
      await reloaded.loadEditor();
      expect(reloaded.entries, hasLength(5));
      expect(
        reloaded.entries.firstWhere((p) => p.id == original.id).status,
        PromotionStatus.archived,
      );
      expect(
        reloaded.entries.firstWhere((p) => p.id == original.id).startsAt,
        original.startsAt,
      );
      final public = PromotionsController(
        store: store,
        canManage: () => false,
        clock: () => now,
        seedDemo: true,
      );
      addTearDown(public.dispose);
      await public.loadPublic();
      expect(public.entries, isEmpty);
      expect(public.visible, hasLength(2));
      expect(
        public.visible.every(
          (p) => PromotionImages.values.containsKey(p.illustrationKey),
        ),
        isTrue,
      );
    },
  );

  test(
    'quitar la foto de perfil se conserva al volver a iniciar sesión',
    () async {
      final auth = AuthController(profiles: MemoryPreferencesStore());
      addTearDown(auth.dispose);
      await auth.signIn('admin', '1234');
      expect(auth.user!.avatarAsset, isNotEmpty);
      expect(
        auth.updateProfile(name: auth.user!.name, phone: '', avatarAsset: ''),
        isNull,
      );
      await auth.flushProfile();
      auth.signOut();
      await auth.signIn('admin', '1234');
      expect(auth.user!.avatarAsset, isEmpty);
    },
  );

  for (final width in [320.0, 1280.0]) {
    testWidgets(
      'las alertas del resumen usan la imagen de su producto a $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final data = PharmacyController();
        addTearDown(data.dispose);
        final expected = data.inventory
            .where((p) => p.isLow || p.hasExpiringLots || p.hasExpiredLots)
            .take(3)
            .toList();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SingleChildScrollView(
                child: InventoryAlertsCard(
                  entries: data.inventory,
                  onNavigate: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProductThumbnail), findsNWidgets(expected.length));
        expect(
          tester
              .widgetList<ProductThumbnail>(find.byType(ProductThumbnail))
              .map((p) => p.illustrationKey),
          expected.map((p) => p.product.illustrationKey),
        );
        expect(find.byType(Image), findsNWidgets(expected.length));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'detalle de producto, lote y contacto conserva su imagen a $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final data = PharmacyController(seedDemoHistory: true);
        addTearDown(data.dispose);
        Future<void> mount(Widget child) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(body: child),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await mount(
          ProductDetailsPage(
            controller: data,
            productId: data.products.first.id,
            onBack: () {},
            onLots: () {},
          ),
        );
        expect(find.byType(ProductThumbnail), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        await mount(
          LotDetailsPage(
            controller: data,
            lotId: data.lots.first.id,
            onBack: () {},
          ),
        );
        expect(find.byType(ProductThumbnail), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        final contact = data.contacts.firstWhere(
          (c) => c.kind == ContactKind.customer,
        );
        await mount(
          ContactDetailsPage(
            controller: data,
            kind: contact.kind,
            contactId: contact.id,
            onBack: () {},
          ),
        );
        expect(find.byType(PersonAvatar), findsOneWidget);
        expect(find.text(contact.identification), findsOneWidget);
        await mount(UserAvatar(user: AuthController.demoUsers.first, size: 64));
        expect(find.byType(Image), findsOneWidget);
      },
    );
  }
}
