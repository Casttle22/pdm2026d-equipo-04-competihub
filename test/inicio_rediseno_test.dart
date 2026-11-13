import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/inicio_screen.dart' show CarruselDestacados;
import 'package:competihub/tema.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Rediseño del Inicio según las maquetas: encabezado con píldora de
// ubicación, buscador, filtros en píldoras, carrusel de destacados con
// puntos y filas de «Próximos eventos».
void main() {
  final hoy = DateTime(2026, 11, 12, 9);
  final ejemplos = ordenarPorCercania(competenciasDeEjemplo(hoy), hoy);

  Widget inicio({
    List<Competencia>? datos,
    TransitionBuilder? builder,
    VoidCallback? onVerTodos,
  }) {
    return conRepositorio(
      FakeCompetenciasRepository.conDatos(datos ?? ejemplos),
      MaterialApp(
        theme: temaCompetihub(),
        builder: builder,
        home: HomeScreen(onVerTodos: onVerTodos),
      ),
      ahora: hoy,
    );
  }

  testWidgets('el encabezado muestra la marca y la píldora de ubicación', (
    tester,
  ) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();

    expect(find.text('CompetiHub'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    final pildora = find.byKey(const ValueKey('inicio-ubicacion'));
    expect(
      find.descendant(of: pildora, matching: find.text('Todas')),
      findsOneWidget,
    );
    expect(
      find.text('Buscar torneos, hackathons, organizadores…'),
      findsOneWidget,
    );
    expect(find.byTooltip('Nueva competencia'), findsOneWidget);
  });

  testWidgets('la píldora filtra presenciales (Quetzaltenango) y virtuales '
      '(Online), con las híbridas en ambas', (tester) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();
    final pildora = find.byKey(const ValueKey('inicio-ubicacion'));

    Future<void> elegir(String opcion) async {
      await tester.tap(pildora);
      await tester.pumpAndSettle();
      await tester.tap(find.text(opcion).last);
      await tester.pumpAndSettle();
    }

    // 4 presenciales/híbridas (academic-01, sports-01, academic-02 y
    // esports-02) y 3 virtuales/híbridas (esports-01, other-01 y
    // academic-02).
    await elegir('Quetzaltenango (presencial e híbrida)');
    expect(find.text('4 competencias disponibles'), findsOneWidget);
    expect(
      find.descendant(of: pildora, matching: find.text('Quetzaltenango')),
      findsOneWidget,
    );
    // Con un filtro, Destacados se oculta.
    expect(find.text('Eventos destacados'), findsNothing);

    await elegir('Online (virtual e híbrida)');
    expect(find.text('3 competencias disponibles'), findsOneWidget);

    await elegir('Todas las ubicaciones');
    expect(find.text('6 competencias disponibles'), findsOneWidget);
    expect(find.text('Eventos destacados'), findsOneWidget);
  });

  testWidgets('la categoría seleccionada va azul rellena con texto blanco', (
    tester,
  ) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Esports'));
    await tester.pumpAndSettle();

    final esports = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Esports'),
    );
    expect(esports.selected, isTrue);
    expect(esports.selectedColor, azulCompetihub);
    expect(esports.labelStyle!.color, Colors.white);
    final todas = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Todas'),
    );
    expect(todas.selected, isFalse);
    expect(todas.backgroundColor, Colors.white);
  });

  testWidgets('el carrusel tiene puntos de página y avanzan al deslizar', (
    tester,
  ) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();

    final carrusel = tester.widget<CarruselDestacados>(
      find.byType(CarruselDestacados),
    );
    expect(carrusel.competencias, hasLength(3));
    final puntos = find.descendant(
      of: find.byKey(const ValueKey('inicio-destacados-puntos')),
      matching: find.byType(AnimatedContainer),
    );
    expect(puntos, findsNWidgets(3));
    double ancho(int i) => tester.getSize(puntos.at(i)).width;
    expect(ancho(0), greaterThan(ancho(1)));

    await tester.drag(
      find.byKey(const ValueKey('inicio-destacados')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(ancho(1), greaterThan(ancho(0)));
  });

  testWidgets('la tarjeta destacada muestra título, subtítulo, organizador, '
      'fecha y modalidad con lugar', (tester) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();
    // La primera destacada es la copa (en 3 días), que tiene organizador.
    final tarjeta = find.byType(TarjetaDestacada).first;
    final copa = ejemplos.firstWhere((c) => c.id == 'mock-esports-01');
    for (final texto in [
      copa.titulo,
      copa.descripcion,
      copa.organizador!,
      // Fecha y tiempo restante en la misma línea.
      '${formatearRangoCorto(copa.fechaInicio, copa.fechaFin)} · Faltan 3 días',
      'Cierra en 2 días',
      'Virtual · ${copa.ubicacion}',
    ]) {
      expect(
        find.descendant(of: tarjeta, matching: find.text(texto)),
        findsOneWidget,
        reason: texto,
      );
    }
  });

  testWidgets('la fila de Próximos muestra etiquetas de formato y modalidad '
      'y el botón Detalles abre el Detalle', (tester) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();

    // La olimpiada (híbrida, por parejas) está en Próximos.
    final fila = find.byKey(const ValueKey('mock-academic-02'));
    await tester.scrollUntilVisible(fila, 200, scrollable: listaDeInicio);
    await tester.pumpAndSettle();
    expect(find.text('Próximos eventos'), findsOneWidget);
    for (final texto in ['Equipos', 'Híbrida', 'Académica']) {
      expect(
        find.descendant(of: fila, matching: find.text(texto)),
        findsOneWidget,
        reason: texto,
      );
    }
    final detalles = find.byKey(const ValueKey('detalles-mock-academic-02'));
    await tester.ensureVisible(detalles);
    await tester.pumpAndSettle();
    await tester.tap(detalles);
    await tester.pumpAndSettle();
    expect(find.text('Identificador: mock-academic-02'), findsOneWidget);
  });

  testWidgets('las fechas de varios días se muestran como rango', (
    tester,
  ) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();
    final olimpiada = ejemplos.firstWhere((c) => c.id == 'mock-academic-02');
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(olimpiada.id)),
      200,
      scrollable: listaDeInicio,
    );
    // Dura dos días y cambia de mes: 30 de noviembre al 1 de diciembre.
    expect(
      formatearRangoCorto(olimpiada.fechaInicio, olimpiada.fechaFin),
      '30 de nov - 1 de dic, 2026',
    );
    expect(
      find.text('30 de nov - 1 de dic, 2026 · ${olimpiada.ubicacion}'),
      findsOneWidget,
    );
  });

  testWidgets('«Ver todos» aparece solo si hay a dónde ir y avisa al tocarlo', (
    tester,
  ) async {
    await tester.pumpWidget(inicio());
    await tester.pumpAndSettle();
    expect(find.text('Ver todos'), findsNothing);

    var veces = 0;
    await tester.pumpWidget(inicio(onVerTodos: () => veces++));
    await tester.pumpAndSettle();
    expect(find.text('Ver todos'), findsWidgets);
    await tester.tap(find.text('Ver todos').first);
    expect(veces, 1);
  });

  testWidgets('A 360 dp y texto 2.0: encabezado, carrusel y filas sin '
      'desbordes', (tester) async {
    usarTelefono360(tester);
    await tester.pumpWidget(inicio(builder: textoGrande, onVerTodos: () {}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byType(CarruselDestacados),
      200,
      scrollable: listaDeInicio,
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.drag(
        find.byKey(const ValueKey('inicio-destacados')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mock-esports-02')),
      300,
      scrollable: listaDeInicio,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // El menú de ubicación tampoco se desborda.
    await tester.drag(listaDeInicio, const Offset(0, 6000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('inicio-ubicacion')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
