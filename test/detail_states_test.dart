import 'dart:async';

import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';

// Pruebas S14: se reemplaza el repositorio, no el provider de resultado.
void main() {
  Widget detalleCon(FakeCompetenciasRepository repositorio, String id) {
    return conRepositorio(
      repositorio,
      MaterialApp(home: CompetitionDetailScreen(competitionId: id)),
    );
  }

  testWidgets('Cargando: mantiene el indicador hasta completar la lectura', (
    tester,
  ) async {
    final competencia = competenciasMock.first;
    final lectura = Completer<Competencia?>();
    final repositorio = FakeCompetenciasRepository.conDatos(competenciasMock)
      ..respuestaPorId = (_) => lectura.future;

    await tester.pumpWidget(detalleCon(repositorio, competencia.id));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando competencia...'), findsOneWidget);
    expect(find.text(competencia.titulo), findsNothing);
    expect(repositorio.llamadasPorId, 1);

    // Completar el Future antes de pumpAndSettle: el spinner gira sin fin.
    lectura.complete(competencia);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(competencia.titulo), findsOneWidget);
    expect(repositorio.idsConsultados, [competencia.id]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Error: Reintentar consulta el mismo id y recupera los datos', (
    tester,
  ) async {
    final competencia = competenciasMock.first;
    final repositorio = FakeCompetenciasRepository.conDatos(competenciasMock)
      ..respuestaPorId = (_) async => throw StateError('error de prueba');

    await tester.pumpWidget(detalleCon(repositorio, competencia.id));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar esta competencia.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
    expect(find.textContaining('error de prueba'), findsNothing);
    expect(
      find.text('No se encontró la competencia seleccionada.'),
      findsNothing,
    );

    // Sin reintentos automáticos en Riverpod 3.
    await tester.pump(const Duration(seconds: 10));
    expect(repositorio.llamadasPorId, 1);

    final segundaLectura = Completer<Competencia?>();
    repositorio.respuestaPorId = (_) => segundaLectura.future;
    await tester.pump();
    expect(repositorio.llamadasPorId, 1);
    expect(find.text('No pudimos cargar esta competencia.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(repositorio.llamadasPorId, 2);
    expect(repositorio.idsConsultados, [competencia.id, competencia.id]);
    expect(find.text('Cargando competencia...'), findsOneWidget);
    expect(find.text('No pudimos cargar esta competencia.'), findsNothing);

    segundaLectura.complete(competencia);
    await tester.pumpAndSettle();

    expect(find.text(competencia.titulo), findsOneWidget);
    expect(find.text('Identificador: ${competencia.id}'), findsOneWidget);
    expect(find.text('No pudimos cargar esta competencia.'), findsNothing);
    expect(repositorio.llamadasPorId, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No encontrada: null muestra el aviso y permite regresar', (
    tester,
  ) async {
    final repositorio = FakeCompetenciasRepository.conDatos(competenciasMock)
      ..respuestaPorId = (_) async => null;

    await tester.pumpWidget(
      conRepositorio(
        repositorio,
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const CompetitionDetailScreen(
                        competitionId: 'no-existe',
                      ),
                    ),
                  );
                },
                child: const Text('Abrir detalle'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    expect(
      find.text('No se encontró la competencia seleccionada.'),
      findsOneWidget,
    );
    expect(find.text('Volver a competencias'), findsOneWidget);
    expect(find.text('No pudimos cargar esta competencia.'), findsNothing);
    expect(repositorio.idsConsultados, ['no-existe']);

    await tester.tap(find.text('Volver a competencias'));
    await tester.pumpAndSettle();
    expect(find.byType(CompetitionDetailScreen), findsNothing);
    expect(find.text('Abrir detalle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Datos: un cambio de id no muestra la competencia anterior', (
    tester,
  ) async {
    final primera = competenciasMock.first;
    final segunda = competenciasMock[1];
    final repositorio = FakeCompetenciasRepository.conDatos(competenciasMock);

    await tester.pumpWidget(detalleCon(repositorio, primera.id));
    await tester.pumpAndSettle();
    expect(find.text(primera.titulo), findsOneWidget);
    expect(find.text('Identificador: ${primera.id}'), findsOneWidget);

    await tester.pumpWidget(detalleCon(repositorio, segunda.id));
    await tester.pumpAndSettle();
    expect(find.text(segunda.titulo), findsOneWidget);
    expect(find.text('Identificador: ${segunda.id}'), findsOneWidget);
    expect(find.text(primera.titulo), findsNothing);
    expect(find.text('Identificador: ${primera.id}'), findsNothing);
    expect(repositorio.idsConsultados, [primera.id, segunda.id]);
    expect(tester.takeException(), isNull);
  });
}
