import 'dart:math' as math;

import 'package:competihub/widgets/categoria_estilo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Contraste según WCAG 2: (claro + 0,05) / (oscuro + 0,05).
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // Mismo esquema de color que usa la app.
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  );
  const categorias = ['Esports', 'Académica', 'Deportiva', 'Otras'];

  for (final categoria in categorias) {
    test('$categoria: el texto de la etiqueta alcanza contraste AA', () {
      final estilo = estiloDeCategoria(categoria, scheme);
      final fondo = fondoSuave(estilo.color, scheme.surface);

      expect(contraste(estilo.color, fondo), greaterThanOrEqualTo(4.5));
    });

    test('$categoria: el texto blanco de la cabecera alcanza contraste AA', () {
      final estilo = estiloDeCategoria(categoria, scheme);

      expect(contraste(Colors.white, estilo.color), greaterThanOrEqualTo(4.5));
    });
  }

  test('una categoría desconocida usa el estilo de Otras', () {
    final desconocida = estiloDeCategoria('Categoría nueva', scheme);
    final otras = estiloDeCategoria('Otras', scheme);

    expect(desconocida.color, otras.color);
    expect(desconocida.icono, otras.icono);
  });
}
