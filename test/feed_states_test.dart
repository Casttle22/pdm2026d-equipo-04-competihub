import 'dart:async';

import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';

// Pruebas S14 de los cuatro estados del Feed con un repositorio falso.
void main() {
  Widget feedCon(FakeCompetenciasRepository repositorio) {
    return conRepositorio(repositorio, const MaterialApp(home: HomeScreen()));
  }

  testWidgets('cargando -> datos: muestra el indicador hasta que responde', (
    tester,
  ) async {
    final lectura = Completer<List<Competencia>>();
    final repositorio = FakeCompetenciasRepository(() => lectura.future);

    await tester.pumpWidget(feedCon(repositorio));
    await tester.pump();

    // Mientras el Future no termina: estado de carga y ninguna tarjeta.
    // No se usa pumpAndSettle aquí: el indicador gira sin terminar.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando competencias...'), findsOneWidget);
    expect(find.byType(CompetitionCard), findsNothing);

    lectura.complete(competenciasMock);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(competenciasMock.first.titulo), findsOneWidget);
    expect(repositorio.llamadas, 1);
  });

  testWidgets('error -> Reintentar -> datos, sin reintento automático', (
    tester,
  ) async {
    final repositorio = FakeCompetenciasRepository(
      () async => throw Exception('fallo simulado de lectura'),
    );

    await tester.pumpWidget(feedCon(repositorio));
    await tester.pumpAndSettle();

    // 1-2. La primera lectura falla y aparece un mensaje para personas.
    expect(find.text('No pudimos cargar las competencias.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
    expect(find.textContaining('fallo simulado'), findsNothing);

    // 3. Aunque pase el tiempo, Riverpod no vuelve a consultar por su cuenta
    // (retry: (_, _) => null).
    await tester.pump(const Duration(seconds: 10));
    expect(repositorio.llamadas, 1);

    // 4. El falso ahora responde, pero la pantalla no cambia sin la acción.
    final segundaLectura = Completer<List<Competencia>>();
    repositorio.respuesta = () => segundaLectura.future;
    await tester.pump();
    expect(find.text('No pudimos cargar las competencias.'), findsOneWidget);
    expect(repositorio.llamadas, 1);

    // 5. Reintentar provoca una segunda consulta y vuelve a mostrar la carga.
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(repositorio.llamadas, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No pudimos cargar las competencias.'), findsNothing);

    // 6. Llegan los datos y el error anterior ya no se muestra.
    segundaLectura.complete(competenciasMock);
    await tester.pumpAndSettle();
    expect(find.text(competenciasMock.first.titulo), findsOneWidget);
    expect(
      find.text('${competenciasMock.length} competencias disponibles'),
      findsOneWidget,
    );
    expect(find.text('No pudimos cargar las competencias.'), findsNothing);
    expect(repositorio.llamadas, 2);
  });

  testWidgets('vacío: Volver a cargar consulta otra vez el repositorio', (
    tester,
  ) async {
    final repositorio = FakeCompetenciasRepository.conDatos([]);

    await tester.pumpWidget(feedCon(repositorio));
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no hay competencias disponibles.'),
      findsOneWidget,
    );
    expect(find.byType(CompetitionCard), findsNothing);
    expect(repositorio.llamadas, 1);

    repositorio.respuesta = () async => competenciasMock;
    await tester.tap(find.text('Volver a cargar'));
    await tester.pumpAndSettle();

    expect(repositorio.llamadas, 2);
    expect(find.text(competenciasMock.first.titulo), findsOneWidget);
  });

  testWidgets('vacío por filtro: Ver todas regresa a todas las competencias', (
    tester,
  ) async {
    final esports = competenciasMock.firstWhere(
      (competencia) => competencia.categoria == 'Esports',
    );
    final academica = competenciasMock.firstWhere(
      (competencia) => competencia.categoria == 'Académica',
    );
    final repositorio = FakeCompetenciasRepository.conDatos([esports]);

    await tester.pumpWidget(feedCon(repositorio));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Esports'));
    await tester.pumpAndSettle();

    // Los datos se recargan y ya no hay competencias de la categoría elegida.
    repositorio.respuesta = () async => [academica];
    ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    ).invalidate(competenciasProvider);
    await tester.pumpAndSettle();

    expect(
      find.text('Prueba otra categoría o selecciona Todas.'),
      findsOneWidget,
    );
    expect(find.text('Volver a cargar'), findsNothing);

    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todas'))
          .selected,
      isTrue,
    );
    expect(find.text(academica.titulo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
