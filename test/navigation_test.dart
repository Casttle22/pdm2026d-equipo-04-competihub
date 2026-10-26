import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';

void main() {
  testWidgets(
    'Cada tarjeta navega al detalle de su competencia y permite regresar',
    (tester) async {
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos(competenciasMock),
          const CompetihubApp(),
        ),
      );
      await tester.pumpAndSettle();

      for (final competition in competenciasMock) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey(competition.id)),
          200,
        );
        await tester.tap(find.byKey(ValueKey(competition.id)));
        await tester.pumpAndSettle();

        final detail = find.byType(CompetitionDetailScreen);
        expect(detail, findsOneWidget);
        expect(
          find.descendant(of: detail, matching: find.text(competition.titulo)),
          findsOneWidget,
        );
        expect(find.text('Identificador: ${competition.id}'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(CompetitionDetailScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('El filtro se conserva al regresar del detalle', (tester) async {
    await tester.pumpWidget(
      conRepositorio(
        FakeCompetenciasRepository.conDatos(competenciasMock),
        const CompetihubApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Esports'));
    await tester.pumpAndSettle();

    final competition = competenciasMock.firstWhere(
      (item) => item.categoria == 'Esports',
    );
    await tester.scrollUntilVisible(find.byKey(ValueKey(competition.id)), 200);
    await tester.tap(find.byKey(ValueKey(competition.id)));
    await tester.pumpAndSettle();
    expect(find.text('Identificador: ${competition.id}'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Esports'))
          .selected,
      isTrue,
    );
    final esportsCount = competenciasMock
        .where((item) => item.categoria == 'Esports')
        .length;
    expect(find.text('$esportsCount competencias disponibles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Un identificador inexistente muestra un estado comprensible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompetitionDetailScreen(
          competitionId: 'no-existe',
          competitions: competenciasMock,
        ),
      ),
    );
    expect(
      find.text('No se encontró la competencia seleccionada.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('El detalle utiliza tarjetas visuales y datos de la selección', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(find.text(competition.categoria), findsOneWidget);
    expect(find.text('Información general'), findsOneWidget);
    expect(find.text(competition.modalidad), findsOneWidget);
    await tester.scrollUntilVisible(find.text(competition.ubicacion), 150);
    expect(find.text(competition.ubicacion), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El detalle se adapta a una pantalla pequeña y texto ampliado', (
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
        home: CompetitionDetailScreen(
          competitionId: competenciasMock.first.id,
          competitions: competenciasMock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
