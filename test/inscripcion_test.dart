import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';
import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 4: fecha límite de inscripción con estado (base v3).
void main() {
  // Miércoles 11 de noviembre de 2026, 10:30.
  final hoy = DateTime(2026, 11, 11, 10, 30);

  Competencia conLimite(
    DateTime? limite, {
    DateTime? inicio,
    String id = 'local-1',
  }) {
    final base = competenciasMock.first;
    return Competencia(
      id: id,
      titulo: 'Torneo con inscripción',
      categoria: base.categoria,
      fechaInicio: inicio ?? DateTime(2026, 12, 20, 9),
      ubicacion: base.ubicacion,
      modalidad: base.modalidad,
      descripcion: base.descripcion,
      reglas: base.reglas,
      costo: base.costo,
      instruccionesParticipacion: base.instruccionesParticipacion,
      fechaLimiteInscripcion: limite,
    );
  }

  group('Estado de la inscripción', () {
    test('sin fecha límite no se afirma nada', () {
      final competencia = conLimite(null);
      expect(estadoInscripcion(competencia, hoy), isNull);
      expect(etiquetaInscripcion(competencia, hoy), isNull);
    });

    test('faltando más de una semana: Inscripciones abiertas', () {
      final competencia = conLimite(DateTime(2026, 11, 19, 23, 59));
      expect(estadoInscripcion(competencia, hoy), EstadoInscripcion.abiertas);
      expect(etiquetaInscripcion(competencia, hoy), 'Inscripciones abiertas');
    });

    test('en la última semana: Cierra en N días', () {
      expect(
        etiquetaInscripcion(conLimite(DateTime(2026, 11, 18, 8)), hoy),
        'Cierra en 7 días',
      );
      expect(
        etiquetaInscripcion(conLimite(DateTime(2026, 11, 13, 23, 59)), hoy),
        'Cierra en 2 días',
      );
      expect(
        etiquetaInscripcion(conLimite(DateTime(2026, 11, 12, 0, 5)), hoy),
        'Cierra en 1 día',
      );
    });

    test('el mismo día, antes de la hora límite: Cierra hoy', () {
      final competencia = conLimite(DateTime(2026, 11, 11, 18));
      expect(estadoInscripcion(competencia, hoy), EstadoInscripcion.cierraHoy);
      expect(etiquetaInscripcion(competencia, hoy), 'Cierra hoy');
    });

    test('pasada la hora límite: Inscripciones cerradas', () {
      expect(
        etiquetaInscripcion(conLimite(DateTime(2026, 11, 11, 10)), hoy),
        'Inscripciones cerradas',
      );
      expect(
        etiquetaInscripcion(conLimite(DateTime(2026, 11, 1)), hoy),
        'Inscripciones cerradas',
      );
    });

    test('una competencia finalizada siempre tiene la inscripción cerrada', () {
      // Dato incoherente a propósito: límite futuro en un evento ya pasado.
      final competencia = conLimite(
        DateTime(2026, 12, 1),
        inicio: DateTime(2026, 10, 1, 9),
      );
      expect(etiquetaInscripcion(competencia, hoy), 'Inscripciones cerradas');
    });

    test('los ejemplos cubren los cuatro estados y uno queda sin límite', () {
      final estados = {
        for (final ejemplo in competenciasDeEjemplo(hoy))
          ejemplo.id: etiquetaInscripcion(ejemplo, hoy),
      };
      expect(estados['mock-esports-01'], 'Cierra en 2 días');
      expect(estados['mock-academic-01'], 'Cierra hoy');
      expect(estados['mock-sports-01'], 'Inscripciones abiertas');
      expect(estados['mock-other-01'], 'Inscripciones cerradas');
      expect(estados['mock-esports-02'], 'Inscripciones cerradas');
      expect(estados['mock-academic-02'], isNull);
    });
  });

  group('Base de datos v3', () {
    test('la migración v2 → v3 agrega la columna sin tocar los datos de la '
        'persona', () async {
      final base = await BaseDePrueba.crear();
      final v2 = await base.abrir(version: 2, hoy: hoy);
      final filaUsuario = filaDeUsuarioV1();
      await v2.insert('competencias', filaUsuario);
      await v2.close();

      final v3 = await base.abrir(version: 3, hoy: hoy);
      expect(await versionDe(v3), 3);
      final filas = {
        for (final fila in await v3.query('competencias'))
          fila['id']! as String: fila,
      };
      await v3.close();

      // La competencia de la persona conserva todo y queda sin límite.
      expect(filas['local-1'], {
        ...filaUsuario,
        'fecha_limite_inscripcion': null,
      });
      expect(filas.length, competenciasMock.length + 1);
      // Los ejemplos reciben su fecha límite.
      expect(
        filas['mock-esports-01']!['fecha_limite_inscripcion'],
        DateTime(2026, 11, 13, 23, 59).millisecondsSinceEpoch,
      );
      expect(filas['mock-academic-02']!['fecha_limite_inscripcion'], isNull);
    });

    test('la fecha límite se guarda, se lee y se puede quitar', () async {
      final base = await BaseDePrueba.crear();
      final datos = CompetenciasDatabase(
        // La capa de datos siempre trabaja con el esquema vigente.
        openDatabase: () => base.abrir(version: versionEsquema, hoy: hoy),
        ahora: () => hoy,
      );
      final limite = DateTime(2026, 12, 15, 18, 30);
      final borrador = conLimite(limite).aBorrador();

      final creada = await datos.crearCompetencia(borrador);
      expect(creada.fechaLimiteInscripcion, limite);
      final leida = await datos.obtenerCompetenciaPorId(creada.id);
      expect(leida!.fechaLimiteInscripcion, limite);

      await datos.actualizarCompetencia(creada.id, conLimite(null).aBorrador());
      final sinLimite = await datos.obtenerCompetenciaPorId(creada.id);
      expect(sinLimite!.fechaLimiteInscripcion, isNull);
    });
  });

  group('Interfaz', () {
    testWidgets('la tarjeta y el Detalle muestran el estado de inscripción', (
      tester,
    ) async {
      final competencia = conLimite(DateTime(2026, 11, 13, 23, 59));
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos([competencia]),
          MaterialApp(theme: temaCompetihub(), home: const HomeScreen()),
          ahora: hoy,
        ),
      );
      await tester.pumpAndSettle();

      final tarjeta = find.byKey(ValueKey(competencia.id));
      expect(
        find.descendant(of: tarjeta, matching: find.text('Cierra en 2 días')),
        findsOneWidget,
      );

      await tester.ensureVisible(tarjeta);
      await tester.pumpAndSettle();
      await tester.tap(tarjeta);
      await tester.pumpAndSettle();

      expect(find.byType(CompetitionDetailScreen), findsOneWidget);
      // En la cabecera.
      expect(find.text('Cierra en 2 días'), findsOneWidget);
      // Y con la fecha exacta en «Información para participar».
      final ficha = find.byKey(const ValueKey('detalle-inscripcion'));
      await tester.scrollUntilVisible(
        ficha,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: ficha,
          matching: find.text(
            'Cierra en 2 días\nFecha límite: 13/11/2026 a las 23:59',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin fecha límite no aparece ningún estado de inscripción', (
      tester,
    ) async {
      final competencia = conLimite(null);
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos([competencia]),
          const MaterialApp(home: HomeScreen()),
          ahora: hoy,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('etiqueta-inscripcion')), findsNothing);
      for (final texto in [
        'Inscripciones abiertas',
        'Inscripciones cerradas',
        'Cierra hoy',
      ]) {
        expect(find.text(texto), findsNothing);
      }
      expect(find.textContaining('Cierra en'), findsNothing);

      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos([competencia]),
          MaterialApp(
            home: CompetitionDetailScreen(competitionId: competencia.id),
          ),
          ahora: hoy,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('etiqueta-inscripcion')), findsNothing);
      expect(find.byKey(const ValueKey('detalle-inscripcion')), findsNothing);
    });

    testWidgets('un lector de pantalla recibe el estado de inscripción en el '
        'resumen de la tarjeta', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos([
            conLimite(DateTime(2026, 11, 11, 18)),
          ]),
          const MaterialApp(home: HomeScreen()),
          ahora: hoy,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'Cierra hoy\.')), findsWidgets);
      semantics.dispose();
    });
  });

  group('Formulario', () {
    Finder campoLimite() =>
        find.byKey(const ValueKey('competition-form-fecha-limite'));

    Future<void> irA(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('el límite no puede ser posterior al inicio', (tester) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            // El inicio es el 20 de diciembre; el límite, un día después.
            initial: conLimite(DateTime(2026, 12, 21, 9)),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();

      expect(guardado, isNull);
      await irA(
        tester,
        find.text('El límite de inscripción no puede ser posterior al inicio.'),
      );
      expect(
        find.text('El límite de inscripción no puede ser posterior al inicio.'),
        findsOneWidget,
      );
    });

    testWidgets('un límite igual o anterior al inicio se guarda', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      final limite = DateTime(2026, 12, 20, 9);
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conLimite(limite),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await irA(tester, campoLimite());
      expect(
        find.descendant(
          of: campoLimite(),
          matching: find.text('20/12/2026 a las 09:00'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardado!.fechaLimiteInscripcion, limite);
    });

    testWidgets('se puede elegir con los selectores y quitar con el botón', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: conLimite(null),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await irA(tester, campoLimite());

      // Vacío, los selectores proponen la fecha de inicio: se aceptan.
      await tester.tap(campoLimite());
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: campoLimite(),
          matching: find.text('20/12/2026 a las 09:00'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('competition-form-fecha-limite-limpiar')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardado, isNotNull);
      expect(guardado!.fechaLimiteInscripcion, isNull);
    });
  });

  testWidgets('A 360 dp y texto 2.0: tarjetas, Detalle y error del formulario '
      'sin desbordes', (tester) async {
    usarTelefono360(tester);
    final ejemplos = ordenarPorCercania(competenciasDeEjemplo(hoy), hoy);
    await tester.pumpWidget(
      conRepositorio(
        FakeCompetenciasRepository.conDatos(ejemplos),
        MaterialApp(
          theme: temaCompetihub(),
          builder: textoGrande,
          home: const HomeScreen(),
        ),
        ahora: hoy,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mock-esports-02')),
      300,
      scrollable: listaDeInicio,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Detalle de un ejemplo que cierra hoy.
    await tester.pumpWidget(
      conRepositorio(
        FakeCompetenciasRepository.conDatos(ejemplos),
        MaterialApp(
          theme: temaCompetihub(),
          builder: textoGrande,
          home: const CompetitionDetailScreen(
            competitionId: 'mock-academic-01',
          ),
        ),
        ahora: hoy,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cierra hoy'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('detalle-inscripcion')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Formulario con el error del límite.
    await tester.pumpWidget(
      MaterialApp(
        builder: textoGrande,
        home: CompetitionFormScreen(
          initial: conLimite(DateTime(2026, 12, 21, 9)),
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('competition-form-save')));
    await tester.pumpAndSettle();
    final error = find.text(
      'El límite de inscripción no puede ser posterior al inicio.',
    );
    await tester.scrollUntilVisible(
      error,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(error, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
