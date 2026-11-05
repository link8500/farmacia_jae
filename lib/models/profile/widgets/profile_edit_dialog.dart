import 'package:flutter/material.dart';
import '../../../core/services/auth_controller.dart';
import '../../../core/services/profile_photo_picker.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/models/session_user.dart';
import '../models/profile_appearance.dart';

/// Borrador aislado: cerrar/cancelar no modifica el perfil. Solo Guardar envía
/// los campos personales permitidos al controlador, nunca rol o asignaciones.
class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({required this.auth, this.photoPicker, super.key});
  final AuthController auth;

  /// Inyección de pruebas: evita abrir selectores nativos durante las pruebas.
  final Future<String?> Function()? photoPicker;
  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _form = GlobalKey<FormState>();
  late final SessionUser _original;
  late final TextEditingController _name, _phone, _email;
  late ProfileSymbol _symbol;
  late ProfileTone _tone;
  late String _photo;
  late String _asset;
  bool _saving = false, _picking = false, _closing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _original = widget.auth.user!;
    _name = TextEditingController(text: _original.name);
    _phone = TextEditingController(text: _original.phone);
    _email = TextEditingController(text: _original.displayEmail);
    _symbol = _original.avatarSymbol;
    _tone = _original.avatarTone;
    _photo = _original.avatarPhoto;
    _asset = _original.avatarAsset;
    widget.auth.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (widget.auth.user?.id == _original.id || _closing) return;
    _closing = true;
    // Se retira esta ruta exacta, aunque un cambio de sesión ya haya iniciado
    // otra transición; nunca se hace pop de la nueva pantalla de login.
    final route = ModalRoute.of(context);
    Future.microtask(() {
      if (mounted && route?.isActive == true) {
        Navigator.of(context).removeRoute(route!, false);
      }
    });
  }

  @override
  void dispose() {
    widget.auth.removeListener(_sessionChanged);
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final photo = await (widget.photoPicker ?? selectProfilePhoto)();
      if (!mounted || widget.auth.user?.id != _original.id) return;
      if (photo != null) {
        if (ProfilePhoto.decode(photo) == null) {
          throw const FormatException('La foto seleccionada no es válida.');
        }
        setState(() {
          _photo = photo;
          _asset = '';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'No se pudo abrir la foto.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
    if (widget.auth.user?.id != _original.id) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = widget.auth.updateProfile(
      name: _name.text,
      phone: _phone.text,
      contactEmail: _email.text,
      avatarSymbol: _symbol,
      avatarTone: _tone,
      avatarPhoto: _photo,
      avatarAsset: _asset,
    );
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    await widget.auth.flushProfile();
    if (!mounted || widget.auth.user?.id != _original.id) return;
    if (widget.auth.profileStorageError != null) {
      setState(() {
        _saving = false;
        _error =
            '${widget.auth.profileStorageError} Puedes reintentar Guardar cambios.';
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _picking;
    final preview = _original.copyWith(
      name: _name.text.trim().isEmpty ? _original.name : _name.text,
      avatarSymbol: _symbol,
      avatarTone: _tone,
      avatarPhoto: _photo,
      avatarAsset: _asset,
    );
    return PopScope(
      canPop: !_saving,
      child: FormDialog(
        canClose: !_saving,
        title: 'Editar perfil',
        description:
            'Personaliza tus datos y tu avatar. Los cambios se guardan solo para tu cuenta en este navegador.',
        actions: [
          TextButton(
            key: const Key('profile-cancel'),
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            key: const Key('profile-save'),
            onPressed: busy ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
          ),
        ],
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: UserAvatar(
                  key: const Key('profile-avatar-preview'),
                  user: preview,
                  size: 88,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (supportsProfilePhoto || widget.photoPicker != null)
                    OutlinedButton.icon(
                      key: const Key('profile-photo-pick'),
                      onPressed: busy ? null : _pickPhoto,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _picking ? 'Preparando foto…' : 'Cargar foto',
                      ),
                    ),
                  if (_photo.isNotEmpty || _asset.isNotEmpty)
                    TextButton(
                      key: const Key('profile-photo-remove'),
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              _photo = '';
                              _asset = '';
                            }),
                      child: const Text('Quitar foto'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Icono del perfil',
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final symbol in ProfileSymbol.values)
                    Semantics(
                      selected: _photo.isEmpty && _symbol == symbol,
                      child: IconButton.outlined(
                        key: Key('profile-symbol-${symbol.name}'),
                        tooltip: symbol.label,
                        icon: symbol == ProfileSymbol.initials
                            ? const Icon(Icons.text_fields_rounded, size: 18)
                            : Icon(UserAvatar.symbols[symbol], size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: _photo.isEmpty && _symbol == symbol
                              ? context.palette.paleBlue
                              : null,
                          foregroundColor: _photo.isEmpty && _symbol == symbol
                              ? context.palette.blue
                              : context.palette.muted,
                          side: BorderSide(
                            color: _photo.isEmpty && _symbol == symbol
                                ? context.palette.blue
                                : context.palette.border,
                          ),
                        ),
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                _symbol = symbol;
                                _photo = '';
                                _asset = '';
                              }),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Color del avatar',
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tone in ProfileTone.values)
                    Semantics(
                      selected: _tone == tone,
                      child: IconButton.filled(
                        key: Key('profile-tone-${tone.name}'),
                        tooltip: tone.label,
                        onPressed: busy
                            ? null
                            : () => setState(() => _tone = tone),
                        style: IconButton.styleFrom(
                          backgroundColor: UserAvatar.tones[tone],
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          _tone == tone ? Icons.check : Icons.circle_outlined,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              TextFormField(
                key: const Key('profile-name'),
                controller: _name,
                enabled: !busy,
                maxLength: 100,
                validator: ProfileFields.name,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('profile-email'),
                controller: _email,
                enabled: !busy,
                validator: ProfileFields.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo de contacto (opcional)',
                  helperText: 'No cambia tu usuario de acceso.',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('profile-phone'),
                controller: _phone,
                enabled: !busy,
                validator: ProfileFields.phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto (opcional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'El rol, el usuario, la sucursal y la caja no se cambian desde este formulario. Las fotos se optimizan localmente; no se suben a ningún servidor.',
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    key: const Key('profile-edit-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
