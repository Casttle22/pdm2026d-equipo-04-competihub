import 'dart:io';

import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:competihub/screens/mapa_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/widgets/mapa_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';
import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';
import 'fakes/teselas_de_prueba.dart';

// Módulo 10: mapa interactivo con OpenStreetMap (base v7).
void main() {
  final hoy = DateTime(2026, 11, 12, 9);
  final ejemplos = competenciasDeEjemplo(hoy);

  Competencia propia({double? latitud, double? longitud}) {
    final base = competenciasMock.first;
    return Competencia(
      id: 'local-punto',
      titulo: 'Torneo en el gimnasio',
      categoria: 'Deportiva',
      fechaInicio: DateTime(2026, 12, 20, 9),
      ubicacion: 'Gimnasio municipal',
      modalidad: 'Presencial',
      descripcion: base.descripcion,
      reglas: base.reglas,
      costo: base.costo,
      instruccionesParticipacion: base.instruccionesParticipacion,
      latitud: latitud,
      longitud: longitud,
    );
  }

  Widget app(
    Widget home, {
    List<Competencia>? datos,
    TeselasDePrueba? teselas,
    TransitionBuilder? builder,
  }) {
    return ProviderScope(
      overrides: [
        competenciasRepositoryProvider.overrideWithValue(
          FakeCompetenciasRepository.conDatos(datos ?? ejemplos),
        ),
        relojProvider.overrideWithValue(() => hoy),
        proveedorDeTeselasProvider.overrideWithValue(
          teselas ?? TeselasDePrueba(),
        ),
      ],
      child: MaterialApp(theme: temaCompetihub(), builder: builder, home: home),
    );
  }

  group('Datos', () {
    test('los ejemplos con lugar físico tienen coordenadas ficticias cerca '
        'de Quetzaltenango; los virtuales no', () {
      for (final ejemplo in competenciasMock) {
        if (ejemplo.modalidad == 'Virtual') {
          expect(ejemplo.tieneCoordenadas, isFalse, reason: ejemplo.id);
          continue;
        }
        expect(ejemplo.tieneCoordenadas, isTrue, reason: ejemplo.id);
        expect(
          (ejemplo.latitud! - latitudCentroDeEjemplo).abs(),
          lessThan(0.02),
        );
        expect(
          (ejemplo.longitud! - longitudCentroDeEjemplo).abs(),
          lessThan(0.02),
        );
      }
    });

    test('competenciasEnMapa deja solo presenciales e híbridas con punto', () {
      final ids = competenciasEnMapa([
        ...competenciasMock,
        propia(),
      ]).map((c) => c.id).toSet();
      expect(ids, {
        'mock-academic-01',
        'mock-sports-01',
        'mock-academic-02',
        'mock-esports-02',
      });
    });

    test(
      'la migración v6 → v7 agrega las columnas sin tocar a la persona',
      () async {
        final base = await BaseDePrueba.crear();
        final v6 = await base.abrir(version: 6, hoy: hoy);
        await v6.insert('competencias', {
          ...filaDeUsuarioV1(),
          'fecha_limite_inscripcion': null,
          'formato': null,
          'tamano_equipo_min': null,
          'tamano_equipo_max': null,
          'premios': null,
          'organizador': null,
        });
        await v6.insert('guardados', {
          'competencia_id': 'local-1',
          'guardado_en': 1,
        });
        final antes = (await v6.query(
          'competencias',
          where: 'id = ?',
          whereArgs: ['local-1'],
        )).single;
        await v6.close();

        final v7 = await base.abrir(version: 7, hoy: hoy);
        expect(await versionDe(v7), 7);
        final despues = (await v7.query(
          'competencias',
          where: 'id = ?',
          whereArgs: ['local-1'],
        )).single;
        expect(despues, {...antes, 'latitud': null, 'longitud': null});
        expect(await v7.query('guardados'), hasLength(1));
        final carrera = (await v7.query(
          'competencias',
          where: 'id = ?',
          whereArgs: ['mock-sports-01'],
        )).single;
        expect(carrera['latitud'], 14.8290);
        expect(carrera['longitud'], -91.5120);
        await v7.close();
      },
    );

    test('el punto se guarda y se puede quitar', () async {
      final base = await BaseDePrueba.crear();
      final datos = CompetenciasDatabase(
        openDatabase: () => base.abrir(version: versionEsquema, hoy: hoy),
        ahora: () => hoy,
      );
      final creada = await datos.crearCompetencia(
        propia(latitud: 14.84, longitud: -91.52).aBorrador(),
      );
      var leida = (await datos.obtenerCompetenciaPorId(creada.id))!;
      expect(leida.latitud, 14.84);
      expect(leida.longitud, -91.52);

      await datos.actualizarCompetencia(creada.id, propia().aBorrador());
      leida = (await datos.obtenerCompetenciaPorId(creada.id))!;
      expect(leida.tieneCoordenadas, isFalse);
    });
  });

  group('Configuración de OpenStreetMap', () {
    test('el userAgentPackageName coincide con el id de la app', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('applicationId = "$idDeLaApp"'));
    });

    test('el AndroidManifest principal pide permiso de internet', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        manifest,
        contains('<uses-permission android:name="android.permission.INTERNET"'),
      );
    });
  });

  group('Pestaña Mapa', () {
    testWidgets('muestra un marcador por competencia ubicable, el aviso de '
        'ficticias y la atribución', (tester) async {
      await tester.pumpWidget(app(const MapaScreen()));
      await tester.pumpAndSettle();

      for (final id in [
        'mock-academic-01',
        'mock-sports-01',
        'mock-academic-02',
        'mock-esports-02',
      ]) {
        expect(find.byKey(ValueKey('marcador-$id')), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('marcador-mock-esports-01')),
        findsNothing,
      );
      expect(find.text('Ubicaciones ficticias de ejemplo.'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(find.byKey(const ValueKey('mapa-sin-conexion')), findsNothing);
    });

    testWidgets('al tocar un marcador aparece una tarjeta breve que lleva al '
        'Detalle', (tester) async {
      await tester.pumpWidget(app(const MapaScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('marcador-mock-sports-01')));
      await tester.pumpAndSettle();
      final tarjeta = find.byKey(const ValueKey('mapa-tarjeta-breve'));
      expect(tarjeta, findsOneWidget);
      expect(
        find.descendant(
          of: tarjeta,
          matching: find.text('Carrera ficticia de cinco kilómetros'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('mapa-ver-detalle')));
      await tester.pumpAndSettle();
      expect(find.byType(CompetitionDetailScreen), findsOneWidget);
      expect(find.text('Identificador: mock-sports-01'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(tarjeta, findsNothing);
    });

    testWidgets('sin conexión muestra un estado claro y permite reintentar', (
      tester,
    ) async {
      final teselas = TeselasDePrueba(fallar: true);
      await tester.pumpWidget(app(const MapaScreen(), teselas: teselas));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mapa-sin-conexion')), findsOneWidget);
      expect(
        find.text('No se pudo cargar el mapa. Revisa tu conexión a internet.'),
        findsOneWidget,
      );

      // Vuelve la conexión.
      teselas.fallar = false;
      final antes = teselas.pedidas;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(teselas.pedidas, greaterThan(antes));
      expect(find.byKey(const ValueKey('mapa-sin-conexion')), findsNothing);
    });

    testWidgets('sin competencias ubicables explica cómo agregarlas', (
      tester,
    ) async {
      await tester.pumpWidget(app(const MapaScreen(), datos: [propia()]));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mapa-vacio')), findsOneWidget);
      expect(find.text('No hay competencias en el mapa'), findsOneWidget);
    });

    testWidgets('con una competencia propia no muestra el aviso de ficticias', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const MapaScreen(),
          datos: [propia(latitud: 14.84, longitud: -91.52)],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('marcador-local-punto')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('aviso-ubicacion-ficticia')),
        findsNothing,
      );
    });

    testWidgets('dentro de la app, la pestaña Mapa conserva la selección', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PantallaPrincipal()));
      await tester.pumpAndSettle();
      Future<void> pestana(String nombre) async {
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('barra-inferior')),
            matching: find.text(nombre),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pestana('Mapa');
      await tester.tap(find.byKey(const ValueKey('marcador-mock-sports-01')));
      await tester.pumpAndSettle();
      await pestana('Inicio');
      await pestana('Mapa');
      expect(find.byKey(const ValueKey('mapa-tarjeta-breve')), findsOneWidget);
    });
  });

  group('Detalle', () {
    testWidgets('una competencia con punto muestra el mapa pequeño', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const CompetitionDetailScreen(competitionId: 'mock-sports-01')),
      );
      await tester.pumpAndSettle();
      final mapa = find.byKey(const ValueKey('detalle-mapa'));
      await tester.scrollUntilVisible(
        mapa,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: mapa,
          matching: find.text('Ubicación ficticia de ejemplo.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: mapa,
          matching: find.text('© OpenStreetMap contributors'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin punto (o virtual) no hay mapa', (tester) async {
      await tester.pumpWidget(
        app(const CompetitionDetailScreen(competitionId: 'mock-esports-01')),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detalle-mapa')), findsNothing);
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

    testWidgets('elige un punto tocando el mapa, lo guarda y lo puede quitar', (
      tester,
    ) async {
      final guardados = <CompetenciaDraft>[];
      await tester.pumpWidget(
        app(
          CompetitionFormScreen(
            initial: propia(),
            onSave: (draft) async => guardados.add(draft),
          ),
        ),
      );
      final elegir = find.byKey(
        const ValueKey('competition-form-elegir-punto'),
      );
      await irA(tester, elegir);
      expect(find.text('Sin punto elegido'), findsOneWidget);
      await tester.tap(elegir);
      await tester.pumpAndSettle();

      // Sin tocar el mapa no se puede aceptar.
      final usar = find.byKey(const ValueKey('selector-usar-punto'));
      expect(tester.widget<FilledButton>(usar).onPressed, isNull);

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('selector-mapa'))),
      );
      // El mapa espera un instante por si es un doble toque.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.textContaining('Punto marcado:'), findsOneWidget);
      await tester.tap(usar);
      await tester.pumpAndSettle();

      // De vuelta en el formulario, con el punto (centro de Quetzaltenango,
      // porque se tocó el centro del mapa).
      expect(find.text('14.83470, -91.51810'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardados.single.latitud, closeTo(latitudCentroDeEjemplo, 1e-4));
      expect(guardados.single.longitud, closeTo(longitudCentroDeEjemplo, 1e-4));
    });

    testWidgets('Quitar punto deja la competencia sin coordenadas', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        app(
          CompetitionFormScreen(
            initial: propia(latitud: 14.84, longitud: -91.52),
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      final quitar = find.byKey(
        const ValueKey('competition-form-quitar-punto'),
      );
      await irA(tester, quitar);
      expect(find.text('14.84000, -91.52000'), findsOneWidget);
      await tester.tap(quitar);
      await tester.pumpAndSettle();
      expect(find.text('Sin punto elegido'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardado!.latitud, isNull);
      expect(guardado!.longitud, isNull);
    });
  });

  testWidgets('A 360 dp y texto 2.0: pestaña Mapa con tarjeta, Detalle con '
      'mapa y selector no se desbordan', (tester) async {
    usarTelefono360(tester);
    await tester.pumpWidget(app(const MapaScreen(), builder: textoGrande));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('marcador-mock-academic-02')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mapa-tarjeta-breve')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      app(
        const CompetitionDetailScreen(competitionId: 'mock-academic-02'),
        builder: textoGrande,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('detalle-mapa')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      app(
        CompetitionFormScreen(initial: propia(), onSave: (_) async {}),
        builder: textoGrande,
      ),
    );
    await tester.pumpAndSettle();
    final elegir = find.byKey(const ValueKey('competition-form-elegir-punto'));
    await tester.scrollUntilVisible(
      elegir,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(elegir);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
