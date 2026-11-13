import 'dart:math' as math;

import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/widgets/etiquetas_ficha.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 2: tema azul con contraste AA y Detalle en dos columnas.

// Contraste según WCAG 2: (claro + 0,05) / (oscuro + 0,05).
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final scheme = esquemaDeColor;

  test('El color principal es el azul de la marca', () {
    expect(scheme.primary, azulCompetihub);
    expect(scheme.brightness, Brightness.light);
  });

  // Cada par es (texto, fondo) tal como lo usa la interfaz.
  final pares = <String, (Color, Color)>{
    'texto sobre el color principal': (scheme.onPrimary, scheme.primary),
    'color principal sobre la superficie': (scheme.primary, scheme.surface),
    'texto sobre la superficie': (scheme.onSurface, scheme.surface),
    'texto secundario sobre la superficie': (
      scheme.onSurfaceVariant,
      scheme.surface,
    ),
    'texto secundario sobre superficie resaltada': (
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHighest,
    ),
    'etiqueta de estado': (scheme.onPrimaryContainer, scheme.primaryContainer),
    'aviso de datos ficticios': (
      scheme.onSecondaryContainer,
      scheme.secondaryContainer,
    ),
    'mensaje de error': (scheme.error, scheme.surface),
    'caja de error': (scheme.onErrorContainer, scheme.errorContainer),
  };
  // Fondo gris azulado de las pantallas y tarjetas blancas.
  pares['texto sobre el fondo de la app'] = (scheme.onSurface, fondoApp);
  pares['texto secundario sobre el fondo de la app'] = (
    scheme.onSurfaceVariant,
    fondoApp,
  );
  pares['color principal sobre el fondo de la app'] = (
    scheme.primary,
    fondoApp,
  );
  // Etiquetas de formato y modalidad.
  for (final (nombre, colores) in [
    ('Individual', coloresIndividual),
    ('Equipos', coloresEquipos),
    ('Presencial', coloresPresencial),
    ('Virtual', coloresVirtual),
    ('Híbrida', coloresHibrida),
  ]) {
    pares['etiqueta $nombre'] = (colores.texto, colores.fondo);
  }

  pares.forEach((nombre, par) {
    test('Contraste AA: $nombre', () {
      expect(contraste(par.$1, par.$2), greaterThanOrEqualTo(4.5));
    });
  });

  testWidgets('La app usa el tema azul', (tester) async {
    await tester.pumpWidget(
      conRepositorio(
        FakeCompetenciasRepository.conDatos(competenciasMock),
        const CompetihubApp(),
      ),
    );
    await tester.pumpAndSettle();
    final contexto = tester.element(find.text('CompetiHub'));
    expect(Theme.of(contexto).colorScheme.primary, azulCompetihub);
  });

  Widget detalle({TransitionBuilder? builder}) {
    return conRepositorio(
      FakeCompetenciasRepository.conDatos(competenciasMock),
      MaterialApp(
        theme: temaCompetihub(),
        builder: builder,
        home: CompetitionDetailScreen(competitionId: competenciasMock.first.id),
      ),
    );
  }

  testWidgets('Desde 600 dp, el Detalle usa dos columnas', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(detalle());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detalle-dos-columnas')), findsOneWidget);
    final general = tester.getTopLeft(find.text('Información general'));
    final participar = tester.getTopLeft(
      find.text('Información para participar'),
    );
    // La segunda sección empieza a la derecha, no debajo.
    expect(participar.dx, greaterThan(general.dx + 300));
    expect(participar.dy, lessThan(general.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('En un teléfono, el Detalle sigue en una columna', (
    tester,
  ) async {
    usarTelefono360(tester, alto: 3000);
    await tester.pumpWidget(detalle());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detalle-dos-columnas')), findsNothing);
    final general = tester.getTopLeft(find.text('Información general'));
    final participar = tester.getTopLeft(
      find.text('Información para participar'),
    );
    expect(participar.dx, general.dx);
    expect(participar.dy, greaterThan(general.dy));
  });

  testWidgets('A 360 dp y texto 2.0, el Detalle con el tema azul no se '
      'desborda', (tester) async {
    usarTelefono360(tester);
    await tester.pumpWidget(detalle(builder: textoGrande));
    await tester.pumpAndSettle();

    final lista = find.byType(Scrollable).first;
    for (final texto in [
      'Información general',
      'Información para participar',
      competenciasMock.first.contacto!,
    ]) {
      await tester.scrollUntilVisible(find.text(texto), 200, scrollable: lista);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: texto);
    }
  });

  testWidgets('En el límite de 600 dp con texto 2.0, las dos columnas no se '
      'desbordan', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(detalle(builder: textoGrande));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detalle-dos-columnas')), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
