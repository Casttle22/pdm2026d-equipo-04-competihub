import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> expectDetailText(WidgetTester tester, String value) async {
  await tester.scrollUntilVisible(
    find.text(value),
    160,
    scrollable: find.byType(Scrollable),
  );
  expect(find.text(value), findsOneWidget);
}

void main() {
  testWidgets('El detalle presenta datos generales y cómo participar', (
    tester,
  ) async {
    final competition = competenciasMock.first;
    await tester.pumpWidget(
      MaterialApp(
        home: CompetitionDetailScreen(
          competitionId: competition.id,
          competitions: competenciasMock,
        ),
      ),
    );

    expect(find.text(competition.titulo), findsOneWidget);
    expect(find.text('Identificador: ${competition.id}'), findsOneWidget);
    expect(find.text('Información general'), findsOneWidget);
    await expectDetailText(tester, 'Finaliza');
    await expectDetailText(tester, '20/10/2026 a las 21:00');
    await expectDetailText(tester, competition.modalidad);
    await expectDetailText(tester, competition.ubicacion);
    await expectDetailText(tester, competition.descripcion);
    await expectDetailText(tester, 'Información para participar');
    await expectDetailText(tester, competition.reglas);
    await expectDetailText(tester, competition.costo);
    await expectDetailText(tester, competition.instruccionesParticipacion);
    await expectDetailText(tester, competition.inscripcionUrl!);
    await expectDetailText(tester, competition.contacto!);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Otro id muestra su propio contenido sin datos duplicados', (
    tester,
  ) async {
    final competition = competenciasMock[1];
    await tester.pumpWidget(
      MaterialApp(
        home: CompetitionDetailScreen(
          competitionId: competition.id,
          competitions: competenciasMock,
        ),
      ),
    );

    expect(find.text(competition.titulo), findsOneWidget);
    expect(find.text(competenciasMock.first.titulo), findsNothing);
    await expectDetailText(tester, competition.descripcion);
    await expectDetailText(tester, competition.reglas);
    await expectDetailText(tester, competition.costo);
    await expectDetailText(tester, competition.instruccionesParticipacion);
    expect(competition.fechaFin, isNotNull);
    expect(competition.inscripcionUrl, isNull);
    expect(competition.contacto, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No inventa fecha final ni enlace cuando son opcionales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final competition = competenciasMock[2];
    await tester.pumpWidget(
      MaterialApp(
        home: CompetitionDetailScreen(
          competitionId: competition.id,
          competitions: competenciasMock,
        ),
      ),
    );

    expect(competition.fechaFin, isNull);
    await expectDetailText(tester, competition.instruccionesParticipacion);
    expect(find.text('Finaliza'), findsNothing);
    expect(find.text('Enlace de referencia'), findsNothing);
    await expectDetailText(tester, competition.contacto!);
    expect(tester.takeException(), isNull);
  });
}
