import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/explorar_screen.dart';
import 'package:competihub/screens/mapa_screen.dart';
import 'package:competihub/screens/mis_eventos_screen.dart';
import 'package:competihub/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 7: barra inferior con Inicio, Mapa y Mis eventos.
void main() {
  Widget app({TransitionBuilder? builder}) {
    return conRepositorio(
      FakeCompetenciasRepository.conDatos(competenciasMock),
      MaterialApp(
        theme: temaCompetihub(),
        builder: builder,
        home: const PantallaPrincipal(),
      ),
      ahora: DateTime(2026, 9, 1, 12),
    );
  }

  Future<void> irA(WidgetTester tester, String pestana) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('barra-inferior')),
        matching: find.text(pestana),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool visible(WidgetTester tester, Type pantalla) {
    // En el IndexedStack, las pestañas ocultas siguen montadas pero fuera
    // de escena: find las omite por defecto.
    return find.byType(pantalla).evaluate().isNotEmpty;
  }

  testWidgets('la barra tiene las cuatro secciones y empieza en Inicio', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final barra = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('barra-inferior')),
    );
    expect(barra.selectedIndex, 0);
    expect(barra.destinations, hasLength(4));
    for (final pestana in ['Inicio', 'Explorar', 'Mapa', 'Mis eventos']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('barra-inferior')),
          matching: find.text(pestana),
        ),
        findsOneWidget,
      );
    }
    expect(visible(tester, HomeScreen), isTrue);
    expect(visible(tester, MapaScreen), isFalse);
    // La app no tiene cuentas: no hay «Perfil».
    expect(find.text('Perfil'), findsNothing);
  });

  testWidgets('cambia de sección al tocar cada pestaña', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await irA(tester, 'Explorar');
    expect(visible(tester, ExplorarScreen), isTrue);
    expect(visible(tester, HomeScreen), isFalse);

    await irA(tester, 'Mapa');
    expect(visible(tester, MapaScreen), isTrue);
    expect(visible(tester, HomeScreen), isFalse);

    await irA(tester, 'Mis eventos');
    expect(visible(tester, MisEventosScreen), isTrue);

    await irA(tester, 'Inicio');
    expect(visible(tester, HomeScreen), isTrue);
  });

  testWidgets('el Inicio conserva búsqueda, filtro y posición al volver', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Académica'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('inicio-busqueda')),
      'ficticio',
    );
    await tester.pumpAndSettle();
    await tester.drag(listaDeInicio, const Offset(0, -300));
    await tester.pumpAndSettle();
    final posicion = tester
        .state<ScrollableState>(listaDeInicio)
        .position
        .pixels;
    expect(posicion, greaterThan(0));

    await irA(tester, 'Mis eventos');
    await irA(tester, 'Inicio');

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('inicio-busqueda'), skipOffstage: false),
          )
          .controller!
          .text,
      'ficticio',
    );
    expect(
      tester
          .widget<ChoiceChip>(
            // Explorar también tiene un filtro «Académica»: se busca el del
            // Inicio.
            find.descendant(
              of: find.byType(HomeScreen, skipOffstage: false),
              matching: find.widgetWithText(
                ChoiceChip,
                'Académica',
                skipOffstage: false,
              ),
              skipOffstage: false,
            ),
          )
          .selected,
      isTrue,
    );
    expect(
      tester.state<ScrollableState>(listaDeInicio).position.pixels,
      posicion,
    );
  });

  testWidgets('«Ver todos» del Inicio lleva a Explorar y Explorar conserva '
      'sus filtros', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver todos').first);
    await tester.pumpAndSettle();
    expect(visible(tester, ExplorarScreen), isTrue);
    final barra = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('barra-inferior')),
    );
    expect(barra.selectedIndex, 1);

    final presencial = find.descendant(
      of: find.byType(ExplorarScreen),
      matching: find.widgetWithText(ChoiceChip, 'Presencial'),
    );
    await tester.tap(presencial);
    await tester.pumpAndSettle();
    await irA(tester, 'Inicio');
    await irA(tester, 'Explorar');
    expect(tester.widget<ChoiceChip>(presencial).selected, isTrue);
  });

  testWidgets('el Detalle se abre sobre la barra y Atrás vuelve a la misma '
      'pestaña', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final tarjeta = find.byKey(const ValueKey('mock-esports-02'));
    await tester.ensureVisible(tarjeta);
    await tester.pumpAndSettle();
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    expect(find.byType(CompetitionDetailScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('barra-inferior')), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('barra-inferior')), findsOneWidget);
    expect(visible(tester, HomeScreen), isTrue);
  });

  testWidgets('a 360 dp y texto 2.0, la barra y las cuatro secciones no se '
      'desbordan', (tester) async {
    usarTelefono360(tester);
    await tester.pumpWidget(app(builder: textoGrande));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final pestana in ['Explorar', 'Mapa', 'Mis eventos', 'Inicio']) {
      await irA(tester, pestana);
      expect(tester.takeException(), isNull, reason: pestana);
    }
  });
}
