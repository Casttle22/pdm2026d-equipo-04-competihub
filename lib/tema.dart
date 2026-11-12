import 'package:flutter/material.dart';

// Tema de CompetiHub: azul, en la línea de start.gg y Unstop.
//
// El esquema parte del azul de marca. `fromSeed` suaviza el color principal,
// así que se fija el azul exacto: con texto blanco encima da un contraste de
// 5,7:1 (WCAG AA pide 4,5:1). test/tema_test.dart comprueba los pares de
// color que usa la interfaz.
const Color azulCompetihub = Color(0xFF1565C0);

final ColorScheme esquemaDeColor = ColorScheme.fromSeed(
  seedColor: azulCompetihub,
  brightness: Brightness.light,
).copyWith(primary: azulCompetihub, onPrimary: Colors.white);

// Ancho a partir del cual el Detalle pasa a dos columnas (tabletas y
// teléfonos en horizontal).
const double anchoDosColumnas = 600;

ThemeData temaCompetihub() {
  final scheme = esquemaDeColor;
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 1,
    ),
    // Los mensajes de error y de ayuda pueden ocupar varias líneas.
    inputDecorationTheme: const InputDecorationTheme(
      errorMaxLines: 6,
      helperMaxLines: 6,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
