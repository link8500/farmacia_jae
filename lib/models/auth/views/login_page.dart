import 'package:flutter/material.dart';
import '../../../core/services/auth_controller.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/pharmacy_brand.dart';

/// Único acceso al área interna. No incluye registro ni altas de usuarios.
class LoginPage extends StatefulWidget {
  const LoginPage({required this.auth, super.key});
  final AuthController auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  /// La navegación posterior la decide el guard, no el formulario.
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    final error = await widget.auth.signIn(_username.text, _password.text);
    if (mounted && error != null) setState(() => _error = error);
  }

  void _fillDemo(String username) {
    _username.text = username;
    _password.text = AuthController.demoPassword;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.auth,
    builder: (context, _) => Scaffold(
      backgroundColor: context.palette.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          final form = _buildForm(wide);
          if (!wide) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: form,
                  ),
                ),
              ),
            );
          }
          return Row(
            children: [
              const Expanded(child: _LoginStory()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(56),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: form,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildForm(bool wide) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide) ...[
          const PharmacyBrand(subtitle: 'Administración'),
          const SizedBox(height: 40),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: context.palette.paleBlue,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'ACCESO DEL PERSONAL',
            style: TextStyle(
              color: context.palette.blue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Bienvenido de nuevo',
          style: TextStyle(
            color: context.palette.ink,
            fontSize: 31,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Inicia sesión para continuar con la gestión de tu farmacia.',
          style: TextStyle(color: context.palette.muted, height: 1.6),
        ),
        const SizedBox(height: 32),
        const _FieldLabel('Usuario'),
        TextFormField(
          key: const Key('login-username'),
          controller: _username,
          enabled: !widget.auth.isSigningIn,
          keyboardType: TextInputType.text,
          autocorrect: false,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'usuario',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 19),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Ingresa tu usuario.'
              : null,
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Contraseña'),
        TextFormField(
          key: const Key('login-password'),
          controller: _password,
          enabled: !widget.auth.isSigningIn,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!widget.auth.isSigningIn) _submit();
          },
          decoration: InputDecoration(
            hintText: 'Ingresa tu contraseña',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19,
              ),
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Ingresa tu contraseña.' : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 51,
          child: FilledButton(
            key: const Key('login-submit'),
            onPressed: widget.auth.isSigningIn ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.auth.isSigningIn
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.palette.surface,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Iniciar sesión',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Las cuentas son asignadas por la administración.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.muted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.palette.canvas,
            border: Border.all(color: context.palette.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 17,
                    color: context.palette.muted,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Accesos rápidos',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Cuentas ficticias. La sesión solo vive en memoria y se pierde al recargar.',
                style: TextStyle(
                  color: context.palette.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: widget.auth.isSigningIn
                        ? null
                        : () => _fillDemo(AuthController.demoUsers[0].username),
                    child: const Text(
                      'Probar administrador',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: widget.auth.isSigningIn
                        ? null
                        : () => _fillDemo(AuthController.demoUsers[1].username),
                    child: const Text(
                      'Probar empleado',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            'Farmacia JAE · Administración',
            style: TextStyle(color: context.palette.muted, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.palette.ink,
      ),
    ),
  );
}

/// Panel visual estático. No contiene datos del negocio ni permisos de sesión.
class _LoginStory extends StatelessWidget {
  const _LoginStory();
  @override
  Widget build(BuildContext context) => Container(
    height: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.palette.heroStart, context.palette.heroEnd],
      ),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PharmacyBrand(subtitle: 'Espacio del personal'),
          const SizedBox(height: 74),
          Text(
            'Todo en su lugar.\nTu equipo, conectado.',
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.17,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Un espacio de trabajo para organizar la operación diaria y dedicar más tiempo a las personas.',
            style: TextStyle(
              color: context.palette.muted,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 35),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.palette.surface.withValues(alpha: .87),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.palette.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      color: context.palette.blue,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Una farmacia, un mismo equipo',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ...[
                  (
                    Icons.inventory_2_outlined,
                    'Inventario organizado',
                    'Productos, lotes y vencimientos.',
                  ),
                  (
                    Icons.point_of_sale_outlined,
                    'Atención más ágil',
                    'Facturación e inventario en un mismo flujo.',
                  ),
                  (
                    Icons.verified_user_outlined,
                    'Un acceso para cada rol',
                    'Administrador y personal operativo.',
                  ),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: context.palette.paleBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.$1,
                            color: context.palette.blue,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.$3,
                                style: TextStyle(
                                  color: context.palette.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'GESTIÓN INTERNA · FARMACIA JAE',
            style: TextStyle(
              color: context.palette.muted,
              fontSize: 10,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}
