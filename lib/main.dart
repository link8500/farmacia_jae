import 'package:flutter/material.dart';
import 'package:farmacia_sae/core/app.dart';

/// Reexporta el widget raíz para que las pruebas y entradas alternativas
/// puedan importar la aplicación desde un único punto público.
export 'package:farmacia_sae/core/app.dart';

/// Punto de entrada de la aplicación web de Farmacia JAE.
///
/// La configuración visual y la pantalla inicial viven en [FarmaciaApp].
/// Mantener este archivo pequeño facilita cambiar la plataforma de entrada
/// sin mezclarla con la lógica de negocio.
void main() {
  runApp(const FarmaciaApp());
}
