import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/explorar_screen.dart';
import 'package:competihub/screens/mis_eventos_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';
import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 8: Mis eventos (base v6).
void main() {
  // Con estas fechas de ejemplo, 5 están por venir y 1 finalizó.
  final hoy = DateTime(2026, 11, 12, 9);
  final ejemplos = ordenarPorCercania(competenciasDeEjemplo(hoy), hoy);

  FakeCompetenciasRepository repositorio({Set<String> guardados = const {}}) {
    return FakeCompetenciasRepository.conDatos(ejemplos)
      ..guardados.addAll(guardados);
  }

  Widget app(
    FakeCompetenciasRepository repo, {
    Widget home = const PantallaPrincipal(),
    TransitionBuilder? builder,
  }) {
    return conRepositorio(
      repo,
      MaterialApp(theme: temaCompetihub(), builder: builder, home: home),
      ahora: hoy,
    );
  }

  Future<void> irAPestana(WidgetTester tester, String pestana) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('barra-inferior')),
        matching: find.text(pestana),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Base de datos v6', () {
    test(
      'la migración v5 → v6 crea guardados vacíos y no toca a la persona',
      () async {
        final base = await BaseDePrueba.crear();
        final v5 = await base.abrir(version: 5, hoy: hoy);
        await v5.insert('competencias', {
          ...filaDeUsuarioV1(),
          'fecha_limite_inscripcion': null,
          'formato': null,
          'tamano_equipo_min': null,
          'tamano_equipo_max': null,
          'premios': null,
          'organizador': null,
        });
        final antes = await v5.query('competencias');
        await v5.close();

        final v6 = await base.abrir(version: 6, hoy: hoy);
        expect(await versionDe(v6), 6);
        expect(await v6.query('guardados'), isEmpty);
        expect(await v6.query('competencias'), antes);
        await v6.close();
      },
    );

    test(
      'guarda, ignora duplicados, quita y se borra con la competencia',
      () async {
        final base = await BaseDePrueba.crear();
        final datos = CompetenciasDatabase(
          openDatabase: () => base.abrir(version: versionEsquema, hoy: hoy),
          ahora: () => hoy,
        );
        expect(await datos.obtenerIdsGuardados(), isEmpty);

        await datos.guardarCompetencia('mock-esports-01');
        await datos.guardarCompetencia('mock-esports-01');
        await datos.guardarCompetencia('mock-academic-01');
        expect(await datos.obtenerIdsGuardados(), {
          'mock-esports-01',
          'mock-academic-01',
        });

        await datos.quitarGuardado('mock-academic-01');
        expect(await datos.obtenerIdsGuardados(), {'mock-esports-01'});

        await datos.eliminarCompetencia('mock-esports-01');
        expect(await datos.obtenerIdsGuardados(), isEmpty);
      },
    );
  });

  group('Pestaña Mis eventos', () {
    testWidgets('vacía, explica cómo guardar y lleva a Explorar', (
      tester,
    ) async {
      await tester.pumpWidget(app(repositorio()));
      await tester.pumpAndSettle();
      await irAPestana(tester, 'Mis eventos');

      expect(find.text('Todavía no guardas competencias'), findsOneWidget);
      expect(find.textContaining('ícono de marcador'), findsOneWidget);

      // Desde la barra con Explorar, el botón lleva a esa pestaña.
      await tester.tap(find.text('Explorar competencias'));
      await tester.pumpAndSettle();
      expect(find.byType(ExplorarScreen), findsOneWidget);
      expect(find.byType(MisEventosScreen), findsNothing);
    });

    testWidgets('muestra las guardadas con las próximas primero', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          repositorio(
            guardados: {'mock-esports-02', 'mock-other-01', 'mock-esports-01'},
          ),
          home: const MisEventosScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final ids = tester
          .widgetList<CompetitionCard>(find.byType(CompetitionCard))
          .map((tarjeta) => tarjeta.competition.id)
          .toList();
      // esports-01 (en 3 días), other-01 (en 25) y la finalizada al final.
      expect(ids, ['mock-esports-01', 'mock-other-01', 'mock-esports-02']);
      expect(find.text('Próximas'), findsOneWidget);
      expect(find.text('Finalizadas'), findsOneWidget);
    });

    testWidgets('si falla la carga, ofrece reintentar', (tester) async {
      final repo = FakeCompetenciasRepository(
        () async => throw Exception('fallo simulado'),
      );
      await tester.pumpWidget(app(repo, home: const MisEventosScreen()));
      await tester.pumpAndSettle();
      expect(find.text('No pudimos cargar tus eventos.'), findsOneWidget);

      repo.respuesta = () async => ejemplos;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no guardas competencias'), findsOneWidget);
    });
  });

  group('Botón Guardar', () {
    testWidgets('desde la tarjeta guarda y la competencia aparece en Mis '
        'eventos', (tester) async {
      final repo = repositorio();
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();

      final boton = find.byKey(const ValueKey('guardar-mock-academic-02'));
      await tester.scrollUntilVisible(boton, 300, scrollable: listaDeInicio);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(repo.guardados, {'mock-academic-02'});
      expect(find.text('Guardada en Mis eventos.'), findsOneWidget);
      expect(tester.widget<IconButton>(boton).isSelected, isTrue);

      await irAPestana(tester, 'Mis eventos');
      expect(
        find.byKey(const ValueKey('guardada-mock-academic-02')),
        findsOneWidget,
      );
    });

    testWidgets('desde el Detalle guarda y quita, y la pestaña se actualiza', (
      tester,
    ) async {
      final repo = repositorio(guardados: {'mock-esports-01'});
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      await irAPestana(tester, 'Mis eventos');
      final tarjeta = find.byKey(const ValueKey('guardada-mock-esports-01'));
      await tester.tap(tarjeta);
      await tester.pumpAndSettle();
      expect(find.byType(CompetitionDetailScreen), findsOneWidget);

      final boton = find.byKey(const ValueKey('guardar-mock-esports-01'));
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: boton, matching: find.text('Guardada')),
        findsOneWidget,
      );
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(repo.guardados, isEmpty);
      expect(
        find.descendant(of: boton, matching: find.text('Guardar')),
        findsOneWidget,
      );
      expect(find.text('Quitada de Mis eventos.'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Todavía no guardas competencias'), findsOneWidget);
    });

    testWidgets('si guardar falla, lo dice y no cambia el estado', (
      tester,
    ) async {
      final repo = repositorio()..errorAlGuardar = Exception('disco lleno');
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();

      final boton = find.byKey(const ValueKey('guardar-mock-academic-02'));
      await tester.scrollUntilVisible(boton, 300, scrollable: listaDeInicio);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.text('No se pudo actualizar Mis eventos.'), findsOneWidget);
      expect(tester.widget<IconButton>(boton).isSelected, isFalse);
    });

    testWidgets('el lector de pantalla oye qué hace el botón y con qué '
        'competencia', (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = repositorio(guardados: {'mock-esports-01'});
      await tester.pumpWidget(
        app(
          repo,
          home: const CompetitionDetailScreen(
            competitionId: 'mock-academic-01',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          'Guardar «Reto ficticio de programación» en Mis eventos',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(app(repo, home: const MisEventosScreen()));
      await tester.pumpAndSettle();
      // En la tarjeta: el resumen y, aparte, el botón para quitarla. El
      // ícono se anuncia con su descripción (tooltip) y como seleccionado.
      final boton = find.byTooltip(
        'Quitar «Copa ficticia de arena digital» de Mis eventos',
      );
      expect(boton, findsOneWidget);
      expect(tester.getSemantics(boton), isSemantics(isSelected: true));
      expect(
        find.bySemanticsLabel(RegExp(r'^Copa ficticia de arena digital\.')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  testWidgets('A 360 dp y texto 2.0, tarjetas con botón, Detalle y Mis '
      'eventos no se desbordan', (tester) async {
    usarTelefono360(tester);
    final repo = repositorio(guardados: {'mock-esports-01', 'mock-esports-02'});
    await tester.pumpWidget(app(repo, builder: textoGrande));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mock-esports-02')),
      300,
      scrollable: listaDeInicio,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await irAPestana(tester, 'Mis eventos');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('guardada-mock-esports-01')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('detalle-acciones')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detalle-acciones')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
