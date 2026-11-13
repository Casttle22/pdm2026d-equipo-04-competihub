import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/explorar_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/utils/busqueda.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Pestaña Explorar: búsqueda con todos los filtros.
void main() {
  final hoy = DateTime(2026, 11, 12, 9);
  // Con estas fechas, 5 están por venir y mock-esports-02 ya finalizó.
  final ejemplos = ordenarPorCercania(competenciasDeEjemplo(hoy), hoy);

  group('aplicarFiltros', () {
    Set<String> ids(FiltrosExplorar filtros) =>
        aplicarFiltros(ejemplos, filtros, hoy).map((c) => c.id).toSet();

    test('por defecto deja fuera las finalizadas', () {
      expect(ids(const FiltrosExplorar()), hasLength(5));
      expect(ids(const FiltrosExplorar()), isNot(contains('mock-esports-02')));
      expect(
        ids(const FiltrosExplorar(incluirFinalizadas: true)),
        hasLength(6),
      );
    });

    test('filtra por categoría, modalidad y formato', () {
      expect(ids(const FiltrosExplorar(categoria: 'Académica')), {
        'mock-academic-01',
        'mock-academic-02',
      });
      expect(ids(const FiltrosExplorar(modalidad: 'Virtual')), {
        'mock-esports-01',
        'mock-other-01',
      });
      expect(ids(const FiltrosExplorar(formato: FormatoCompetencia.equipos)), {
        'mock-esports-01',
        'mock-academic-02',
      });
      expect(
        ids(
          const FiltrosExplorar(
            categoria: 'Académica',
            formato: FormatoCompetencia.individual,
          ),
        ),
        {'mock-academic-01'},
      );
    });

    test('inscripción abierta deja las que aún aceptan inscripciones', () {
      // Abiertas: esports-01 (cierra en 2 días), academic-01 (cierra hoy) y
      // sports-01 (abierta). other-01 cerró y academic-02 no tiene límite.
      expect(ids(const FiltrosExplorar(soloInscripcionAbierta: true)), {
        'mock-esports-01',
        'mock-academic-01',
        'mock-sports-01',
      });
    });

    test('combina la búsqueda con los filtros y ordena por cercanía', () {
      final resultado = aplicarFiltros(
        ejemplos,
        // «ficti» coincide con «ficticio» y «ficticia».
        const FiltrosExplorar(consulta: 'ficti', modalidad: 'Presencial'),
        hoy,
      );
      expect(resultado.map((c) => c.id), [
        'mock-academic-01',
        'mock-sports-01',
      ]);
    });

    test('hayFiltros no cuenta la búsqueda', () {
      expect(const FiltrosExplorar(consulta: 'copa').hayFiltros, isFalse);
      expect(const FiltrosExplorar(modalidad: 'Virtual').hayFiltros, isTrue);
      expect(
        const FiltrosExplorar(incluirFinalizadas: true).hayFiltros,
        isTrue,
      );
    });
  });

  group('Pantalla', () {
    Widget explorar({TransitionBuilder? builder}) {
      return conRepositorio(
        FakeCompetenciasRepository.conDatos(ejemplos),
        MaterialApp(
          theme: temaCompetihub(),
          builder: builder,
          home: const ExplorarScreen(),
        ),
        ahora: hoy,
      );
    }

    Finder pildora(String texto) => find.widgetWithText(ChoiceChip, texto);
    String conteo(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('explorar-conteo')))
        .data!;

    testWidgets('muestra todos los grupos de filtros y el conteo', (
      tester,
    ) async {
      await tester.pumpWidget(explorar());
      await tester.pumpAndSettle();

      for (final grupo in [
        'Categoría',
        'Modalidad',
        'Formato',
        'Más filtros',
      ]) {
        expect(find.text(grupo), findsOneWidget, reason: grupo);
      }
      expect(conteo(tester), '5 resultados');
      expect(
        find.byKey(const ValueKey('explorar-quitar-filtros')),
        findsNothing,
      );
    });

    testWidgets('cada filtro cambia los resultados y «Quitar filtros» vuelve '
        'al inicio', (tester) async {
      await tester.pumpWidget(explorar());
      await tester.pumpAndSettle();

      await tester.tap(pildora('Equipos'));
      await tester.pumpAndSettle();
      expect(conteo(tester), '2 resultados');

      await tester.tap(pildora('Híbrida'));
      await tester.pumpAndSettle();
      expect(conteo(tester), '1 resultado');
      expect(
        find.byKey(const ValueKey('explorar-mock-academic-02')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('explorar-quitar-filtros')));
      await tester.pumpAndSettle();
      expect(conteo(tester), '5 resultados');
      expect(tester.widget<ChoiceChip>(pildora('Equipos')).selected, isFalse);
    });

    testWidgets('incluir finalizadas e inscripción abierta', (tester) async {
      await tester.pumpWidget(explorar());
      await tester.pumpAndSettle();

      await tester.ensureVisible(pildora('Incluir finalizadas'));
      await tester.tap(pildora('Incluir finalizadas'));
      await tester.pumpAndSettle();
      expect(conteo(tester), '6 resultados');

      await tester.tap(pildora('Incluir finalizadas'));
      await tester.pumpAndSettle();
      await tester.tap(pildora('Inscripción abierta'));
      await tester.pumpAndSettle();
      expect(conteo(tester), '3 resultados');
    });

    testWidgets('sin resultados explica qué hacer y permite quitar filtros', (
      tester,
    ) async {
      await tester.pumpWidget(explorar());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('explorar-busqueda')),
        'ajedrez submarino',
      );
      await tester.pumpAndSettle();

      expect(conteo(tester), '0 resultados');
      expect(find.byKey(const ValueKey('explorar-vacio')), findsOneWidget);
      final quitar = find.byKey(const ValueKey('explorar-vacio-quitar'));
      await tester.ensureVisible(quitar);
      await tester.pumpAndSettle();
      await tester.tap(quitar);
      await tester.pumpAndSettle();
      expect(conteo(tester), '5 resultados');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('explorar-busqueda')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('una fila abre el Detalle', (tester) async {
      await tester.pumpWidget(explorar());
      await tester.pumpAndSettle();
      final fila = find.byKey(const ValueKey('explorar-mock-esports-01'));
      await tester.scrollUntilVisible(
        fila,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(fila);
      await tester.pumpAndSettle();
      expect(find.byType(CompetitionDetailScreen), findsOneWidget);
    });

    testWidgets('a 360 dp y texto 2.0 no se desborda', (tester) async {
      usarTelefono360(tester);
      await tester.pumpWidget(explorar(builder: textoGrande));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
