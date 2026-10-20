import 'package:competihub/data/mock_competencias.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:competihub/main.dart';

void main() {
  testWidgets('CompetiHub preserves its identity and labels fictional data', (
    tester,
  ) async {
    await tester.pumpWidget(const CompetihubApp());
    expect(find.widgetWithText(AppBar, 'CompetiHub'), findsOneWidget);
    expect(find.text('Explora competencias'), findsOneWidget);
    expect(
      find.text(
        'Competencias ficticias para desarrollo y pruebas. No son eventos reales.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Feed shows distinct mock competitions and scrolls to the last', (
    tester,
  ) async {
    await tester.pumpWidget(const CompetihubApp());

    for (final competition in [competenciasMock.first, competenciasMock.last]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(competition.id)),
        200,
        scrollable: find.byType(Scrollable),
      );
      final card = find.byKey(ValueKey(competition.id));
      expect(
        find.descendant(of: card, matching: find.text(competition.titulo)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(competition.categoria)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('Ubicación: ${competition.ubicacion}'),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Feed supports narrow mobile screens and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: HomeScreen(competitions: competenciasMock),
      ),
    );
    for (final competition in competenciasMock) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(competition.id)),
        150,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Feed uses the supplied collection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(competitions: [competenciasMock.last])),
    );
    expect(find.text(competenciasMock.last.titulo), findsOneWidget);
    expect(find.text(competenciasMock.first.titulo), findsNothing);
  });

  test(
    'Mock dataset contains unique identifiers and complete required data',
    () {
      expect(competenciasMock.length, inInclusiveRange(6, 8));
      expect(
        competenciasMock.map((competition) => competition.id).toSet().length,
        competenciasMock.length,
      );
      expect(
        competenciasMock.map((competition) => competition.categoria).toSet(),
        containsAll(['Esports', 'Académica', 'Deportiva', 'Otras']),
      );
      for (final competition in competenciasMock) {
        for (final value in [
          competition.id,
          competition.titulo,
          competition.categoria,
          competition.ubicacion,
          competition.modalidad,
          competition.descripcion,
          competition.reglas,
          competition.costo,
          competition.instruccionesParticipacion,
        ]) {
          expect(value.trim(), isNotEmpty, reason: competition.id);
        }
        expect(competition.fechaInicio.year, 2026);
        final endDate = competition.fechaFin;
        if (endDate != null) {
          expect(endDate.isBefore(competition.fechaInicio), isFalse);
        }
      }
    },
  );

  testWidgets('El filtro Esports y Todas actualizan el feed', (tester) async {
    await tester.pumpWidget(const CompetihubApp());

    final esportsCount = competenciasMock
        .where((competencia) => competencia.categoria == 'Esports')
        .length;

    // Seleccionar Esports.
    final chipEsports = find.widgetWithText(ChoiceChip, 'Esports');

    await tester.tap(chipEsports);
    await tester.pumpAndSettle();

    expect(tester.widget<ChoiceChip>(chipEsports).selected, isTrue);

    expect(find.text('$esportsCount competencias disponibles'), findsOneWidget);

    // Regresar a Todas.
    final chipTodas = find.widgetWithText(ChoiceChip, 'Todas');

    await tester.tap(chipTodas);
    await tester.pumpAndSettle();

    expect(tester.widget<ChoiceChip>(chipTodas).selected, isTrue);

    expect(
      find.text('${competenciasMock.length} competencias disponibles'),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('El feed muestra un estado vacío cuando no hay competencias', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(competitions: [])),
    );

    // Verificar que el contador indique cero resultados.
    expect(find.text('0 competencias disponibles'), findsOneWidget);

    // Verificar que aparezca el mensaje de estado vacío.
    expect(find.text('No se encontraron competencias'), findsOneWidget);

    expect(
      find.text('Todavía no hay competencias disponibles.'),
      findsOneWidget,
    );

    // No deben existir tarjetas de competencias.
    expect(find.byType(CompetitionCard), findsNothing);

    // La opción Todas debe permanecer disponible.
    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);

    // No deben producirse excepciones.
    expect(tester.takeException(), isNull);
  });

  for (final categoria in ['Esports', 'Académica', 'Deportiva', 'Otras']) {
    testWidgets('El feed filtra correctamente la categoría $categoria', (
      tester,
    ) async {
      await tester.pumpWidget(const CompetihubApp());

      final competenciasEsperadas = competenciasMock
          .where((competencia) => competencia.categoria == categoria)
          .toList();

      // Seleccionar la categoría.
      final filtro = find.widgetWithText(ChoiceChip, categoria);

      await tester.tap(filtro);
      await tester.pumpAndSettle();

      // Comprobar que quedó seleccionada.
      expect(tester.widget<ChoiceChip>(filtro).selected, isTrue);

      // Comprobar el contador.
      final cantidad = competenciasEsperadas.length;

      expect(
        find.text(
          cantidad == 1
              ? '1 competencia disponible'
              : '$cantidad competencias disponibles',
        ),
        findsOneWidget,
      );

      // Verificar la cantidad de elementos del feed.
      final lista = tester.widget<ListView>(find.byType(ListView));

      expect(lista.childrenDelegate.estimatedChildCount, cantidad + 1);

      // Comprobar que aparecen las competencias esperadas.
      for (final competencia in competenciasEsperadas) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey(competencia.id)),
          150,
        );

        final tarjeta = find.byKey(ValueKey(competencia.id));

        expect(
          find.descendant(of: tarjeta, matching: find.text(competencia.titulo)),
          findsOneWidget,
        );
      }

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('El filtro excluye otras categorias sin alterar los datos', (
    tester,
  ) async {
    // Utilizamos una pantalla amplia para visualizar todas
    // las tarjetas filtradas durante la prueba.
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Guardamos los identificadores originales.
    final idsOriginales = competenciasMock
        .map((competencia) => competencia.id)
        .toList();

    await tester.pumpWidget(const CompetihubApp());

    // Seleccionamos la categoria Academica.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Académica'));
    await tester.pumpAndSettle();

    final competenciasEsperadas = competenciasMock
        .where((competencia) => competencia.categoria == 'Académica')
        .toList();

    final competenciasExcluidas = competenciasMock
        .where((competencia) => competencia.categoria != 'Académica')
        .toList();

    // Solo deben existir las tarjetas de la categoria elegida.
    expect(
      find.byType(CompetitionCard),
      findsNWidgets(competenciasEsperadas.length),
    );

    // Las competencias Academicas deben aparecer.
    for (final competencia in competenciasEsperadas) {
      expect(find.byKey(ValueKey(competencia.id)), findsOneWidget);
    }

    // Las competencias de otras categorias no deben aparecer.
    for (final competencia in competenciasExcluidas) {
      expect(find.byKey(ValueKey(competencia.id)), findsNothing);
    }

    // La coleccion original debe permanecer sin modificaciones.
    expect(
      competenciasMock.map((competencia) => competencia.id).toList(),
      idsOriginales,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('El estado vacío se adapta a pantallas pequeñas', (tester) async {
    // Simular una pantalla móvil de 320 x 640.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const HomeScreen(competitions: []),
      ),
    );

    await tester.pumpAndSettle();

    // Verificar el contador.
    expect(find.text('0 competencias disponibles'), findsOneWidget);

    // Verificar los mensajes del estado vacío.
    expect(find.text('No se encontraron competencias'), findsOneWidget);

    expect(
      find.text('Todavía no hay competencias disponibles.'),
      findsOneWidget,
    );

    // Comprobar que Flutter no registre errores
    // de diseño, como desbordamientos.
    expect(tester.takeException(), isNull);
  });
}
