import 'package:flutter/material.dart';
import '../models/home/views/home.dart';
import '../shared/themes/app_theme.dart';

/// Widget raíz de Farmacia JAE.
///
/// Aquí se registra la configuración global de Flutter. La navegación y el
/// estado operativo se mantienen en los módulos que corresponden a cada área.
class FarmaciaApp extends StatelessWidget {
  /// Crea la aplicación principal.
  const FarmaciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmacia JAE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
