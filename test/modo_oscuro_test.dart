import 'dart:math' as math;

import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/providers/tema_provider.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/tema.dart';
import 'package:competihub/widgets/categoria_estilo.dart';
import 'package:competihub/widgets/etiquetas_ficha.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Modo claro y oscuro: contraste del tema oscuro, selector de tema y
// seguimiento de la configuración del sistema.

double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final hoy = DateTime(2026, 11, 12, 9);
  final ejemplos = competenciasDeEjemplo(hoy);

  group('Contraste AA en modo oscuro', () {
    final s = esquemaOscuro;
    final tarjeta = s.surfaceContainerHigh;
    final pares = <String, (Color, Color)>{
      'texto sobre el fondo': (s.onSurface, s.surface),
      'texto secundario sobre el fondo': (s.onSurfaceVariant, s.surface),
      'texto sobre las tarjetas': (s.onSurface, tarjeta),
      'texto secundario sobre las tarjetas': (s.onSurfaceVariant, tarjeta),
      'color principal sobre el fondo': (s.primary, s.surface),
      'color principal sobre las tarjetas': (s.primary, tarjeta),
      'texto sobre el color principal': (s.onPrimary, s.primary),
      'ícono activo de la barra sobre su indicador': (
        s.primary,
        s.primaryContainer,
      ),
      'etiqueta de estado': (s.onPrimaryContainer, s.primaryContainer),
      'aviso de datos ficticios': (
        s.onSecondaryContainer,
        s.secondaryContainer,
      ),
      'caja de error': (s.onErrorContainer, s.errorContainer),
      'mensaje de error sobre las tarjetas': (s.error, tarjeta),
    };
    for (final categoria in ['Esports', 'Académica', 'Deportiva', 'Otras']) {
      final color = estiloDeCategoria(categoria, s).color;
      pares['categoría $categoria sobre su fondo suave'] = (
        color,
        fondoSuave(color, tarjeta),
      );
    }
    for (final (nombre, colores) in [
      ('Individual', coloresIndividualOscuro),
      ('Equipos', coloresEquiposOscuro),
      ('Presencial', coloresPresencialOscuro),
      ('Virtual', coloresVirtualOscuro),
      ('Híbrida', coloresHibridaOscuro),
    ]) {
      pares['etiqueta $nombre'] = (colores.texto, colores.fondo);
    }
    pares.forEach((nombre, par) {
      test(nombre, () {
        expect(contraste(par.$1, par.$2), greaterThanOrEqualTo(4.5));
      });
    });

    test('el tema oscuro usa el mismo color semilla y es oscuro', () {
      expect(temaCompetihubOscuro().brightness, Brightness.dark);
      expect(
        temaCompetihubOscuro().colorScheme,
        ColorScheme.fromSeed(
          seedColor: azulCompetihub,
          brightness: Brightness.dark,
        ),
      );
    });

    test('los degradados de portada usan siempre el color oscuro de la '
        'categoría (con contenido blanco encima)', () {
      for (final categoria in ['Esports', 'Académica', 'Deportiva', 'Otras']) {
        expect(
          contraste(Colors.white, colorBaseDeCategoria(categoria)),
          greaterThanOrEqualTo(4.5),
          reason: categoria,
        );
      }
    });
  });

  group('Selector de tema', () {
    Widget app() => conRepositorio(
      FakeCompetenciasRepository.conDatos(ejemplos),
      const CompetihubApp(),
      ahora: hoy,
    );

    Brightness brillo(WidgetTester tester) =>
        Theme.of(tester.element(find.text('CompetiHub'))).brightness;

    Future<void> elegir(WidgetTester tester, ThemeMode modo) async {
      await tester.tap(find.byKey(const ValueKey('selector-tema')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('tema-${modo.name}')));
      await tester.pumpAndSettle();
    }

    testWidgets('por defecto sigue la configuración del sistema', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(brillo(tester), Brightness.dark);
      expect(find.byTooltip('Tema: Sistema'), findsOneWidget);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(brillo(tester), Brightness.light);
    });

    testWidgets('Claro y Oscuro fijan el modo aunque el sistema diga otra '
        'cosa; Sistema vuelve a seguirlo', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await elegir(tester, ThemeMode.light);
      expect(brillo(tester), Brightness.light);
      expect(find.byTooltip('Tema: Claro'), findsOneWidget);

      await elegir(tester, ThemeMode.dark);
      expect(brillo(tester), Brightness.dark);
      expect(find.byTooltip('Tema: Oscuro'), findsOneWidget);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(brillo(tester), Brightness.dark);

      await elegir(tester, ThemeMode.system);
      expect(brillo(tester), Brightness.light);
    });

    test('el provider empieza en Sistema y guarda la elección', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);
      expect(contenedor.read(modoTemaProvider), ThemeMode.system);
      contenedor.read(modoTemaProvider.notifier).cambiar(ThemeMode.dark);
      expect(contenedor.read(modoTemaProvider), ThemeMode.dark);
    });
  });

  group('Pantallas en oscuro', () {
    Widget oscuro(Widget home, {TransitionBuilder? builder}) => conRepositorio(
      FakeCompetenciasRepository.conDatos(ejemplos),
      MaterialApp(
        theme: temaCompetihub(),
        darkTheme: temaCompetihubOscuro(),
        themeMode: ThemeMode.dark,
        builder: builder,
        home: home,
      ),
      ahora: hoy,
    );

    testWidgets('las tarjetas y campos toman el color del tema, no blanco', (
      tester,
    ) async {
      await tester.pumpWidget(oscuro(const PantallaPrincipal()));
      await tester.pumpAndSettle();
      final campo = tester.widget<TextField>(
        find.byKey(const ValueKey('inicio-busqueda')),
      );
      expect(campo.decoration!.fillColor, esquemaOscuro.surfaceContainerHigh);
      final todas = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Todas'),
      );
      // Seleccionada: color principal con su texto de contraste.
      expect(todas.selectedColor, esquemaOscuro.primary);
      expect(todas.labelStyle!.color, esquemaOscuro.onPrimary);
    });

    testWidgets('a 360 dp y texto 2.0 en oscuro, Inicio y Detalle no se '
        'desbordan', (tester) async {
      usarTelefono360(tester);
      await tester.pumpWidget(
        oscuro(const PantallaPrincipal(), builder: textoGrande),
      );
      await tester.pumpAndSettle();
      await tester.drag(listaDeInicio, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        oscuro(
          const CompetitionDetailScreen(competitionId: 'mock-academic-02'),
          builder: textoGrande,
        ),
      );
      await tester.pumpAndSettle();
      final lista = find.byType(Scrollable).first;
      for (var i = 0; i < 10; i++) {
        await tester.drag(lista, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
