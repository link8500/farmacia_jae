import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/preferences_controller.dart';
import 'package:farmacia_sae/core/services/preferences_store.dart';
import 'package:farmacia_sae/models/settings/models/app_preferences.dart';
import 'package:farmacia_sae/shared/themes/app_palette.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

class DelayedStore implements PreferencesStore {
  final readResult = Completer<String?>();
  final writes = <Completer<void>>[];
  final values = <String>[];
  @override
  Future<String?> read() => readResult.future;
  @override
  Future<void> write(String value) {
    values.add(value);
    final done = Completer<void>();
    writes.add(done);
    return done.future;
  }
}

class FailingStore extends MemoryPreferencesStore {
  bool fails = true;
  @override
  Future<void> write(String value) async {
    if (fails) throw StateError('Almacenamiento bloqueado');
    await super.write(value);
  }
}

void main() {
  test(
    'preferencias independientes por cuenta y restablecimiento solo personal',
    () async {
      final store = MemoryPreferencesStore();
      final prefs = PreferencesController(store);
      addTearDown(prefs.dispose);
      await prefs.initialize();
      prefs.useAccount('admin');
      prefs.setThemeMode(ThemeMode.dark);
      prefs.setAccent(AppAccent.teal);
      prefs.setDensity(WorkspaceDensity.compact);
      prefs.setHighContrast(true);
      prefs.useAccount('empleado');
      expect(prefs.value.themeMode, ThemeMode.system);
      expect(prefs.value.accent, AppAccent.blue);
      prefs.setThemeMode(ThemeMode.light);
      prefs.setCatalogLayout(CatalogLayout.list);
      prefs.setConfirmClearSale(false);
      await prefs.flush();
      final clone = PreferencesController(store);
      addTearDown(clone.dispose);
      await clone.initialize();
      clone.useAccount('admin');
      expect(clone.value.themeMode, ThemeMode.dark);
      expect(clone.value.accent, AppAccent.teal);
      expect(clone.value.highContrast, isTrue);
      expect(clone.value.density, WorkspaceDensity.compact);
      clone.useAccount('empleado');
      expect(clone.value.catalogLayout, CatalogLayout.list);
      expect(clone.value.confirmClearSale, isFalse);
      clone.restoreDefaults();
      clone.useAccount('admin');
      expect(clone.value.themeMode, ThemeMode.dark);
      clone.useAccount(null);
      expect(clone.value.themeMode, ThemeMode.system);
      expect(clone.accountId, isNull);
      await clone.flush();
      expect(jsonDecode(store.data!)['profiles'].keys.toSet(), {
        'user:admin',
        'user:empleado',
      });
    },
  );
  test(
    'guardar antes de leer no elimina preferencias de otras cuentas',
    () async {
      final store = MemoryPreferencesStore(
        jsonEncode({
          'version': 2,
          'profiles': {
            'user:otra': const AppPreferences(
              themeMode: ThemeMode.dark,
            ).toJson(),
          },
        }),
      );
      final prefs = PreferencesController(store)..useAccount('nueva');
      addTearDown(prefs.dispose);
      prefs.setAccent(AppAccent.violet);
      await prefs.flush();
      final saved = jsonDecode(store.data!)['profiles'];
      expect(saved['user:otra']['themeMode'], 'dark');
      expect(saved['user:nueva']['accent'], 'violet');
    },
  );
  test('lectura tardía y cambio de cuenta respetan cada propietario', () async {
    final store = DelayedStore();
    final prefs = PreferencesController(store)..useAccount('primera');
    addTearDown(prefs.dispose);
    final loading = prefs.initialize();
    prefs.setThemeMode(ThemeMode.dark);
    prefs.useAccount('segunda');
    store.readResult.complete(
      jsonEncode({
        'version': 2,
        'profiles': {
          'user:primera': const AppPreferences(
            themeMode: ThemeMode.light,
          ).toJson(),
          'user:segunda': const AppPreferences(
            accent: AppAccent.violet,
          ).toJson(),
        },
      }),
    );
    await loading;
    expect(prefs.value.accent, AppAccent.violet);
    prefs.useAccount('primera');
    expect(prefs.value.themeMode, ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    store.writes.single.complete();
    await prefs.flush();
  });
  test(
    'preferencias globales v1 se migran al login, sin atribuirlas a una cuenta',
    () async {
      final prefs = PreferencesController(
        MemoryPreferencesStore(
          jsonEncode(const AppPreferences(themeMode: ThemeMode.dark).toJson()),
        ),
      );
      addTearDown(prefs.dispose);
      await prefs.initialize();
      expect(prefs.value.themeMode, ThemeMode.dark);
      prefs.useAccount('admin');
      expect(prefs.value.themeMode, ThemeMode.system);
    },
  );
  test('acentos, contraste reforzado y densidad tienen efecto en el tema', () {
    for (final brightness in Brightness.values) {
      for (final accent in AppAccent.values) {
        final color = brightness == Brightness.dark
            ? accent.dark
            : accent.light;
        final theme = AppTheme.configured(
          brightness: brightness,
          accent: color,
          highContrast: true,
          compact: true,
        );
        expect(theme.colorScheme.primary, color);
        final palette = theme.extension<AppPalette>()!;
        expect(palette.muted, palette.ink);
        expect(theme.visualDensity.vertical, lessThan(0));
        final a = theme.colorScheme.primary.computeLuminance(),
            b = theme.colorScheme.onPrimary.computeLuminance();
        expect(
          (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });
  test('valores seguros y formatos locales corruptos o desconocidos', () async {
    for (final raw in [
      'no-json',
      '[]',
      '{"version":99}',
      '{"version":1,"themeMode":"otro","textSize":"enorme","confirmClearSale":0}',
    ]) {
      final prefs = PreferencesController(MemoryPreferencesStore(raw));
      await prefs.initialize();
      expect(prefs.value.themeMode, ThemeMode.system);
      expect(prefs.value.textSize, AppTextSize.standard);
      expect(prefs.value.confirmClearSale, isTrue);
      expect(prefs.isLoaded, isTrue);
      prefs.dispose();
    }
  });

  test(
    'guarda y recupera todas las preferencias sin incluir datos operativos',
    () async {
      final store = MemoryPreferencesStore();
      final prefs = PreferencesController(store);
      await prefs.initialize();
      prefs.setThemeMode(ThemeMode.dark);
      prefs.setTextSize(AppTextSize.extraLarge);
      prefs.setReduceMotion(true);
      prefs.setConfirmClearSale(false);
      prefs.setNotificationBadges(false);
      await prefs.flush();
      final loaded = PreferencesController(store);
      await loaded.initialize();
      expect(loaded.value.themeMode, ThemeMode.dark);
      expect(loaded.value.textSize, AppTextSize.extraLarge);
      expect(loaded.value.reduceMotion, isTrue);
      expect(loaded.value.confirmClearSale, isFalse);
      expect(loaded.value.showNotificationBadges, isFalse);
      final json = jsonDecode(store.data!) as Map<String, dynamic>;
      final saved = json['profiles']['guest'] as Map;
      expect(saved.keys.toSet(), {
        'version',
        'themeMode',
        'textSize',
        'reduceMotion',
        'confirmClearSale',
        'showNotificationBadges',
        'accent',
        'catalogLayout',
        'density',
        'highContrast',
      });
      prefs.dispose();
      loaded.dispose();
    },
  );

  test(
    'escrituras rápidas se procesan en orden, no pisan el último ajuste',
    () async {
      final store = DelayedStore();
      final prefs = PreferencesController(store);
      store.readResult.complete(null);
      await prefs.initialize();
      prefs.setThemeMode(ThemeMode.dark);
      prefs.setThemeMode(ThemeMode.light);
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, hasLength(1));
      store.writes.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, hasLength(2));
      store.writes.last.complete();
      await prefs.flush();
      expect(
        jsonDecode(store.values.last)['profiles']['guest']['themeMode'],
        'light',
      );
      expect(prefs.isSaving, isFalse);
      prefs.dispose();
    },
  );

  test(
    'una lectura tardía no revierte una elección reciente del usuario',
    () async {
      final store = DelayedStore();
      final prefs = PreferencesController(store);
      final loading = prefs.initialize();
      prefs.setThemeMode(ThemeMode.dark);
      store.readResult.complete(
        jsonEncode(const AppPreferences(themeMode: ThemeMode.light).toJson()),
      );
      await loading;
      expect(prefs.value.themeMode, ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      store.writes.single.complete();
      await prefs.flush();
      prefs.dispose();
    },
  );

  test('un error de guardado es visible y puede reintentarse', () async {
    final store = FailingStore();
    final prefs = PreferencesController(store);
    await prefs.initialize();
    prefs.setThemeMode(ThemeMode.dark);
    await prefs.flush();
    expect(prefs.value.themeMode, ThemeMode.dark);
    expect(prefs.storageError, isNotNull);
    store.fails = false;
    prefs.retrySave();
    await prefs.flush();
    expect(prefs.storageError, isNull);
    expect(jsonDecode(store.data!)['profiles']['guest']['themeMode'], 'dark');
    prefs.dispose();
  });

  test('restablecer solo escribe preferencias predeterminadas', () async {
    final store = MemoryPreferencesStore();
    final prefs = PreferencesController(store);
    await prefs.initialize();
    prefs.setThemeMode(ThemeMode.dark);
    prefs.setReduceMotion(true);
    prefs.restoreDefaults();
    await prefs.flush();
    expect(prefs.value.themeMode, ThemeMode.system);
    expect(prefs.value.reduceMotion, isFalse);
    expect(prefs.value.confirmClearSale, isTrue);
    expect(jsonDecode(store.data!)['version'], 2);
    prefs.dispose();
  });

  test(
    'cerrar el controlador durante una lectura no notifica después de dispose',
    () async {
      final store = DelayedStore();
      final prefs = PreferencesController(store);
      final loading = prefs.initialize();
      prefs.dispose();
      store.readResult.complete(null);
      await expectLater(loading, completes);
    },
  );

  test(
    'texto principal y secundario tienen contraste legible en ambas paletas',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
      }

      for (final palette in [AppPalette.light, AppPalette.dark]) {
        expect(
          contrast(palette.ink, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(palette.muted, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}
