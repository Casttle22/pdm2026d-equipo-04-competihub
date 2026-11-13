import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/media_competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/servicios/abridor_de_enlaces.dart';
import 'package:competihub/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';
import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Sección «Fotos y videos» del Detalle.
void main() {
  final hoy = DateTime(2026, 11, 12, 9);
  final ejemplos = competenciasDeEjemplo(hoy);

  Competencia propia({List<MediaCompetencia> galeria = const []}) {
    final base = ejemplos.firstWhere((c) => c.id == 'mock-sports-01');
    return Competencia.desdeBorrador(
      'local-galeria',
      base.aBorrador(),
      galeria: galeria,
    );
  }

  late List<Uri> abiertos;
  late bool resultado;

  setUp(() {
    abiertos = [];
    resultado = true;
  });

  Widget detalle(
    String id, {
    List<Competencia>? datos,
    TransitionBuilder? builder,
  }) {
    return ProviderScope(
      overrides: [
        competenciasRepositoryProvider.overrideWithValue(
          FakeCompetenciasRepository.conDatos(datos ?? ejemplos),
        ),
        relojProvider.overrideWithValue(() => hoy),
        abridorDeEnlacesProvider.overrideWithValue(
          AbridorDeEnlaces(
            lanzar: (uri) async {
              abiertos.add(uri);
              return resultado;
            },
          ),
        ),
      ],
      child: MaterialApp(
        theme: temaCompetihub(),
        builder: builder,
        home: CompetitionDetailScreen(competitionId: id),
      ),
    );
  }

  Future<void> irAGaleria(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('detalle-galeria')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('Datos', () {
    test('tres ejemplos traen galería; los videos son ficticios', () {
      final conGaleria = competenciasMock.where((c) => c.galeria.isNotEmpty);
      expect(conGaleria.map((c) => c.id).toSet(), {
        'mock-esports-01',
        'mock-sports-01',
        'mock-academic-02',
      });
      for (final ejemplo in conGaleria) {
        for (final media in ejemplo.galeria) {
          if (media.esVideo) {
            expect(media.fuente, startsWith('https://example.com/'));
            expect(media.titulo, contains('ficticio'));
          } else {
            expect(media.fuente, startsWith('assets/imagenes/'));
          }
        }
      }
    });

    test('la base de datos devuelve la galería de los ejemplos sin '
        'guardarla', () async {
      final base = await BaseDePrueba.crear();
      final datos = CompetenciasDatabase(
        openDatabase: () => base.abrir(version: versionEsquema, hoy: hoy),
        ahora: () => hoy,
      );
      final carrera = await datos.obtenerCompetenciaPorId('mock-sports-01');
      expect(carrera!.galeria, hasLength(3));
      final copa = await datos.obtenerCompetenciaPorId('mock-academic-01');
      expect(copa!.galeria, isEmpty);
    });
  });

  testWidgets('la sección aparece cuando hay elementos', (tester) async {
    await tester.pumpWidget(detalle('mock-sports-01'));
    await tester.pumpAndSettle();
    await irAGaleria(tester);
    expect(find.text('Fotos y videos'), findsOneWidget);
    expect(find.byKey(const ValueKey('galeria-0')), findsOneWidget);
  });

  testWidgets('sin galería, la sección no se muestra', (tester) async {
    tester.view.physicalSize = const Size(400, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(detalle('mock-academic-01'));
    await tester.pumpAndSettle();
    expect(find.text('Fotos y videos'), findsNothing);
    expect(find.byKey(const ValueKey('detalle-galeria')), findsNothing);
  });

  testWidgets('un video muestra su ícono de play y una foto no', (
    tester,
  ) async {
    await tester.pumpWidget(detalle('mock-sports-01'));
    await tester.pumpAndSettle();
    await irAGaleria(tester);

    // En la carrera: dos fotos y, al final, un video.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('galeria-0')),
        matching: find.byKey(const ValueKey('galeria-play')),
      ),
      findsNothing,
    );
    final video = find.byKey(const ValueKey('galeria-2'));
    await tester.ensureVisible(video);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: video,
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('una foto se abre en grande y se puede cerrar', (tester) async {
    await tester.pumpWidget(detalle('mock-sports-01'));
    await tester.pumpAndSettle();
    await irAGaleria(tester);

    await tester.tap(find.byKey(const ValueKey('galeria-0')));
    await tester.pumpAndSettle();
    final ampliada = find.byKey(const ValueKey('galeria-imagen-ampliada'));
    expect(ampliada, findsOneWidget);
    expect(
      find.descendant(
        of: ampliada,
        matching: find.text(
          'Foto: Petewarrior · CC BY 4.0 · Wikimedia Commons',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(ampliada, findsNothing);
  });

  testWidgets('en un ejemplo, el video avisa que es ficticio antes de '
      'abrirse', (tester) async {
    await tester.pumpWidget(detalle('mock-sports-01'));
    await tester.pumpAndSettle();
    await irAGaleria(tester);
    final video = find.byKey(const ValueKey('galeria-2'));
    await tester.ensureVisible(video);
    await tester.pumpAndSettle();

    await tester.tap(video);
    await tester.pumpAndSettle();
    expect(find.text('Video ficticio'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(abiertos, isEmpty);

    await tester.tap(video);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('video-abrir-igual')));
    await tester.pumpAndSettle();
    expect(
      abiertos.single.toString(),
      'https://example.com/competihub/video-ficticio-carrera',
    );
  });

  testWidgets('en una competencia propia, el video se abre directo y avisa '
      'si falla', (tester) async {
    resultado = false;
    final competencia = propia(
      galeria: const [
        MediaCompetencia(
          tipo: TipoMedia.video,
          fuente: 'https://example.com/mi-video',
          titulo: 'Mi video',
        ),
      ],
    );
    await tester.pumpWidget(detalle(competencia.id, datos: [competencia]));
    await tester.pumpAndSettle();
    await irAGaleria(tester);
    await tester.tap(find.byKey(const ValueKey('galeria-0')));
    await tester.pumpAndSettle();

    expect(find.text('Video ficticio'), findsNothing);
    expect(abiertos.single.toString(), 'https://example.com/mi-video');
    expect(find.text('No se pudo abrir el video.'), findsOneWidget);
  });

  testWidgets('el lector de pantalla distingue fotos y videos', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(detalle('mock-academic-02'));
    await tester.pumpAndSettle();
    await irAGaleria(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Foto: Tablero de ajedrez')),
      findsOneWidget,
    );
    final video = find.byKey(const ValueKey('galeria-2'));
    await tester.ensureVisible(video);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp(r'^Video: .*Se abre en otra app\.$')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a 360 dp y texto 2.0, la galería no se desborda', (
    tester,
  ) async {
    usarTelefono360(tester);
    await tester.pumpWidget(detalle('mock-sports-01', builder: textoGrande));
    await tester.pumpAndSettle();
    await irAGaleria(tester);
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const ValueKey('detalle-galeria')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
