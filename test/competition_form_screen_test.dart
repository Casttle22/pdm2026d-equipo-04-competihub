import 'dart:async';

import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:competihub/widgets/competition_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder campo(String clave) => find.byKey(ValueKey('competition-form-$clave'));

final Finder botonGuardar = find.byKey(const ValueKey('competition-form-save'));

String textoDe(WidgetTester tester, String clave) {
  final editable = tester.widget<EditableText>(
    find.descendant(of: campo(clave), matching: find.byType(EditableText)),
  );
  return editable.controller.text;
}

// Pantalla vertical alta para que todo el formulario quede visible sin
// desplazarse.
void usarPantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Monta una pantalla base con un botón que abre el formulario, para poder
// comprobar que al guardar se regresa a la pantalla anterior.
Future<void> abrirFormulario(
  WidgetTester tester, {
  Competencia? initial,
  required Future<void> Function(CompetenciaDraft) onSave,
}) async {
  usarPantallaAlta(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CompetitionFormScreen(initial: initial, onSave: onSave),
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

Future<void> tocarGuardar(WidgetTester tester) async {
  await tester.tap(botonGuardar);
  await tester.pumpAndSettle();
}

Competencia competenciaCon({DateTime? fechaInicio, DateTime? fechaFin}) {
  final base = competenciasMock.first;
  return Competencia(
    id: base.id,
    titulo: base.titulo,
    categoria: base.categoria,
    fechaInicio: fechaInicio ?? base.fechaInicio,
    ubicacion: base.ubicacion,
    modalidad: base.modalidad,
    descripcion: base.descripcion,
    reglas: base.reglas,
    costo: base.costo,
    instruccionesParticipacion: base.instruccionesParticipacion,
    fechaFin: fechaFin,
    inscripcionUrl: base.inscripcionUrl,
    contacto: base.contacto,
    imagenUrl: base.imagenUrl,
  );
}

void main() {
  group('CompetitionFormScreen', () {
    testWidgets('Un formulario vacío no se guarda y marca los obligatorios', (
      tester,
    ) async {
      var llamadas = 0;
      await abrirFormulario(
        tester,
        onSave: (_) async {
          llamadas++;
        },
      );

      expect(find.text('Nueva competencia'), findsOneWidget);
      await tocarGuardar(tester);

      expect(llamadas, 0);
      expect(find.byType(CompetitionFormScreen), findsOneWidget);
      // Título, ubicación, descripción, reglas, costo e instrucciones.
      expect(find.text('Este campo es obligatorio.'), findsNWidgets(6));
      expect(find.text('Selecciona una categoría.'), findsOneWidget);
      expect(find.text('Selecciona una modalidad.'), findsOneWidget);
      expect(find.text('Selecciona la fecha de inicio.'), findsOneWidget);
    });

    testWidgets('Un campo obligatorio con solo espacios no es válido', (
      tester,
    ) async {
      var llamadas = 0;
      await abrirFormulario(
        tester,
        initial: competenciasMock.first,
        onSave: (_) async {
          llamadas++;
        },
      );

      await tester.enterText(campo('titulo'), '   ');
      await tocarGuardar(tester);

      expect(llamadas, 0);
      expect(find.text('Este campo es obligatorio.'), findsOneWidget);
    });

    testWidgets('La edición precarga los datos actuales', (tester) async {
      final competition = competenciasMock.first;
      await abrirFormulario(tester, initial: competition, onSave: (_) async {});

      expect(find.text('Editar competencia'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(textoDe(tester, 'titulo'), competition.titulo);
      expect(textoDe(tester, 'ubicacion'), competition.ubicacion);
      expect(textoDe(tester, 'descripcion'), competition.descripcion);
      expect(textoDe(tester, 'reglas'), competition.reglas);
      expect(textoDe(tester, 'costo'), competition.costo);
      expect(
        textoDe(tester, 'instrucciones'),
        competition.instruccionesParticipacion,
      );
      expect(textoDe(tester, 'inscripcion-url'), competition.inscripcionUrl);
      expect(textoDe(tester, 'contacto'), competition.contacto);
      expect(find.text('20/10/2026 a las 18:00'), findsOneWidget);
      expect(find.text('20/10/2026 a las 21:00'), findsOneWidget);
    });

    testWidgets(
      'Guardar una edición entrega el borrador y cierra la pantalla',
      (tester) async {
        final competition = competenciasMock.first;
        CompetenciaDraft? recibido;
        await abrirFormulario(
          tester,
          initial: competition,
          onSave: (draft) async {
            recibido = draft;
          },
        );

        await tester.enterText(campo('titulo'), '  Copa editada  ');
        await tester.enterText(campo('costo'), 'Q25 por equipo');
        await tocarGuardar(tester);

        final draft = recibido;
        expect(draft, isNotNull);
        expect(draft!.titulo, 'Copa editada');
        expect(draft.costo, 'Q25 por equipo');
        expect(draft.categoria, competition.categoria);
        expect(draft.modalidad, competition.modalidad);
        expect(draft.fechaInicio, competition.fechaInicio);
        expect(draft.fechaFin, competition.fechaFin);
        expect(draft.ubicacion, competition.ubicacion);
        expect(draft.descripcion, competition.descripcion);
        expect(draft.reglas, competition.reglas);
        expect(
          draft.instruccionesParticipacion,
          competition.instruccionesParticipacion,
        );
        expect(draft.inscripcionUrl, competition.inscripcionUrl);
        expect(draft.contacto, competition.contacto);
        expect(draft.imagenUrl, competition.imagenUrl);

        expect(find.byType(CompetitionFormScreen), findsNothing);
        expect(find.text('Abrir formulario'), findsOneWidget);
      },
    );

    testWidgets('Se pueden limpiar los campos opcionales', (tester) async {
      CompetenciaDraft? recibido;
      await abrirFormulario(
        tester,
        initial: competenciasMock.first,
        onSave: (draft) async {
          recibido = draft;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey('competition-form-fecha-fin-limpiar')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(campo('inscripcion-url'), '');
      await tester.enterText(campo('contacto'), '   ');
      // Los ejemplos traen portada: también se vacía para comprobar que el
      // campo de imagen se puede limpiar.
      await tester.enterText(campo('imagen-url'), '');
      await tocarGuardar(tester);

      expect(recibido, isNotNull);
      expect(recibido!.fechaFin, isNull);
      expect(recibido!.inscripcionUrl, isNull);
      expect(recibido!.contacto, isNull);
      expect(recibido!.imagenUrl, isNull);
    });

    testWidgets('El fin no puede ser anterior al inicio', (tester) async {
      var llamadas = 0;
      await abrirFormulario(
        tester,
        initial: competenciaCon(
          fechaInicio: DateTime(2026, 10, 20, 18),
          fechaFin: DateTime(2026, 10, 20, 17, 59),
        ),
        onSave: (_) async {
          llamadas++;
        },
      );

      await tocarGuardar(tester);

      expect(llamadas, 0);
      expect(
        find.text('El fin debe ser igual o posterior al inicio.'),
        findsOneWidget,
      );
    });

    testWidgets('El fin igual al inicio es válido', (tester) async {
      final inicio = DateTime(2026, 10, 20, 18);
      CompetenciaDraft? recibido;
      await abrirFormulario(
        tester,
        initial: competenciaCon(fechaInicio: inicio, fechaFin: inicio),
        onSave: (draft) async {
          recibido = draft;
        },
      );

      await tocarGuardar(tester);

      expect(recibido?.fechaFin, inicio);
    });

    testWidgets('Los enlaces deben ser HTTP(S) con host', (tester) async {
      var llamadas = 0;
      await abrirFormulario(
        tester,
        initial: competenciasMock.first,
        onSave: (_) async {
          llamadas++;
        },
      );
      const mensaje =
          'Ingresa un enlace válido que empiece con http:// o https://.';

      for (final invalido in [
        'example.com/inscripcion',
        'ftp://example.com',
        'https://',
      ]) {
        await tester.enterText(campo('inscripcion-url'), invalido);
        await tocarGuardar(tester);
        expect(llamadas, 0, reason: invalido);
        expect(find.text(mensaje), findsOneWidget, reason: invalido);
      }

      await tester.enterText(campo('inscripcion-url'), 'http://example.com/a');
      await tester.enterText(campo('imagen-url'), 'mailto:alguien@example.com');
      await tocarGuardar(tester);
      expect(llamadas, 0);
      expect(find.text(mensaje), findsOneWidget);

      await tester.enterText(campo('imagen-url'), 'https://example.com/i.png');
      await tocarGuardar(tester);
      expect(llamadas, 1);
    });

    testWidgets('Si guardar falla, conserva los datos y permite reintentar', (
      tester,
    ) async {
      var llamadas = 0;
      final recibidos = <CompetenciaDraft>[];
      await abrirFormulario(
        tester,
        initial: competenciasMock.first,
        onSave: (draft) async {
          llamadas++;
          recibidos.add(draft);
          if (llamadas == 1) {
            throw Exception('Sin conexión');
          }
        },
      );

      await tester.enterText(campo('titulo'), 'Título que no se debe perder');
      await tocarGuardar(tester);

      expect(llamadas, 1);
      expect(find.byType(CompetitionFormScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('competition-form-error')),
        findsOneWidget,
      );
      expect(textoDe(tester, 'titulo'), 'Título que no se debe perder');

      await tocarGuardar(tester);

      expect(llamadas, 2);
      expect(recibidos.last.titulo, 'Título que no se debe perder');
      expect(find.byType(CompetitionFormScreen), findsNothing);
    });

    testWidgets('Mientras se guarda, se bloquea el doble envío', (
      tester,
    ) async {
      var llamadas = 0;
      final completer = Completer<void>();
      await abrirFormulario(
        tester,
        initial: competenciasMock.first,
        onSave: (_) {
          llamadas++;
          return completer.future;
        },
      );

      await tester.tap(botonGuardar);
      await tester.pump();
      await tester.tap(botonGuardar, warnIfMissed: false);
      await tester.pump();

      expect(llamadas, 1);
      expect(tester.widget<FilledButton>(botonGuardar).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CompetitionFormScreen), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(llamadas, 1);
      expect(find.byType(CompetitionFormScreen), findsNothing);
    });

    testWidgets('Crear una competencia nueva desde el formulario vacío', (
      tester,
    ) async {
      CompetenciaDraft? recibido;
      await abrirFormulario(
        tester,
        onSave: (draft) async {
          recibido = draft;
        },
      );

      await tester.enterText(campo('titulo'), 'Torneo de prueba');
      await tester.tap(campo('categoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deportiva').last);
      await tester.pumpAndSettle();
      await tester.tap(campo('modalidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Híbrida').last);
      await tester.pumpAndSettle();

      // Selector de fecha y luego de hora; se aceptan los valores propuestos.
      await tester.tap(campo('fecha-inicio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(campo('ubicacion'), 'Gimnasio de prueba');
      await tester.enterText(campo('descripcion'), 'Descripción de prueba');
      await tester.enterText(campo('reglas'), 'Reglas de prueba');
      await tester.enterText(campo('costo'), 'Gratis');
      await tester.enterText(campo('instrucciones'), 'Instrucciones de prueba');
      await tocarGuardar(tester);

      expect(recibido, isNotNull);
      expect(recibido!.titulo, 'Torneo de prueba');
      expect(recibido!.categoria, 'Deportiva');
      expect(recibido!.modalidad, 'Híbrida');
      expect(recibido!.fechaFin, isNull);
      expect(recibido!.inscripcionUrl, isNull);
      expect(recibido!.contacto, isNull);
      expect(recibido!.imagenUrl, isNull);
      expect(find.byType(CompetitionFormScreen), findsNothing);
    });
  });

  group('showCompetitionDeleteDialog', () {
    Future<List<bool>> montarDialogo(WidgetTester tester) async {
      final resultados = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    resultados.add(
                      await showCompetitionDeleteDialog(
                        context,
                        'Copa ficticia de arena digital',
                      ),
                    );
                  },
                  child: const Text('Abrir diálogo'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir diálogo'));
      await tester.pumpAndSettle();
      return resultados;
    }

    testWidgets('Muestra el título y cancelar devuelve false', (tester) async {
      final resultados = await montarDialogo(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('Copa ficticia de arena digital'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('competition-delete-cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(resultados, [false]);
    });

    testWidgets('Tocar fuera del diálogo devuelve false', (tester) async {
      final resultados = await montarDialogo(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(resultados, [false]);
    });

    testWidgets('Confirmar devuelve true', (tester) async {
      final resultados = await montarDialogo(tester);

      await tester.tap(
        find.byKey(const ValueKey('competition-delete-confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(resultados, [true]);
    });
  });
}
