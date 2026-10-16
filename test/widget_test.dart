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
}
