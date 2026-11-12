import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pruebas del pulido del formulario: salir con o sin cambios, ir al primer
// error y el aviso de fecha pasada.

Finder campo(String clave) => find.byKey(ValueKey('competition-form-$clave'));

final Finder botonGuardar = find.byKey(const ValueKey('competition-form-save'));

void usarPantalla(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Monta una pantalla base con un botón que abre el formulario, para poder
// comprobar si se regresa a ella.
Future<void> abrirFormulario(
  WidgetTester tester, {
  Competencia? initial,
  Future<void> Function(CompetenciaDraft)? onSave,
  DateTime Function()? ahora,
  Size size = const Size(900, 2600),
}) async {
  usarPantalla(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompetitionFormScreen(
                    initial: initial,
                    onSave: onSave ?? (_) async {},
                    ahora: ahora,
                  ),
                ),
              ),
              child: const Text('Abrir formulario'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir formulario'));
  await tester.pumpAndSettle();
  expect(find.byType(CompetitionFormScreen), findsOneWidget);
}

void main() {
  group('Salir del formulario', () {
    testWidgets('Sin cambios, Atrás cierra sin preguntar', (tester) async {
      await abrirFormulario(tester, initial: competenciasMock.first);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar cambios?'), findsNothing);
      expect(find.byType(CompetitionFormScreen), findsNothing);
      expect(find.text('Abrir formulario'), findsOneWidget);
    });

    testWidgets('Con cambios, Atrás pregunta y permite seguir editando', (
      tester,
    ) async {
      await abrirFormulario(tester, initial: competenciasMock.first);
      await tester.enterText(campo('titulo'), 'Título sin guardar');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar cambios?'), findsOneWidget);

      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar cambios?'), findsNothing);
      expect(find.byType(CompetitionFormScreen), findsOneWidget);
      expect(find.text('Título sin guardar'), findsOneWidget);
    });

    testWidgets('Con cambios, Descartar cierra el formulario', (tester) async {
      var llamadas = 0;
      await abrirFormulario(
        tester,
        onSave: (_) async {
          llamadas++;
        },
      );
      await tester.enterText(campo('titulo'), 'Borrador');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(find.byType(CompetitionFormScreen), findsNothing);
      expect(find.text('Abrir formulario'), findsOneWidget);
      expect(llamadas, 0);
    });
  });

  testWidgets('Con errores, la pantalla sube al primer campo inválido', (
    tester,
  ) async {
    const size = Size(400, 700);
    await abrirFormulario(tester, size: size);

    // Se baja hasta el final: el título queda fuera de la pantalla. El
    // primer Scrollable dentro del formulario es el de la pantalla; los de
    // los campos de texto vienen después.
    final desplazable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    desplazable.position.jumpTo(desplazable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.getRect(campo('titulo')).bottom, lessThan(0));

    await tester.tap(botonGuardar);
    await tester.pumpAndSettle();

    final titulo = tester.getRect(campo('titulo'));
    expect(titulo.top, greaterThanOrEqualTo(0));
    expect(titulo.bottom, lessThanOrEqualTo(size.height));
    expect(find.text('Este campo es obligatorio.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('Aviso de fecha pasada', () {
    testWidgets('Avisa sin bloquear cuando el inicio ya pasó', (tester) async {
      var llamadas = 0;
      await abrirFormulario(
        tester,
        initial: competenciasMock.first,
        onSave: (_) async {
          llamadas++;
        },
        ahora: () => DateTime(2026, 11, 10, 12),
      );

      expect(find.text('Esta fecha ya pasó.'), findsOneWidget);

      await tester.tap(botonGuardar);
      await tester.pumpAndSettle();
      expect(llamadas, 1);
      expect(find.byType(CompetitionFormScreen), findsNothing);
    });

    testWidgets('No avisa cuando el inicio todavía no llega', (tester) async {
      await abrirFormulario(
        tester,
        initial: competenciasMock.first,
        ahora: () => DateTime(2026, 10, 1, 12),
      );

      expect(find.text('Esta fecha ya pasó.'), findsNothing);
    });
  });
}
