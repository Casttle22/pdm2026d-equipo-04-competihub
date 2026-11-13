import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:competihub/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/pantalla_prueba.dart';

// Rediseño del formulario según las maquetas: subtítulos grises, campos
// redondeados con la etiqueta encima y botón fijo de ancho completo.
void main() {
  Widget formulario({bool editar = false, TransitionBuilder? builder}) {
    return MaterialApp(
      theme: temaCompetihub(),
      builder: builder,
      home: CompetitionFormScreen(
        initial: editar ? competenciasMock.first : null,
        onSave: (_) async {},
      ),
    );
  }

  Future<void> irA(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('agrupa los campos bajo subtítulos grises', (tester) async {
    tester.view.physicalSize = const Size(400, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(formulario());
    await tester.pumpAndSettle();

    for (final subtitulo in [
      'Información general',
      'Fecha y hora',
      'Ubicación',
      'Participación',
      'Formato y premios',
      'Etapas y cronograma',
    ]) {
      final texto = tester.widget<Text>(find.text(subtitulo));
      expect(texto.style?.color, esquemaDeColor.onSurfaceVariant);
    }
  });

  testWidgets('el botón dice «Crear competencia» o «Guardar cambios» y '
      'ocupa el ancho completo', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(formulario());
    await tester.pumpAndSettle();

    final boton = find.byKey(const ValueKey('competition-form-save'));
    expect(
      find.descendant(of: boton, matching: find.text('Crear competencia')),
      findsOneWidget,
    );
    expect(tester.getSize(boton).width, 400 - 32);

    await tester.pumpWidget(formulario(editar: true));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: boton, matching: find.text('Guardar cambios')),
      findsOneWidget,
    );
  });

  testWidgets('la fecha y hora es un solo campo con ícono de calendario que '
      'abre la fecha y luego la hora', (tester) async {
    await tester.pumpWidget(formulario());
    await tester.pumpAndSettle();

    final inicio = find.byKey(const ValueKey('competition-form-fecha-inicio'));
    await irA(tester, inicio);
    expect(find.text('Fecha y hora de inicio *'), findsOneWidget);
    expect(
      find.descendant(
        of: inicio,
        matching: find.byIcon(Icons.calendar_today_outlined),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(of: inicio, matching: find.text('Elegir fecha y hora')),
      findsOneWidget,
    );
    await tester.tap(inicio);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('los campos tienen borde redondeado y fondo blanco', (
    tester,
  ) async {
    await tester.pumpWidget(formulario());
    await tester.pumpAndSettle();

    final decorador = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byKey(const ValueKey('competition-form-titulo')),
        matching: find.byType(InputDecorator),
      ),
    );
    final borde = decorador.decoration.enabledBorder! as OutlineInputBorder;
    expect(borde.borderRadius, BorderRadius.circular(radioCampo));
    expect(decorador.decoration.fillColor, Colors.white);
  });

  testWidgets('a 360 dp y texto 2.0, las etiquetas se leen completas y nada '
      'se desborda', (tester) async {
    usarTelefono360(tester);
    await tester.pumpWidget(formulario(builder: textoGrande));
    await tester.pumpAndSettle();

    for (final etiqueta in [
      'Fecha y hora de inicio *',
      'Fecha y hora de fin (opcional)',
      'Límite de inscripción (opcional)',
      'Instrucciones para participar *',
      'Mínimo de personas por equipo (opcional)',
    ]) {
      final texto = find.text(etiqueta);
      if (etiqueta.startsWith('Mínimo')) {
        // Solo aparece con el formato por equipos.
        continue;
      }
      await irA(tester, texto);
      final parrafo = tester.renderObject<RenderParagraph>(texto);
      expect(parrafo.didExceedMaxLines, isFalse, reason: etiqueta);
      expect(tester.takeException(), isNull, reason: etiqueta);
    }
  });
}
