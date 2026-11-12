import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/screens/competition_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 0: a 360 dp y con texto a 2.0, ni los errores del formulario ni el
// título del Detalle se cortan con «…».
void main() {
  bool seCorta(WidgetTester tester, Finder texto) {
    final parrafo = tester.renderObject<RenderParagraph>(texto);
    return parrafo.didExceedMaxLines;
  }

  testWidgets('Los errores del formulario se leen completos', (tester) async {
    usarTelefono360(tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: textoGrande,
        home: CompetitionFormScreen(onSave: (_) async {}),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('competition-form-save')));
    await tester.pumpAndSettle();

    for (final mensaje in [
      'Selecciona una categoría.',
      'Selecciona una modalidad.',
      'Selecciona la fecha de inicio.',
    ]) {
      final texto = find.text(mensaje);
      await tester.scrollUntilVisible(
        texto,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(seCorta(tester, texto), isFalse, reason: mensaje);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('El error de un enlace inválido ocupa varias líneas', (
    tester,
  ) async {
    usarTelefono360(tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: textoGrande,
        home: CompetitionFormScreen(onSave: (_) async {}),
      ),
    );
    final campo = find.byKey(
      const ValueKey('competition-form-inscripcion-url'),
    );
    await tester.scrollUntilVisible(
      campo,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(campo, 'no-es-enlace');
    await tester.tap(find.byKey(const ValueKey('competition-form-save')));
    await tester.pumpAndSettle();

    final texto = find.text(
      'Ingresa un enlace válido que empiece con http:// o https://.',
    );
    await tester.scrollUntilVisible(
      texto,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(seCorta(tester, texto), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El título de la barra del Detalle no se corta', (tester) async {
    usarTelefono360(tester);
    final competencia = competenciasMock.first;
    await tester.pumpWidget(
      conRepositorio(
        FakeCompetenciasRepository.conDatos(competenciasMock),
        MaterialApp(
          builder: textoGrande,
          home: CompetitionDetailScreen(competitionId: competencia.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titulo = find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Detalle'),
    );
    expect(titulo, findsOneWidget);
    expect(seCorta(tester, titulo), isFalse);
    expect(tester.takeException(), isNull);
  });
}
