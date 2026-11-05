import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/app.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/preferences_store.dart';
import 'package:farmacia_sae/models/home/views/home.dart';
import 'package:farmacia_sae/models/profile/models/profile_appearance.dart';
import 'package:farmacia_sae/models/profile/views/profile_page.dart';
import 'package:farmacia_sae/models/profile/widgets/profile_edit_dialog.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/user_avatar.dart';

class _ProfileStore extends MemoryPreferencesStore {
  bool fail = true;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('Guardado bloqueado para esta prueba');
    await super.write(value);
  }
}

Future<String> _photo() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(Colors.blue, BlendMode.src);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 2, 2),
    Paint()..color = Colors.teal,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  final result =
      'data:image/png;base64,${base64Encode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes))}';
  image.dispose();
  picture.dispose();
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AuthController> login(
    WidgetTester tester, {
    String username = 'admin',
    PreferencesStore? store,
  }) async {
    final auth = AuthController(profiles: store);
    addTearDown(auth.dispose);
    final signing = auth.signIn(username, '1234');
    await tester.pump(const Duration(milliseconds: 500));
    await signing;
    return auth;
  }

  Future<void> openEditor(
    WidgetTester tester,
    AuthController auth, {
    Future<String?> Function()? photoPicker,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) =>
                    ProfileEditDialog(auth: auth, photoPicker: photoPicker),
              ),
              child: const Text('Abrir editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
  }

  test(
    'migra el perfil v1 y persiste icono, color, foto y contacto por cuenta',
    () async {
      final store = MemoryPreferencesStore(
        jsonEncode({
          'version': 1,
          'users': {
            'demo-admin': {'name': 'Nombre anterior', 'phone': '8888-1111'},
            'demo-employee': {'name': 'Empleado anterior', 'phone': ''},
          },
        }),
      );
      final auth = AuthController(profiles: store);
      addTearDown(auth.dispose);
      await auth.signIn('admin', '1234');
      expect(auth.user!.name, 'Nombre anterior');
      final original = auth.user!;
      final photo = await _photo();
      expect(
        auth.updateProfile(
          name: 'Perfil nuevo',
          phone: '+505 8888-2222',
          contactEmail: 'contacto@example.com',
          avatarSymbol: ProfileSymbol.flower,
          avatarTone: ProfileTone.purple,
          avatarPhoto: photo,
        ),
        isNull,
      );
      await auth.flushProfile();
      expect(auth.user!.email, original.email);
      expect(auth.user!.username, original.username);
      expect(auth.user!.role, original.role);
      expect(auth.user!.id, original.id);
      auth.signOut();
      await auth.signIn('usuario', '1234');
      expect(auth.user!.name, 'Empleado anterior');
      expect(auth.user!.avatarPhoto, isEmpty);
      expect(auth.user!.avatarSymbol, ProfileSymbol.initials);
      auth.updateProfile(
        name: 'Empleado nuevo',
        phone: '',
        avatarSymbol: ProfileSymbol.heart,
      );
      await auth.flushProfile();
      final reload = AuthController(profiles: store);
      addTearDown(reload.dispose);
      await reload.signIn('admin', '1234');
      expect(reload.user!.displayEmail, 'contacto@example.com');
      expect(reload.user!.avatarSymbol, ProfileSymbol.flower);
      expect(reload.user!.avatarTone, ProfileTone.purple);
      expect(reload.user!.avatarPhoto, photo);
      expect(jsonDecode(store.data!)['version'], 2);
      reload.updateProfile(
        name: 'Perfil nuevo',
        phone: '',
        contactEmail: '',
        avatarPhoto: '',
      );
      await reload.flushProfile();
      reload.signOut();
      await reload.signIn('admin', '1234');
      expect(reload.user!.displayEmail, isEmpty);
      expect(reload.user!.avatarPhoto, isEmpty);
    },
  );

  test(
    'valida primero y nunca guarda permisos, credenciales ni URLs de fotos',
    () async {
      final store = MemoryPreferencesStore();
      final auth = AuthController(profiles: store);
      addTearDown(auth.dispose);
      expect(auth.updateProfile(name: 'Sin sesión', phone: ''), isNotNull);
      await auth.signIn('usuario', '1234');
      final original = auth.user!;
      for (final args in [
        ('', '', '', ''),
        ('Nombre', 'abc', '', ''),
        ('Nombre', '', 'no-es-correo', ''),
        ('Nombre', '', '', 'https://example.com/avatar.png'),
        ('Nombre', '', '', 'data:image/svg+xml;base64,PHN2Zz4='),
        (
          'Nombre',
          '',
          '',
          'data:image/png;base64,${'A' * (ProfilePhoto.maxBytes * 2)}',
        ),
      ]) {
        expect(
          auth.updateProfile(
            name: args.$1,
            phone: args.$2,
            contactEmail: args.$3,
            avatarPhoto: args.$4,
          ),
          isNotNull,
        );
        expect(auth.user, same(original));
      }
      auth.updateProfile(
        name: 'Perfil válido',
        phone: '',
        avatarSymbol: ProfileSymbol.star,
      );
      await auth.flushProfile();
      final stored = (jsonDecode(store.data!)['users']['demo-employee'] as Map);
      for (final field in [
        'id',
        'role',
        'username',
        'password',
        'branchId',
        'registerId',
      ]) {
        expect(stored.containsKey(field), isFalse);
      }
    },
  );

  test(
    'metadatos dañados o permisos inyectados no alteran el rol de la sesión',
    () async {
      final store = MemoryPreferencesStore(
        jsonEncode({
          'version': 2,
          'users': {
            'demo-employee': {
              'name': 'Empleado',
              'phone': '',
              'role': 'administrator',
              'avatarSymbol': 'admin',
              'avatarTone': 'inexistente',
              'avatarPhoto': 'javascript:alert(1)',
            },
          },
        }),
      );
      final auth = AuthController(profiles: store);
      addTearDown(auth.dispose);
      await auth.signIn('usuario', '1234');
      expect(auth.user!.isAdministrator, isFalse);
      expect(auth.user!.avatarSymbol, ProfileSymbol.initials);
      expect(auth.user!.avatarPhoto, isEmpty);
    },
  );

  for (final role in ['admin', 'usuario']) {
    testWidgets(
      'perfil $role solo muestra texto y la edición ocurre en un modal',
      (tester) async {
        final auth = await login(tester, username: role);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: ProfilePage(auth: auth)),
          ),
        );
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(TextField), findsNothing);
        final original = auth.user!;
        await tester.tap(find.text('Editar perfil'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileEditDialog), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(3));
        await tester.ensureVisible(find.byKey(const Key('profile-name')));
        await tester.enterText(
          find.byKey(const Key('profile-name')),
          'Borrador sin guardar',
        );
        await tester.ensureVisible(
          find.byKey(const Key('profile-symbol-star')),
        );
        await tester.tap(find.byKey(const Key('profile-symbol-star')));
        await tester.ensureVisible(find.byKey(const Key('profile-cancel')));
        await tester.tap(find.byKey(const Key('profile-cancel')));
        await tester.pumpAndSettle();
        expect(auth.user, same(original));
        expect(find.byType(TextFormField), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'guardar actualiza datos y avatar en perfil, cabecera y menú sin vaciar carrito',
    (tester) async {
      final auth = await login(tester);
      await tester.pumpWidget(
        FarmaciaApp(
          auth: auth,
          administrationStore: MemoryAdministrationStore(),
          initialLocation: '/administracion/perfil',
        ),
      );
      await tester.pumpAndSettle();
      final data = tester
          .widget<HomeScreen>(find.byType(HomeScreen))
          .controller!;
      data.addToCart(data.products.first);
      final original = auth.user!;
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('profile-symbol-star')));
      await tester.tap(find.byKey(const Key('profile-symbol-star')));
      await tester.ensureVisible(find.byKey(const Key('profile-tone-teal')));
      await tester.tap(find.byKey(const Key('profile-tone-teal')));
      await tester.ensureVisible(find.byKey(const Key('profile-name')));
      await tester.enterText(
        find.byKey(const Key('profile-name')),
        'Ana Perfil',
      );
      await tester.ensureVisible(find.byKey(const Key('profile-email')));
      await tester.enterText(
        find.byKey(const Key('profile-email')),
        'ana@example.com',
      );
      await tester.ensureVisible(find.byKey(const Key('profile-phone')));
      await tester.enterText(
        find.byKey(const Key('profile-phone')),
        '8888-1234',
      );
      await tester.ensureVisible(find.byKey(const Key('profile-save')));
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditDialog), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(auth.user!.name, 'Ana Perfil');
      expect(auth.user!.displayEmail, 'ana@example.com');
      expect(auth.user!.email, original.email);
      expect(auth.user!.role, original.role);
      expect(data.cart, hasLength(1));
      expect(
        tester
            .widgetList<UserAvatar>(find.byType(UserAvatar))
            .every(
              (avatar) =>
                  avatar.user.avatarSymbol == ProfileSymbol.star &&
                  avatar.user.avatarTone == ProfileTone.teal,
            ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cargar, cancelar selección y quitar foto respeta el borrador', (
    tester,
  ) async {
    final auth = await login(tester);
    final photo = await tester.runAsync(_photo);
    var times = 0;
    await openEditor(
      tester,
      auth,
      photoPicker: () async => times++ == 0 ? photo : null,
    );
    await tester.tap(find.byKey(const Key('profile-photo-pick')));
    await tester.pumpAndSettle();
    expect(auth.user!.avatarPhoto, isEmpty);
    expect(
      tester
          .widget<UserAvatar>(find.byKey(const Key('profile-avatar-preview')))
          .user
          .avatarPhoto,
      photo,
    );
    await tester.tap(find.byKey(const Key('profile-photo-pick')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<UserAvatar>(find.byKey(const Key('profile-avatar-preview')))
          .user
          .avatarPhoto,
      photo,
    );
    await tester.tap(find.byKey(const Key('profile-photo-remove')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<UserAvatar>(find.byKey(const Key('profile-avatar-preview')))
          .user
          .avatarPhoto,
      isEmpty,
    );
    await tester.tap(find.byKey(const Key('profile-photo-pick')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-cancel')));
    await tester.tap(find.byKey(const Key('profile-cancel')));
    await tester.pumpAndSettle();
    expect(auth.user!.avatarPhoto, isEmpty);
  });

  testWidgets(
    'error de guardado es visible y permite reintentar sin éxito ficticio',
    (tester) async {
      final store = _ProfileStore();
      final auth = await login(tester, store: store);
      await openEditor(tester, auth);
      await tester.ensureVisible(find.byKey(const Key('profile-save')));
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-edit-error')), findsOneWidget);
      expect(find.byType(ProfileEditDialog), findsOneWidget);
      store.fail = false;
      await tester.ensureVisible(find.byKey(const Key('profile-save')));
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditDialog), findsNothing);
      expect(auth.profileStorageError, isNull);
    },
  );

  testWidgets(
    'validación del modal y cierre de sesión impiden guardar borradores ajenos',
    (tester) async {
      final auth = await login(tester);
      await openEditor(tester, auth);
      await tester.ensureVisible(find.byKey(const Key('profile-name')));
      await tester.enterText(find.byKey(const Key('profile-name')), '');
      await tester.ensureVisible(find.byKey(const Key('profile-save')));
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pumpAndSettle();
      expect(find.text('El nombre no puede quedar vacío.'), findsOneWidget);
      auth.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditDialog), findsNothing);
      expect(auth.user, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'se puede cancelar el modal incluso con el selector de foto pendiente',
    (tester) async {
      final auth = await login(tester);
      final pending = Completer<String?>();
      await openEditor(tester, auth, photoPicker: () => pending.future);
      await tester.tap(find.byKey(const Key('profile-photo-pick')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('profile-cancel')));
      await tester.tap(find.byKey(const Key('profile-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditDialog), findsNothing);
      pending.complete(null);
      await tester.pumpAndSettle();
      expect(auth.user!.avatarPhoto, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('perfil estático y modal adaptables $width oscuro=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = await login(tester);
        auth.updateProfile(
          name:
              'Nombre de perfil bastante largo para comprobar que no se desborda',
          phone: '+505 8888-1111',
          contactEmail: 'un.correo.de.contacto.largo@example.com',
          avatarSymbol: ProfileSymbol.flower,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(body: ProfilePage(auth: auth)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TextFormField), findsNothing);
        await tester.ensureVisible(find.text('Editar perfil'));
        await tester.tap(find.text('Editar perfil'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const Key('profile-phone')));
        await tester.enterText(
          find.byKey(const Key('profile-phone')),
          '8888-2222',
        );
        await tester.ensureVisible(find.byKey(const Key('profile-save')));
        await tester.tap(find.byKey(const Key('profile-save')));
        await tester.pumpAndSettle();
        expect(auth.user!.phone, '8888-2222');
        expect(find.byType(TextFormField), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
