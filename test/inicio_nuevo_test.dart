import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/inicio_screen.dart' show CarruselDestacados;
import 'package:competihub/tema.dart';
import 'package:competihub/widgets/imagen_competencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 3: Inicio con búsqueda, filtros con ícono, Destacados y Próximos.
void main() {
  // 1 de septiembre de 2026: las seis competencias de ejemplo están por
  // venir. Las tres más cercanas son esports-02 (12 sep), esports-01 (20 oct)
  // y academic-01 (24 oct).
  final septiembre = DateTime(2026, 9, 1, 12);
  const idsDestacados = [
    'mock-esports-02',
    'mock-esports-01',
    'mock-academic-01',
  ];

  Widget inicio({
    List<Competencia>? datos,
    DateTime? ahora,
    TransitionBuilder? builder,
  }) {
    return conRepositorio(
      FakeCompetenciasRepository.conDatos(datos ?? competenciasMock),
      MaterialApp(
        theme: temaCompetihub(),
        builder: builder,
        home: const HomeScreen(),
      ),
      ahora: ahora ?? septiembre,
    );
  }

  Future<void> buscar(WidgetTester tester, String texto) async {
    await tester.enterText(
      find.byKey(const ValueKey('inicio-busqueda')),
      texto,
    );
    await tester.pumpAndSettle();
  }

  group('Búsqueda', () {
    testWidgets('filtra por título sin distinguir mayúsculas ni tildes', (
      tester,
    ) async {
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();
      await buscar(tester, 'LOGICA');

      expect(find.text('1 competencia disponible'), findsOneWidget);
      expect(find.byKey(const ValueKey('mock-academic-02')), findsOneWidget);
      expect(find.byType(CompetitionCard), findsOneWidget);
    });

    testWidgets('filtra por ubicación y por descripción', (tester) async {
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();

      await buscar(tester, 'parque nube');
      expect(find.byType(CompetitionCard), findsOneWidget);
      expect(find.byKey(const ValueKey('mock-sports-01')), findsOneWidget);

      await buscar(tester, 'acertijos');
      expect(find.byType(CompetitionCard), findsOneWidget);
      expect(find.byKey(const ValueKey('mock-academic-02')), findsOneWidget);
    });

    testWidgets('se combina con el filtro de categoría', (tester) async {
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Esports'));
      await tester.pumpAndSettle();
      await buscar(tester, 'ficticia');

      // «ficticia» aparece en varias categorías; quedan solo las de Esports.
      expect(find.text('2 competencias disponibles'), findsOneWidget);
      expect(find.byKey(const ValueKey('mock-esports-01')), findsOneWidget);
      expect(find.byKey(const ValueKey('mock-sports-01')), findsNothing);
    });

    testWidgets('sin resultados explica qué pasó y permite borrar la '
        'búsqueda', (tester) async {
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();
      await buscar(tester, 'ajedrez submarino');

      expect(find.text('0 competencias disponibles'), findsOneWidget);
      expect(
        find.text('Sin resultados para «ajedrez submarino»'),
        findsOneWidget,
      );
      expect(
        find.text('Revisa la ortografía o prueba con otras palabras.'),
        findsOneWidget,
      );
      expect(find.byType(CompetitionCard), findsNothing);
      expect(find.byType(TarjetaDestacada), findsNothing);
      // No se ofrece «Volver a cargar»: los datos están bien.
      expect(find.text('Volver a cargar'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('inicio-borrar-busqueda')));
      await tester.pumpAndSettle();

      expect(find.text('6 competencias disponibles'), findsOneWidget);
      expect(
        find.text('Sin resultados para «ajedrez submarino»'),
        findsNothing,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('inicio-busqueda')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('el botón de la caja de texto también borra la búsqueda', (
      tester,
    ) async {
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Borrar búsqueda'), findsNothing);

      await buscar(tester, 'carrera');
      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pumpAndSettle();

      expect(find.text('6 competencias disponibles'), findsOneWidget);
    });
  });

  testWidgets('Cada filtro de categoría lleva su ícono', (tester) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();

    const iconos = {
      'Esports': Icons.sports_esports_outlined,
      'Académica': Icons.school_outlined,
      'Deportiva': Icons.sports_soccer_outlined,
      'Otras': Icons.emoji_events_outlined,
    };
    iconos.forEach((categoria, icono) {
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, categoria),
      );
      expect((chip.avatar! as Icon).icon, icono, reason: categoria);
    });
  });

  group('Destacados y Próximos', () {
    testWidgets('Destacados muestra las 3 próximas más cercanas y Próximos '
        'el resto, sin repetir', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();

      expect(find.text('Eventos destacados'), findsOneWidget);
      expect(find.text('Próximos eventos'), findsOneWidget);
      expect(find.text('Finalizadas'), findsNothing);

      final destacadas = tester
          // El carrusel solo construye las páginas visibles: las
          // destacadas se leen de su lista.
          .widget<CarruselDestacados>(find.byType(CarruselDestacados))
          .competencias
          .map((competencia) => competencia.id)
          .toList();
      expect(destacadas, idsDestacados);

      final enLista = tester
          .widgetList<CompetitionCard>(find.byType(CompetitionCard))
          .map((tarjeta) => tarjeta.competition.id)
          .toSet();
      expect(enLista, {'mock-sports-01', 'mock-academic-02', 'mock-other-01'});
      expect(enLista.intersection(destacadas.toSet()), isEmpty);
    });

    testWidgets('las finalizadas no se destacan y van al final', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // 10 de noviembre: solo mock-other-01 (14 nov) está por venir.
      await tester.pumpWidget(inicio(ahora: DateTime(2026, 11, 10, 12)));
      await tester.pumpAndSettle();

      final destacadas = tester
          // El carrusel solo construye las páginas visibles: las
          // destacadas se leen de su lista.
          .widget<CarruselDestacados>(find.byType(CarruselDestacados))
          .competencias
          .map((competencia) => competencia.id);
      expect(destacadas, ['mock-other-01']);
      expect(find.text('Próximos eventos'), findsNothing);
      expect(find.text('Finalizadas'), findsOneWidget);
      expect(find.byType(CompetitionCard), findsNWidgets(5));
    });

    testWidgets('si todas finalizaron no hay sección Destacados', (
      tester,
    ) async {
      await tester.pumpWidget(inicio(ahora: DateTime(2026, 12, 1)));
      await tester.pumpAndSettle();

      expect(find.text('Eventos destacados'), findsNothing);
      expect(find.byType(TarjetaDestacada), findsNothing);
    });

    testWidgets('al buscar o filtrar, Destacados se oculta y todo va en la '
        'lista', (tester) async {
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();
      expect(find.text('Eventos destacados'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Esports'));
      await tester.pumpAndSettle();
      expect(find.text('Eventos destacados'), findsNothing);
      expect(find.byType(TarjetaDestacada), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await tester.pumpAndSettle();
      expect(find.text('Eventos destacados'), findsOneWidget);

      await buscar(tester, 'copa');
      expect(find.text('Eventos destacados'), findsNothing);
    });

    testWidgets('una tarjeta destacada abre el Detalle de su competencia', (
      tester,
    ) async {
      await tester.pumpWidget(inicio());
      await tester.pumpAndSettle();

      final destacada = find.byKey(const ValueKey('mock-esports-02'));
      await tester.ensureVisible(destacada);
      await tester.pumpAndSettle();
      await tester.tap(destacada);
      await tester.pumpAndSettle();

      expect(find.byType(CompetitionDetailScreen), findsOneWidget);
      expect(find.text('Identificador: mock-esports-02'), findsOneWidget);
    });
  });

  group('Imagen', () {
    Competencia conImagen(String? url) {
      final base = competenciasMock.first;
      return Competencia(
        id: 'local-imagen',
        titulo: 'Torneo con imagen',
        categoria: 'Deportiva',
        fechaInicio: DateTime(2026, 10, 1, 9),
        ubicacion: base.ubicacion,
        modalidad: base.modalidad,
        descripcion: base.descripcion,
        reglas: base.reglas,
        costo: base.costo,
        instruccionesParticipacion: base.instruccionesParticipacion,
        imagenUrl: url,
      );
    }

    testWidgets('sin imagenUrl, Destacados usa el fondo con el ícono de la '
        'categoría', (tester) async {
      await tester.pumpWidget(inicio(datos: [conImagen(null)]));
      await tester.pumpAndSettle();

      final fondo = find.descendant(
        of: find.byType(TarjetaDestacada),
        matching: find.byType(FondoDeCategoria),
      );
      expect(fondo, findsOneWidget);
      expect(tester.widget<FondoDeCategoria>(fondo).imagenFallida, isFalse);
      expect(
        find.descendant(
          of: fondo,
          matching: find.byIcon(Icons.sports_soccer_outlined),
        ),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('con imagenUrl intenta cargarla y, si falla, deja el marcador '
        'de posición', (tester) async {
      // En las pruebas no hay red: toda descarga de imagen falla.
      await tester.pumpWidget(
        inicio(datos: [conImagen('https://example.com/torneo.png')]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      final marcador = find.byKey(const ValueKey('imagen-no-disponible'));
      expect(marcador, findsOneWidget);
      expect(tester.widget<FondoDeCategoria>(marcador).imagenFallida, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el Detalle muestra la imagen arriba solo si hay imagenUrl', (
      tester,
    ) async {
      final competencia = conImagen('https://example.com/torneo.png');
      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos([competencia]),
          MaterialApp(
            home: CompetitionDetailScreen(competitionId: competencia.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detalle-imagen')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('imagen-no-disponible')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        conRepositorio(
          FakeCompetenciasRepository.conDatos(competenciasMock),
          MaterialApp(
            home: CompetitionDetailScreen(
              competitionId: competenciasMock.first.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detalle-imagen')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('A 360 dp y texto 2.0, el Inicio con Destacados no se desborda', (
    tester,
  ) async {
    usarTelefono360(tester);
    await tester.pumpWidget(inicio(builder: textoGrande));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // La fila de Destacados se desliza de lado.
    await tester.scrollUntilVisible(
      find.text('Eventos destacados'),
      200,
      scrollable: listaDeInicio,
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('inicio-destacados')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Y la lista baja hasta la última competencia.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mock-other-01')),
      300,
      scrollable: listaDeInicio,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // El estado sin resultados tampoco se desborda.
    await tester.drag(listaDeInicio, const Offset(0, 5000));
    await tester.pumpAndSettle();
    await buscar(tester, 'no existe');
    expect(find.text('Sin resultados para «no existe»'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
