import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/auth_guard.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';

/// Comprueba el guard al navegar por URL, no solo al pulsar botones.
void main() {
  late AuthController auth;
  late AuthGuard guard;
  setUp(() {
    auth = AuthController();
    guard = AuthGuard(auth);
  });
  tearDown(() => auth.dispose());

  test('admin y usuario acceden con 1234 y conservan su rol', () async {
    expect(await auth.signIn('admin', '1234'), isNull);
    expect(auth.user!.username, 'admin');
    expect(auth.user!.isAdministrator, isTrue);
    auth.signOut();
    expect(await auth.signIn('usuario', '1234'), isNull);
    expect(auth.user!.username, 'usuario');
    expect(auth.user!.isAdministrator, isFalse);
  });

  test('credenciales anteriores no habilitan una sesión', () async {
    expect(await auth.signIn('admin', 'DemoJae2026!'), isNotNull);
    for (final old in AuthController.demoUsers) {
      expect(await auth.signIn(old.email, '1234'), isNotNull);
    }
    expect(auth.isAuthenticated, isFalse);
  });

  test('presentación y login son públicos', () {
    expect(guard.redirect(Uri.parse(AppPaths.presentation)), isNull);
    expect(guard.redirect(Uri.parse(AppPaths.login)), isNull);
  });

  test('todas las rutas privadas requieren una sesión', () {
    for (final path in AppPaths.sections) {
      if (path == AppPaths.administration) {
        expect(guard.redirect(Uri.parse(path)), isNull);
        continue; // La entrada raíz muestra el formulario, sin shell privado.
      }
      final destination = Uri.parse(guard.redirect(Uri.parse(path))!);
      expect(destination.path, AppPaths.login);
      expect(destination.hasQuery, isFalse);
    }
  });

  test('una contraseña incorrecta no crea una sesión', () async {
    expect(
      await auth.signIn(AuthController.demoUsers[0].username, 'incorrecta'),
      isNotNull,
    );
    expect(auth.isAuthenticated, isFalse);
  });

  test('administrador puede entrar a cada módulo', () async {
    await auth.signIn(' ADMIN ', AuthController.demoPassword);
    for (final index in AppPaths.enabledSectionIndices) {
      expect(guard.redirect(Uri.parse(AppPaths.sections[index])), isNull);
    }
  });

  test('empleado no puede entrar a módulos administrativos por URL', () async {
    await auth.signIn(
      AuthController.demoUsers[1].username,
      AuthController.demoPassword,
    );
    for (final index in AppPaths.administratorOnly) {
      expect(
        guard.redirect(Uri.parse(AppPaths.sections[index])),
        AppPaths.profile,
      );
    }
    expect(guard.redirect(Uri.parse('/administracion/ventas')), isNull);
    expect(guard.redirect(Uri.parse('/administracion/inventario')), isNull);
    expect(guard.redirect(Uri.parse(AppPaths.profile)), isNull);
  });

  test('login elimina el destino anterior y usa la entrada canónica', () async {
    await auth.signIn(
      AuthController.demoUsers[0].username,
      AuthController.demoPassword,
    );
    expect(
      guard.redirect(
        Uri(
          path: AppPaths.login,
          queryParameters: {'desde': '/administracion/inventario'},
        ),
      ),
      AppPaths.administration,
    );
  });

  test(
    'no redirige hacia una dirección externa ni a rutas desconocidas',
    () async {
      await auth.signIn(
        AuthController.demoUsers[0].username,
        AuthController.demoPassword,
      );
      for (final destination in [
        'https://otro.example',
        '//otro.example',
        '/administracion/no-existe',
        '/presentacion',
      ]) {
        expect(
          guard.redirect(
            Uri(path: AppPaths.login, queryParameters: {'desde': destination}),
          ),
          AppPaths.administration,
        );
      }
    },
  );

  test('cerrar sesión revoca el acceso a todos los módulos', () async {
    await auth.signIn(
      AuthController.demoUsers[0].username,
      AuthController.demoPassword,
    );
    auth.signOut();
    for (final path in AppPaths.sections) {
      if (path == AppPaths.administration) {
        expect(guard.redirect(Uri.parse(path)), isNull);
        continue;
      }
      expect(Uri.parse(guard.redirect(Uri.parse(path))!).path, AppPaths.login);
    }
  });

  test('enlaces antiguos se limpian con y sin sesión', () async {
    for (final signedIn in [false, true]) {
      if (signedIn) await auth.signIn('admin', '1234');
      for (final path in [
        '/administracion/login?desde=/administracion/productos',
        '/administracion?desde=https://externo.example',
        '/administracion/login',
      ]) {
        expect(guard.redirect(Uri.parse(path)), AppPaths.administration);
      }
      expect(guard.redirect(Uri.parse(AppPaths.administration)), isNull);
    }
  });

  test('editar el perfil no modifica rol, identidad ni correo', () async {
    await auth.signIn(
      AuthController.demoUsers[1].username,
      AuthController.demoPassword,
    );
    final original = auth.user!;
    auth.updateProfile(name: 'Empleado de ejemplo', phone: '12345678');
    expect(auth.user!.name, 'Empleado de ejemplo');
    expect(auth.user!.role, original.role);
    expect(auth.user!.username, original.username);
    expect(auth.user!.email, original.email);
    expect(auth.user!.id, original.id);
  });
}
