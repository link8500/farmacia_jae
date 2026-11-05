import '../services/auth_controller.dart';
import 'app_paths.dart';

/// Guard reutilizable y verificable sin construir la interfaz.
/// Bloquea enlaces privados. El acceso usa una URL limpia sin destino pendiente.
class AuthGuard {
  const AuthGuard(this.auth);
  final AuthController auth;

  String? redirect(Uri uri) {
    final path = uri.path;
    if (path == AppPaths.legacyLogin) return AppPaths.administration;
    if (path == AppPaths.administration) {
      // También limpia enlaces antiguos con ?desde=... y evita bucles.
      return uri.hasQuery || uri.hasFragment ? AppPaths.administration : null;
    }
    if (path == AppPaths.administration ||
        path.startsWith('${AppPaths.administration}/')) {
      if (!auth.isAuthenticated) {
        return AppPaths.administration;
      }
      // Un rol administrador tampoco puede abrir una función suspendida.
      if (AppPaths.disabledSections.contains(AppPaths.indexOf(path))) {
        return AppPaths.administration;
      }
      if (!_allowed(path)) return AppPaths.profile;
    }
    return null;
  }

  bool _allowed(String destination) {
    final path = Uri.parse(destination).path;
    return !AppPaths.disabledSections.contains(AppPaths.indexOf(path)) &&
        (auth.user?.isAdministrator == true ||
            !AppPaths.administratorOnly.contains(AppPaths.indexOf(path)));
  }
}
