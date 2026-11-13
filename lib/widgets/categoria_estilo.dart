import 'package:flutter/material.dart';

// Color e ícono de cada categoría, definidos en un solo lugar.
//
// - `estiloDeCategoria(...).color` es el color del TEXTO y los íconos de la
//   categoría sobre la superficie: oscuro en modo claro y un tono claro en
//   modo oscuro. Alcanza contraste AA (4,5:1) sobre su fondo suave en los dos
//   modos; lo comprueban test/categoria_estilo_test.dart y test/tema_test.dart.
// - `colorBaseDeCategoria` es el color oscuro de la categoría, el mismo en
//   los dos modos, para fondos con contenido blanco encima (los degradados de
//   las portadas sin imagen).
class EstiloCategoria {
  const EstiloCategoria({required this.color, required this.icono});

  final Color color;
  final IconData icono;
}

// Esports usaba el color principal del tema. Con el tema azul se confundía
// con Académica, así que tiene su propio violeta.
const Color colorEsports = Color(0xFF6A1B9A);
const Color colorAcademica = Color(0xFF0D47A1);
const Color colorDeportiva = Color(0xFF1B5E20);
const Color colorOtras = Color(0xFF9A3F00);

// Tonos claros de las mismas categorías, para texto en modo oscuro.
const Color colorEsportsOscuro = Color(0xFFE1BEE7);
const Color colorAcademicaOscuro = Color(0xFFBBDEFB);
const Color colorDeportivaOscuro = Color(0xFFC8E6C9);
const Color colorOtrasOscuro = Color(0xFFFFCC80);

IconData _iconoDe(String categoria) => switch (categoria) {
  'Esports' => Icons.sports_esports_outlined,
  'Académica' => Icons.school_outlined,
  'Deportiva' => Icons.sports_soccer_outlined,
  _ => Icons.emoji_events_outlined,
};

Color colorBaseDeCategoria(String categoria) => switch (categoria) {
  'Esports' => colorEsports,
  'Académica' => colorAcademica,
  'Deportiva' => colorDeportiva,
  _ => colorOtras,
};

Color _colorClaroDe(String categoria) => switch (categoria) {
  'Esports' => colorEsportsOscuro,
  'Académica' => colorAcademicaOscuro,
  'Deportiva' => colorDeportivaOscuro,
  _ => colorOtrasOscuro,
};

EstiloCategoria estiloDeCategoria(String categoria, ColorScheme scheme) {
  return EstiloCategoria(
    color: scheme.brightness == Brightness.dark
        ? _colorClaroDe(categoria)
        : colorBaseDeCategoria(categoria),
    icono: _iconoDe(categoria),
  );
}

// Fondo de una etiqueta: el color de la categoría al 12 % sobre la superficie.
Color fondoSuave(Color color, Color superficie) =>
    Color.alphaBlend(color.withValues(alpha: 0.12), superficie);
