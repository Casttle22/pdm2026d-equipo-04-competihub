import 'dart:math' as math;

import 'package:competihub/tema.dart';
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
  // El esquema de color real de la app (lib/tema.dart).
  final scheme = esquemaDeColor;
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

  test('cada categoría conocida tiene un color distinto', () {
    final colores = {
      for (final categoria in categorias)
        estiloDeCategoria(categoria, scheme).color,
    };
    expect(colores.length, categorias.length);
  });

  test('una categoría desconocida usa el estilo de Otras', () {
    final desconocida = estiloDeCategoria('Categoría nueva', scheme);
    final otras = estiloDeCategoria('Otras', scheme);

    expect(desconocida.color, otras.color);
    expect(desconocida.icono, otras.icono);
  });
}
