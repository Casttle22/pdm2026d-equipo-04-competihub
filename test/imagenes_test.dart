import 'dart:io';

import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/creditos_imagenes.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/widgets/imagen_competencia.dart';
import 'package:competihub/widgets/tarjeta_competencia.dart'
    show CuadroDeCategoria;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';
import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Portadas locales de las competencias de ejemplo.
void main() {
  final hoy = DateTime(2026, 11, 12, 9);
  final ejemplos = competenciasDeEjemplo(hoy);

  group('Datos', () {
    test('cada ejemplo tiene una portada local que existe y tiene crédito', () {
      final portadas = <String>{};
      for (final ejemplo in competenciasMock) {
        final imagen = ejemplo.imagenUrl;
        expect(imagen, isNotNull, reason: ejemplo.id);
        expect(imagen, startsWith('assets/imagenes/'), reason: ejemplo.id);
        expect(File(imagen!).existsSync(), isTrue, reason: imagen);
        expect(creditoDeImagen(imagen), isNotNull, reason: imagen);
        portadas.add(imagen);
      }
      // Una distinta por competencia.
      expect(portadas, hasLength(competenciasMock.length));
    });

    test('todas las imágenes incluidas tienen crédito y están en docs', () {
      final documento = File('docs/creditos_imagenes.md').readAsStringSync();
      final archivos = Directory('assets/imagenes')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();
      expect(archivos, isNotEmpty);
      for (final archivo in archivos) {
        expect(
          creditosDeImagenes.containsKey('assets/imagenes/$archivo'),
          isTrue,
          reason: archivo,
        );
        expect(documento, contains('`$archivo`'), reason: archivo);
      }
    });

    test('pubspec.yaml declara la carpeta de imágenes', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/imagenes/'),
      );
    });
  });

  group('Base de datos v8', () {
    test(
      'pone la portada a los ejemplos sin imagen y no toca nada más',
      () async {
        final base = await BaseDePrueba.crear();
        final v7 = await base.abrir(version: 7, hoy: hoy);
        // Una base anterior: los ejemplos sin portada, uno con una imagen
        // elegida por la persona, y una competencia propia sin imagen.
        await v7.update('competencias', {'imagen_url': null});
        await v7.update(
          'competencias',
          {'imagen_url': 'https://example.com/mi-imagen.png'},
          where: 'id = ?',
          whereArgs: ['mock-sports-01'],
        );
        await v7.insert('competencias', {
          ...filaDeUsuarioV1(),
          'fecha_limite_inscripcion': null,
          'formato': null,
          'tamano_equipo_min': null,
          'tamano_equipo_max': null,
          'premios': null,
          'organizador': null,
          'latitud': null,
          'longitud': null,
        });
        await v7.close();

        final v8 = await base.abrir(version: 8, hoy: hoy);
        expect(await versionDe(v8), 8);
        final imagenes = {
          for (final fila in await v8.query('competencias'))
            fila['id']! as String: fila['imagen_url'],
        };
        await v8.close();

        expect(imagenes['local-1'], isNull);
        expect(imagenes['mock-sports-01'], 'https://example.com/mi-imagen.png');
        expect(
          imagenes['mock-esports-01'],
          'assets/imagenes/portada_esports.jpg',
        );
      },
    );
  });

  group('Interfaz', () {
    testWidgets('ImagenCompetencia usa el asset si la fuente es local', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ImagenCompetencia(
            imagenUrl: 'assets/imagenes/portada_logica.jpg',
            categoria: 'Académica',
          ),
        ),
      );
      final imagen = tester.widget<Image>(
        find.byKey(const ValueKey('imagen-asset')),
      );
      expect(imagen.image, isA<AssetImage>());
      expect(
        (imagen.image as AssetImage).assetName,
        'assets/imagenes/portada_logica.jpg',
      );
    });

    testWidgets('una fuente que no es asset ni http(s) usa el fondo', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ImagenCompetencia(
            imagenUrl: 'ftp://ejemplo/imagen.png',
            categoria: 'Otras',
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.byType(FondoDeCategoria), findsOneWidget);
    });

    testWidgets('el Detalle muestra la portada con su crédito', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos(ejemplos),
          MaterialApp(
            theme: temaCompetihub(),
            home: const CompetitionDetailScreen(
              competitionId: 'mock-sports-01',
            ),
          ),
          ahora: hoy,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detalle-imagen')), findsOneWidget);
      expect(
        find.text('Foto: Petewarrior · CC BY 4.0 · Wikimedia Commons'),
        findsOneWidget,
      );
    });

    testWidgets('la fila muestra la portada en el cuadro de 64 dp', (
      tester,
    ) async {
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos(ejemplos),
          MaterialApp(theme: temaCompetihub(), home: const HomeScreen()),
          ahora: hoy,
        ),
      );
      await tester.pumpAndSettle();
      final fila = find.byKey(const ValueKey('mock-academic-02'));
      await tester.scrollUntilVisible(fila, 200, scrollable: listaDeInicio);
      final cuadro = find.descendant(
        of: fila,
        matching: find.byType(CuadroDeCategoria),
      );
      expect(
        find.descendant(of: cuadro, matching: find.byType(ImagenCompetencia)),
        findsOneWidget,
      );
      expect(tester.getSize(cuadro), const Size(64, 64));
    });

    testWidgets('el formulario acepta la portada local al guardar un ejemplo', (
      tester,
    ) async {
      CompetenciaDraft? guardado;
      await tester.pumpWidget(
        MaterialApp(
          home: CompetitionFormScreen(
            initial: competenciasMock.first,
            onSave: (draft) async => guardado = draft,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('competition-form-save')));
      await tester.pumpAndSettle();
      expect(guardado, isNotNull);
      expect(guardado!.imagenUrl, 'assets/imagenes/portada_esports.jpg');
    });

    testWidgets('a 360 dp y texto 2.0, el Inicio y el Detalle con portadas '
        'no se desbordan', (tester) async {
      usarTelefono360(tester);
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
      await tester.drag(listaDeInicio, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final Competencia carrera = ejemplos.firstWhere(
        (c) => c.id == 'mock-sports-01',
      );
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos(ejemplos),
          MaterialApp(
            theme: temaCompetihub(),
            builder: textoGrande,
            home: CompetitionDetailScreen(competitionId: carrera.id),
          ),
          ahora: hoy,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
