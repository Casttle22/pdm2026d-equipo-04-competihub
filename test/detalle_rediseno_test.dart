import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Rediseño del Detalle según las maquetas: cabecera azul, tarjetas blancas
// con el ícono en un círculo y rejilla de dos columnas.
void main() {
  final hoy = DateTime(2026, 11, 12, 9);
  final ejemplos = ordenarPorCercania(competenciasDeEjemplo(hoy), hoy);

  Competencia propia() {
    final base = ejemplos.firstWhere((c) => c.id == 'mock-esports-01');
    return Competencia.desdeBorrador('local-propia', base.aBorrador());
  }

  Widget detalle(
    String id, {
    List<Competencia>? datos,
    TransitionBuilder? builder,
  }) {
    return conRepositorio(
      FakeCompetenciasRepository.conDatos(datos ?? ejemplos),
      MaterialApp(
        theme: temaCompetihub(),
        builder: builder,
        home: CompetitionDetailScreen(competitionId: id),
      ),
      ahora: hoy,
    );
  }

  void tamanoDePantalla(WidgetTester tester, Size tamano) {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('la cabecera rotula como ficticia solo a las de ejemplo', (
    tester,
  ) async {
    tamanoDePantalla(tester, const Size(400, 3000));
    await tester.pumpWidget(detalle('mock-esports-01'));
    await tester.pumpAndSettle();
    expect(find.text('Competencia ficticia de prueba'), findsOneWidget);
    expect(find.text('Esports'), findsOneWidget);
    expect(find.byIcon(Icons.sports_esports_outlined), findsWidgets);

    await tester.pumpWidget(detalle('local-propia', datos: [propia()]));
    await tester.pumpAndSettle();
    expect(find.text('Competencia ficticia de prueba'), findsNothing);
    expect(find.textContaining('Identificador'), findsNothing);
  });

  testWidgets('las secciones llevan su título', (tester) async {
    tamanoDePantalla(tester, const Size(400, 4000));
    await tester.pumpWidget(detalle('mock-academic-02'));
    await tester.pumpAndSettle();
    for (final titulo in [
      'Información general',
      'Etapas y cronograma',
      'Información para participar',
      'Formato y premios',
    ]) {
      expect(find.text(titulo), findsOneWidget, reason: titulo);
    }
  });

  testWidgets('las tarjetas cortas comparten fila y las largas ocupan el '
      'ancho completo', (tester) async {
    tamanoDePantalla(tester, const Size(400, 3000));
    await tester.pumpWidget(detalle('mock-esports-01'));
    await tester.pumpAndSettle();

    final fecha = tester.getRect(find.text('Fecha'));
    final hora = tester.getRect(find.text('Hora'));
    expect(hora.top, fecha.top);
    expect(hora.left, greaterThan(fecha.left + 100));

    // La ubicación y el contacto (con botón Copiar) van solos en su fila.
    final ubicacion = tester.getRect(find.text('Ubicación o acceso'));
    expect(ubicacion.left, fecha.left);
    final contacto = tester.getRect(find.text('Contacto'));
    expect(contacto.left, fecha.left);
    expect(find.byTooltip('Copiar contacto'), findsOneWidget);
  });

  testWidgets('con texto 2.0 todas las tarjetas van en una columna', (
    tester,
  ) async {
    tamanoDePantalla(tester, const Size(400, 6000));
    await tester.pumpWidget(detalle('mock-esports-01', builder: textoGrande));
    await tester.pumpAndSettle();

    final fecha = tester.getRect(find.text('Fecha'));
    final hora = tester.getRect(find.text('Hora'));
    expect(hora.left, fecha.left);
    expect(hora.top, greaterThan(fecha.bottom));
  });

  testWidgets('el ícono de cada tarjeta va en un círculo azul claro', (
    tester,
  ) async {
    tamanoDePantalla(tester, const Size(400, 3000));
    await tester.pumpWidget(detalle('mock-esports-01'));
    await tester.pumpAndSettle();

    final circulo = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.calendar_month_outlined),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoracion = circulo.decoration! as BoxDecoration;
    expect(decoracion.shape, BoxShape.circle);
    expect(decoracion.color, esquemaDeColor.primaryContainer);
  });

  testWidgets('a 360 dp y texto 2.0, el Detalle completo no se desborda', (
    tester,
  ) async {
    usarTelefono360(tester);
    await tester.pumpWidget(detalle('mock-academic-02', builder: textoGrande));
    await tester.pumpAndSettle();
    final lista = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      await tester.drag(lista, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
