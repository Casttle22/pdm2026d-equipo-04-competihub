import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:competihub/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';
import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 5: ficha de torneo (base v4).
void main() {
  final hoy = DateTime(2026, 11, 12, 9);

  Competencia conFicha({
    FormatoCompetencia? formato,
    int? minimo,
    int? maximo,
    String? premios,
    String? organizador,
  }) {
    final base = competenciasMock.first;
    return Competencia(
      id: 'local-ficha',
      titulo: 'Torneo de la facultad',
      categoria: base.categoria,
      fechaInicio: DateTime(2026, 12, 20, 9),
      ubicacion: base.ubicacion,
      modalidad: base.modalidad,
      descripcion: base.descripcion,
      reglas: base.reglas,
      costo: base.costo,
      instruccionesParticipacion: base.instruccionesParticipacion,
      formato: formato,
      tamanoEquipoMin: minimo,
      tamanoEquipoMax: maximo,
      premios: premios,
      organizador: organizador,
    );
  }

  group('Modelo', () {
    test('describirTamanoEquipo cubre rango, fijo y un solo extremo', () {
      expect(describirTamanoEquipo(2, 5), 'De 2 a 5 personas por equipo');
      expect(describirTamanoEquipo(3, 3), '3 personas por equipo');
      expect(describirTamanoEquipo(2, null), 'Mínimo 2 personas por equipo');
      expect(describirTamanoEquipo(null, 1), 'Hasta 1 persona por equipo');
      expect(describirTamanoEquipo(null, null), isNull);
    });

    test('FormatoCompetencia se lee del texto guardado', () {
      expect(
        FormatoCompetencia.desdeTexto('equipos'),
        FormatoCompetencia.equipos,
      );
      expect(
        FormatoCompetencia.desdeTexto('individual'),
        FormatoCompetencia.individual,
      );
      expect(FormatoCompetencia.desdeTexto(null), isNull);
      expect(FormatoCompetencia.desdeTexto('otro'), isNull);
    });

    test(
      'la ficha de los ejemplos sale de sus reglas y se rotula ficticia',
      () {
        final porId = {for (final c in competenciasMock) c.id: c};
        expect(porId['mock-esports-01']!.formato, FormatoCompetencia.equipos);
        expect(porId['mock-esports-01']!.tamanoEquipoMin, 3);
        expect(porId['mock-academic-02']!.tamanoEquipoMax, 2);
        expect(
          porId['mock-esports-02']!.formato,
          FormatoCompetencia.individual,
        );
        // Sus reglas no dicen si es individual: no se inventa.
        expect(porId['mock-sports-01']!.tieneFichaDeTorneo, isFalse);
        for (final ejemplo in competenciasMock) {
          final premios = ejemplo.premios;
          if (premios != null) {
            expect(premios, contains('ficticio'), reason: ejemplo.id);
          }
          final organizador = ejemplo.organizador;
          if (organizador != null) {
            expect(organizador, contains('ficticio'), reason: ejemplo.id);
          }
        }
      },
    );
  });

  group('Base de datos v4', () {
    test('la migración v3 → v4 agrega la ficha sin tocar los datos de la '
        'persona', () async {
      final base = await BaseDePrueba.crear();
      final v3 = await base.abrir(version: 3, hoy: hoy);
      final filaUsuario = {
        ...filaDeUsuarioV1(),
        'fecha_limite_inscripcion': DateTime(2026, 3, 1).millisecondsSinceEpoch,
      };
      await v3.insert('competencias', filaUsuario);
      await v3.close();

      final v4 = await base.abrir(version: 4, hoy: hoy);
      expect(await versionDe(v4), 4);
      final filas = {
        for (final fila in await v4.query('competencias'))
          fila['id']! as String: fila,
      };
      await v4.close();

      expect(filas['local-1'], {
        ...filaUsuario,
        'formato': null,
        'tamano_equipo_min': null,
        'tamano_equipo_max': null,
        'premios': null,
        'organizador': null,
      });
      expect(filas['mock-esports-01']!['formato'], 'equipos');
      expect(filas['mock-esports-01']!['tamano_equipo_max'], 3);
      expect(filas['mock-sports-01']!['formato'], isNull);
    });

    test('la ficha se guarda y se lee completa', () async {
      final base = await BaseDePrueba.crear();
      final datos = CompetenciasDatabase(
        openDatabase: () => base.abrir(version: versionEsquema, hoy: hoy),
        ahora: () => hoy,
      );
      final creada = await datos.crearCompetencia(
        conFicha(
          formato: FormatoCompetencia.equipos,
          minimo: 2,
          maximo: 5,
          premios: 'Medallas',
          organizador: 'Asociación de estudiantes',
        ).aBorrador(),
      );
      final leida = (await datos.obtenerCompetenciaPorId(creada.id))!;
      expect(leida.formato, FormatoCompetencia.equipos);
      expect(leida.tamanoEquipoMin, 2);
      expect(leida.tamanoEquipoMax, 5);
      expect(leida.premios, 'Medallas');
      expect(leida.organizador, 'Asociación de estudiantes');
    });
  });

  group('Detalle', () {
    Widget detalle(Competencia competencia, {TransitionBuilder? builder}) {
      return conRepositorio(
        FakeCompetenciasRepository.conDatos([competencia]),
        MaterialApp(
          theme: temaCompetihub(),
          builder: builder,
          home: CompetitionDetailScreen(competitionId: competencia.id),
        ),
        ahora: hoy,
      );
    }

    Future<Finder> irASeccion(WidgetTester tester) async {
      final seccion = find.byKey(const ValueKey('detalle-formato-premios'));
      await tester.scrollUntilVisible(
        find.text('Formato y premios'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      return seccion;
    }

    testWidgets('muestra la sección «Formato y premios» con cada dato', (
      tester,
    ) async {
      usarTelefono360(tester, alto: 2400);
      await tester.pumpWidget(
        detalle(
          conFicha(
            formato: FormatoCompetencia.equipos,
            minimo: 2,
            maximo: 5,
            premios: 'Medallas',
            organizador: 'Asociación de estudiantes',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final seccion = await irASeccion(tester);

      for (final texto in [
        'Por equipos',
        'De 2 a 5 personas por equipo',
        'Medallas',
        'Asociación de estudiantes',
      ]) {
        expect(
          find.descendant(of: seccion, matching: find.text(texto)),
          findsOneWidget,
          reason: texto,
        );
      }
    });

    testWidgets('en formato individual no muestra tamaño de equipo', (
      tester,
    ) async {
      usarTelefono360(tester, alto: 2400);
      await tester.pumpWidget(
        detalle(conFicha(formato: FormatoCompetencia.individual, minimo: 2)),
      );
      await tester.pumpAndSettle();
      final seccion = await irASeccion(tester);

      expect(
        find.descendant(of: seccion, matching: find.text('Individual')),
        findsOneWidget,
      );
      expect(find.text('Tamaño del equipo'), findsNothing);
      expect(find.text('Premios'), findsNothing);
    });

    testWidgets('sin ningún dato de la ficha, la sección no aparece', (
      tester,
    ) async {
      usarTelefono360(tester, alto: 3000);
      await tester.pumpWidget(detalle(conFicha()));
      await tester.pumpAndSettle();
      expect(find.text('Formato y premios'), findsNothing);
    });

    testWidgets('a 360 dp y texto 2.0, la sección no se desborda', (
      tester,
    ) async {
      usarTelefono360(tester);
      await tester.pumpWidget(
        detalle(
          conFicha(
            formato: FormatoCompetencia.equipos,
            minimo: 2,
            maximo: 5,
            premios: 'Medallas y diplomas para los tres primeros lugares',
            organizador: 'Asociación de estudiantes de ingeniería',
          ),
          builder: textoGrande,
        ),
      );
      await tester.pumpAndSettle();
      await irASeccion(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Formulario', () {
    Future<void> irA(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Finder campo(String clave) =>
        find.byKey(ValueKey('competition-form-$clave'));

    Future<void> elegirFormato(WidgetTester tester, String opcion) async {
      await irA(tester, campo('formato'));
      await tester.tap(campo('formato'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(opcion).last);
      await tester.pumpAndSettle();
    }

    testWidgets('el tamaño de equipo solo aparece por equipos y se guarda', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conFicha(),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await irA(tester, campo('formato'));
      expect(campo('equipo-min'), findsNothing);

      await elegirFormato(tester, 'Por equipos');
      await irA(tester, campo('equipo-min'));
      await tester.enterText(campo('equipo-min'), '2');
      await tester.enterText(campo('equipo-max'), '4');
      await irA(tester, campo('premios'));
      await tester.enterText(campo('premios'), 'Medallas');
      await tester.enterText(campo('organizador'), 'Club de robótica');

      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();

      expect(guardado!.formato, FormatoCompetencia.equipos);
      expect(guardado!.tamanoEquipoMin, 2);
      expect(guardado!.tamanoEquipoMax, 4);
      expect(guardado!.premios, 'Medallas');
      expect(guardado!.organizador, 'Club de robótica');
    });

    testWidgets('al cambiar a individual, el tamaño de equipo no se guarda', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conFicha(
              formato: FormatoCompetencia.equipos,
              minimo: 3,
              maximo: 3,
            ),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await elegirFormato(tester, 'Individual');
      expect(campo('equipo-min'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardado!.formato, FormatoCompetencia.individual);
      expect(guardado!.tamanoEquipoMin, isNull);
      expect(guardado!.tamanoEquipoMax, isNull);
    });

    testWidgets('valida números y que el máximo no sea menor que el mínimo', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conFicha(formato: FormatoCompetencia.equipos),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await irA(tester, campo('equipo-min'));
      await tester.enterText(campo('equipo-min'), '5');
      await tester.enterText(campo('equipo-max'), '2');
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardado, isNull);
      expect(
        find.text('El máximo no puede ser menor que el mínimo.'),
        findsOneWidget,
      );

      await tester.enterText(campo('equipo-min'), 'tres');
      await tester.enterText(campo('equipo-max'), '');
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe un número entero entre 1 y 100.'),
        findsOneWidget,
      );
    });

    testWidgets('con «Sin especificar» y sin premios, la ficha queda vacía', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conFicha(formato: FormatoCompetencia.individual),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await elegirFormato(tester, 'Sin especificar');
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardado!.formato, isNull);
      expect(guardado!.premios, isNull);
      expect(guardado!.organizador, isNull);
    });

    testWidgets('a 360 dp y texto 2.0, los campos y errores no se desbordan', (
      tester,
    ) async {
      usarTelefono360(tester);
      await tester.pumpWidget(
        MaterialApp(
          builder: textoGrande,
          home: CompetitionFormScreen(
            initial: conFicha(formato: FormatoCompetencia.equipos),
            onSave: (_) async {},
          ),
        ),
      );
      await irA(tester, campo('equipo-max'));
      await tester.enterText(campo('equipo-min'), '5');
      await tester.enterText(campo('equipo-max'), '2');
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      await irA(
        tester,
        find.text('El máximo no puede ser menor que el mínimo.'),
      );
      await irA(tester, campo('organizador'));
      expect(tester.takeException(), isNull);
    });
  });
}
