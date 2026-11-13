import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/etapa.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:competihub/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';
import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 6: etapas y cronograma (base v5).
void main() {
  final hoy = DateTime(2026, 11, 12, 9);

  final grupos = Etapa(
    nombre: 'Fase de grupos',
    fechaHora: DateTime(2026, 12, 20, 9),
    descripcion: 'Todos contra todos.',
  );
  final semis = Etapa(
    nombre: 'Semifinales',
    fechaHora: DateTime(2026, 12, 20, 13),
  );
  final final_ = Etapa(nombre: 'Final', fechaHora: DateTime(2026, 12, 20, 17));

  Competencia conEtapas(List<Etapa> etapas, {String id = 'local-etapas'}) {
    final base = competenciasMock.first;
    return Competencia(
      id: id,
      titulo: 'Torneo con cronograma',
      categoria: base.categoria,
      fechaInicio: DateTime(2026, 12, 20, 9),
      fechaFin: DateTime(2026, 12, 20, 19),
      ubicacion: base.ubicacion,
      modalidad: base.modalidad,
      descripcion: base.descripcion,
      reglas: base.reglas,
      costo: base.costo,
      instruccionesParticipacion: base.instruccionesParticipacion,
      etapas: etapas,
    );
  }

  group('Estado de las etapas', () {
    final etapas = [grupos, semis, final_];

    test('antes de empezar, todas son próximas y ninguna es actual', () {
      expect(
        estadosDeEtapas(etapas, hoy, competenciaFinalizada: false),
        everyElement(EstadoEtapa.proxima),
      );
    });

    test('la actual es la última que ya empezó', () {
      expect(
        estadosDeEtapas(
          etapas,
          DateTime(2026, 12, 20, 14),
          competenciaFinalizada: false,
        ),
        [EstadoEtapa.completada, EstadoEtapa.actual, EstadoEtapa.proxima],
      );
      // Justo a la hora de inicio, la etapa ya es la actual.
      expect(
        estadosDeEtapas(
          etapas,
          DateTime(2026, 12, 20, 17),
          competenciaFinalizada: false,
        ).last,
        EstadoEtapa.actual,
      );
    });

    test('si la competencia finalizó, todas están completadas', () {
      expect(
        estadosDeEtapas(
          etapas,
          DateTime(2026, 12, 21),
          competenciaFinalizada: true,
        ),
        everyElement(EstadoEtapa.completada),
      );
    });

    test('las etapas de ejemplo siguen a la fecha de inicio', () {
      final inicio = DateTime(2026, 11, 15, 18);
      final etapasCopa = etapasDeEjemploDesde('mock-esports-01', inicio);
      expect(etapasCopa.map((e) => e.nombre), [
        'Fase de grupos',
        'Semifinales',
        'Final',
      ]);
      expect(etapasCopa.first.fechaHora, inicio);
      expect(etapasCopa.last.fechaHora, DateTime(2026, 11, 15, 20, 30));
      expect(etapasDeEjemploDesde('mock-sports-01', inicio), isEmpty);
    });
  });

  group('Base de datos v5', () {
    test('la migración v4 → v5 crea la tabla, siembra los ejemplos y no toca '
        'a la persona', () async {
      final base = await BaseDePrueba.crear();
      final v4 = await base.abrir(version: 4, hoy: hoy);
      final filaUsuario = {
        ...filaDeUsuarioV1(),
        'fecha_limite_inscripcion': null,
        'formato': 'equipos',
        'tamano_equipo_min': 5,
        'tamano_equipo_max': 7,
        'premios': 'Copa',
        'organizador': 'Facultad',
      };
      await v4.insert('competencias', filaUsuario);
      await v4.close();

      final v5 = await base.abrir(version: 5, hoy: hoy);
      expect(await versionDe(v5), 5);
      final usuario = await v5.query(
        'competencias',
        where: 'id = ?',
        whereArgs: ['local-1'],
      );
      expect(usuario.single, filaUsuario);
      expect(
        await v5.query(
          'etapas',
          where: 'competencia_id = ?',
          whereArgs: ['local-1'],
        ),
        isEmpty,
      );
      final etapasCopa = await v5.query(
        'etapas',
        where: 'competencia_id = ?',
        whereArgs: ['mock-esports-01'],
        orderBy: 'orden',
      );
      expect(etapasCopa.map((e) => e['nombre']), [
        'Fase de grupos',
        'Semifinales',
        'Final',
      ]);
      // La primera etapa coincide con el inicio guardado de la competencia.
      final copa = await v5.query(
        'competencias',
        where: 'id = ?',
        whereArgs: ['mock-esports-01'],
      );
      expect(etapasCopa.first['fecha_hora'], copa.single['fecha_inicio']);
      await v5.close();
    });

    test('guarda, reordena y reemplaza etapas; al borrar la competencia se '
        'borran sus etapas', () async {
      final base = await BaseDePrueba.crear();
      final datos = CompetenciasDatabase(
        openDatabase: () => base.abrir(version: versionEsquema, hoy: hoy),
        ahora: () => hoy,
      );
      final creada = await datos.crearCompetencia(
        conEtapas([grupos, semis, final_]).aBorrador(),
      );
      var leida = (await datos.obtenerCompetenciaPorId(creada.id))!;
      expect(leida.etapas, [grupos, semis, final_]);

      // Reordenar y quitar.
      await datos.actualizarCompetencia(
        creada.id,
        conEtapas([final_, grupos]).aBorrador(),
      );
      leida = (await datos.obtenerCompetenciaPorId(creada.id))!;
      expect(leida.etapas, [final_, grupos]);

      await datos.eliminarCompetencia(creada.id);
      final db = await base.abrir(version: versionEsquema, hoy: hoy);
      expect(
        await db.query(
          'etapas',
          where: 'competencia_id = ?',
          whereArgs: [creada.id],
        ),
        isEmpty,
      );
      await db.close();
    });

    test(
      'borrar una competencia de ejemplo también borra su cronograma',
      () async {
        final base = await BaseDePrueba.crear();
        final datos = CompetenciasDatabase(
          openDatabase: () => base.abrir(version: versionEsquema, hoy: hoy),
          ahora: () => hoy,
        );
        await datos.eliminarCompetencia('mock-esports-01');
        final db = await base.abrir(version: versionEsquema, hoy: hoy);
        expect(
          await db.query(
            'etapas',
            where: 'competencia_id = ?',
            whereArgs: ['mock-esports-01'],
          ),
          isEmpty,
        );
        // El de la otra competencia sigue ahí.
        expect(
          await db.query(
            'etapas',
            where: 'competencia_id = ?',
            whereArgs: ['mock-academic-02'],
          ),
          hasLength(2),
        );
        await db.close();
      },
    );
  });

  group('Detalle', () {
    Widget detalle(
      Competencia competencia, {
      required DateTime ahora,
      TransitionBuilder? builder,
    }) {
      return conRepositorio(
        FakeCompetenciasRepository.conDatos([competencia]),
        MaterialApp(
          theme: temaCompetihub(),
          builder: builder,
          home: CompetitionDetailScreen(competitionId: competencia.id),
        ),
        ahora: ahora,
      );
    }

    Future<void> irACronograma(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('detalle-cronograma')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la línea de tiempo con la etapa actual resaltada', (
      tester,
    ) async {
      usarTelefono360(tester, alto: 2600);
      await tester.pumpWidget(
        detalle(
          conEtapas([grupos, semis, final_]),
          ahora: DateTime(2026, 12, 20, 14),
        ),
      );
      await tester.pumpAndSettle();
      await irACronograma(tester);

      expect(find.text('Etapas y cronograma'), findsOneWidget);
      expect(find.text('Etapa actual'), findsOneWidget);
      // El rótulo «Etapa actual» está en la fila de Semifinales.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('etapa-1')),
          matching: find.text('Etapa actual'),
        ),
        findsOneWidget,
      );
      expect(find.text('Todos contra todos.'), findsOneWidget);
    });

    testWidgets('el lector de pantalla anuncia el estado de cada etapa', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      usarTelefono360(tester, alto: 2600);
      await tester.pumpWidget(
        detalle(
          conEtapas([grupos, semis, final_]),
          ahora: DateTime(2026, 12, 20, 14),
        ),
      );
      await tester.pumpAndSettle();
      await irACronograma(tester);

      expect(
        find.bySemanticsLabel(RegExp(r'^Fase de grupos\. Completada\.')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Semifinales\. Etapa actual\.')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Final\. Próxima\.')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('antes del evento no resalta ninguna etapa', (tester) async {
      usarTelefono360(tester, alto: 2600);
      await tester.pumpWidget(detalle(conEtapas([grupos, semis]), ahora: hoy));
      await tester.pumpAndSettle();
      await irACronograma(tester);
      expect(find.text('Etapa actual'), findsNothing);
    });

    testWidgets('sin etapas no aparece la sección', (tester) async {
      usarTelefono360(tester, alto: 3000);
      await tester.pumpWidget(detalle(conEtapas([]), ahora: hoy));
      await tester.pumpAndSettle();
      expect(find.text('Etapas y cronograma'), findsNothing);
    });

    testWidgets('a 360 dp y texto 2.0, la línea de tiempo no se desborda', (
      tester,
    ) async {
      usarTelefono360(tester);
      await tester.pumpWidget(
        detalle(
          conEtapas([grupos, semis, final_]),
          ahora: DateTime(2026, 12, 20, 14),
          builder: textoGrande,
        ),
      );
      await tester.pumpAndSettle();
      await irACronograma(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Editor del formulario', () {
    Future<void> irA(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> guardar(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
    }

    testWidgets('agrega una etapa con el diálogo', (tester) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conEtapas([]),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      final agregar = find.byKey(const ValueKey('editor-etapa-agregar'));
      await irA(tester, agregar);
      await tester.tap(agregar);
      await tester.pumpAndSettle();

      // Sin nombre ni fecha no se acepta.
      await tester.tap(find.byKey(const ValueKey('etapa-aceptar')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe el nombre de la etapa.'), findsOneWidget);
      expect(find.text('Elige la fecha y la hora.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('etapa-nombre')),
        'Inauguración',
      );
      await tester.tap(find.byKey(const ValueKey('etapa-fecha')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('etapa-aceptar')));
      await tester.pumpAndSettle();

      expect(find.text('1. Inauguración'), findsOneWidget);
      await guardar(tester);
      // Los selectores proponen la fecha de inicio de la competencia.
      expect(guardado!.etapas, [
        Etapa(nombre: 'Inauguración', fechaHora: DateTime(2026, 12, 20, 9)),
      ]);
    });

    testWidgets('reordena, edita y quita etapas', (tester) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conEtapas([grupos, semis, final_]),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      // Bajar «Fase de grupos» un lugar.
      final bajar = find.byKey(const ValueKey('editor-etapa-0-bajar'));
      await irA(tester, bajar);
      await tester.tap(bajar);
      await tester.pumpAndSettle();
      expect(find.text('1. Semifinales'), findsOneWidget);
      expect(find.text('2. Fase de grupos'), findsOneWidget);
      // La primera no se puede subir ni la última bajar.
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('editor-etapa-0-subir')),
            )
            .onPressed,
        isNull,
      );

      // Editar el nombre de la final.
      final editar = find.byKey(const ValueKey('editor-etapa-2-editar'));
      await irA(tester, editar);
      await tester.tap(editar);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('etapa-nombre')),
        'Gran final',
      );
      await tester.tap(find.byKey(const ValueKey('etapa-aceptar')));
      await tester.pumpAndSettle();

      // Quitar las semifinales (ahora primeras).
      final quitar = find.byKey(const ValueKey('editor-etapa-0-quitar'));
      await irA(tester, quitar);
      await tester.tap(quitar);
      await tester.pumpAndSettle();

      await guardar(tester);
      expect(guardado!.etapas, [
        grupos,
        final_.copiarCon(nombre: 'Gran final'),
      ]);
    });

    testWidgets('cambiar las etapas cuenta como cambio sin guardar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompetitionFormScreen(
                    initial: conEtapas([grupos, semis]),
                    onSave: (_) async {},
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      final quitar = find.byKey(const ValueKey('editor-etapa-1-quitar'));
      await irA(tester, quitar);
      await tester.tap(quitar);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar cambios?'), findsOneWidget);
    });

    testWidgets('a 360 dp y texto 2.0, el editor y el diálogo no se '
        'desbordan', (tester) async {
      usarTelefono360(tester);
      await tester.pumpWidget(
        MaterialApp(
          builder: textoGrande,
          home: CompetitionFormScreen(
            initial: conEtapas([grupos, semis]),
            onSave: (_) async {},
          ),
        ),
      );
      final agregar = find.byKey(const ValueKey('editor-etapa-agregar'));
      await irA(tester, agregar);
      expect(tester.takeException(), isNull);

      await tester.tap(agregar);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('etapa-aceptar')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
