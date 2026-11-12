import 'package:flutter/material.dart';

// Color e ícono de cada categoría, definidos en un solo lugar para el Feed y
// el Detalle. Los colores fijos se eligieron para que el texto alcance un
// contraste de 4,5:1 (WCAG AA) tanto sobre su fondo suave como debajo de
// texto blanco; test/categoria_estilo_test.dart lo comprueba.
class EstiloCategoria {
  const EstiloCategoria({required this.color, required this.icono});

  final Color color;
  final IconData icono;
}

const Color colorAcademica = Color(0xFF0D47A1);
const Color colorDeportiva = Color(0xFF1B5E20);
const Color colorOtras = Color(0xFF9A3F00);

EstiloCategoria estiloDeCategoria(String categoria, ColorScheme scheme) {
  return switch (categoria) {
    'Esports' => EstiloCategoria(
      color: scheme.primary,
      icono: Icons.sports_esports_outlined,
    ),
    'Académica' => const EstiloCategoria(
      color: colorAcademica,
      icono: Icons.school_outlined,
    ),
    'Deportiva' => const EstiloCategoria(
      color: colorDeportiva,
      icono: Icons.sports_soccer_outlined,
    ),
    _ => const EstiloCategoria(
      color: colorOtras,
      icono: Icons.emoji_events_outlined,
    ),
  };
}

// Fondo de una etiqueta: el color de la categoría al 12 % sobre la superficie.
Color fondoSuave(Color color, Color superficie) =>
    Color.alphaBlend(color.withValues(alpha: 0.12), superficie);
