import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';

// Pruebas del pulido del Detalle: resumen, rótulos de ejemplo, copiar y menú.
void main() {
  // Martes 10 de noviembre de 2026, mediodía.
  final ahora = DateTime(2026, 11, 10, 12);

  Widget detalleCon(List<Competencia> datos, String id) {
    return ProviderScope(
      overrides: [
        competenciasRepositoryProvider.overrideWithValue(
          FakeCompetenciasRepository.conDatos(datos),
        ),
        relojProvider.overrideWithValue(() => ahora),
      ],
      child: MaterialApp(home: CompetitionDetailScreen(competitionId: id)),
    );
  }

  // Pantalla alta para que todo el Detalle quede construido sin desplazarse.
  void usarPantallaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Competencia creadaEnLaApp() {
    final base = competenciasMock.first;
    return Competencia(
      id: 'local-prueba-1',
      titulo: 'Torneo creado en la app',
      categoria: base.categoria,
      fechaInicio: DateTime(2026, 11, 20, 9),
      ubicacion: 'Gimnasio de prueba',
      modalidad: 'Presencial',
      descripcion: base.descripcion,
      reglas: base.reglas,
      costo: 'Q10',
      instruccionesParticipacion: base.instruccionesParticipacion,
    );
  }

  testWidgets('El resumen muestra cuándo, dónde y costo al abrir', (
    tester,
  ) async {
    final competencia = competenciasMock.first;
    await tester.pumpWidget(detalleCon(competenciasMock, competencia.id));
    await tester.pumpAndSettle();

    expect(find.text('Cuándo: mar 20 oct 2026 · 18:00'), findsOneWidget);
    expect(
      find.text('Dónde: ${competencia.ubicacion} (${competencia.modalidad})'),
      findsOneWidget,
    );
    expect(find.text('Costo: ${competencia.costo}'), findsOneWidget);
    // El 20 de octubre ya pasó respecto al 10 de noviembre.
    expect(find.text('Finalizada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Una competencia próxima indica cuánto falta', (tester) async {
    final competencia = creadaEnLaApp();
    await tester.pumpWidget(detalleCon([competencia], competencia.id));
    await tester.pumpAndSettle();

    expect(find.text('Faltan 10 días'), findsOneWidget);
    expect(find.text('Cuándo: vie 20 nov 2026 · 09:00'), findsOneWidget);
  });

  testWidgets('Solo las competencias de ejemplo se rotulan como ficticias', (
    tester,
  ) async {
    usarPantallaAlta(tester);
    final ejemplo = competenciasMock.first;
    await tester.pumpWidget(detalleCon(competenciasMock, ejemplo.id));
    await tester.pumpAndSettle();

    expect(find.text('Competencia ficticia de prueba'), findsOneWidget);
    expect(find.text('Identificador: ${ejemplo.id}'), findsOneWidget);
    expect(find.textContaining('son ficticios'), findsOneWidget);
  });

  testWidgets('Una competencia creada en la app no se rotula como ficticia', (
    tester,
  ) async {
    usarPantallaAlta(tester);
    final propia = creadaEnLaApp();
    await tester.pumpWidget(detalleCon([propia], propia.id));
    await tester.pumpAndSettle();

    expect(find.text(propia.titulo), findsOneWidget);
    expect(find.text('Competencia ficticia de prueba'), findsNothing);
    expect(find.textContaining('Identificador'), findsNothing);
    expect(find.textContaining('son ficticios'), findsNothing);
  });

  testWidgets('Copiar deja el enlace y el contacto en el portapapeles', (
    tester,
  ) async {
    usarPantallaAlta(tester);
    final copiados = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final argumentos = call.arguments as Map<Object?, Object?>;
          copiados.add(argumentos['text']! as String);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final competencia = competenciasMock.first;
    await tester.pumpWidget(detalleCon(competenciasMock, competencia.id));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Copiar enlace'));
    await tester.pumpAndSettle();
    expect(copiados, [competencia.inscripcionUrl]);
    expect(find.text('Enlace copiado.'), findsOneWidget);

    await tester.tap(find.byTooltip('Copiar contacto'));
    await tester.pumpAndSettle();
    expect(copiados, [competencia.inscripcionUrl, competencia.contacto]);
    expect(find.text('Contacto copiado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sin enlace ni contacto no se ofrecen botones de copiar', (
    tester,
  ) async {
    usarPantallaAlta(tester);
    final competencia = competenciasMock[1];
    await tester.pumpWidget(detalleCon(competenciasMock, competencia.id));
    await tester.pumpAndSettle();

    expect(competencia.inscripcionUrl, isNull);
    expect(competencia.contacto, isNull);
    expect(find.byTooltip('Copiar enlace'), findsNothing);
    expect(find.byTooltip('Copiar contacto'), findsNothing);
  });

  testWidgets('Eliminar está en el menú de opciones y pide confirmación', (
    tester,
  ) async {
    final competencia = competenciasMock.first;
    await tester.pumpWidget(detalleCon(competenciasMock, competencia.id));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar competencia'), findsNothing);
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar competencia'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('competition-delete-cancel')));
    await tester.pumpAndSettle();

    // Cancelar no borra ni cierra el Detalle.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(CompetitionDetailScreen), findsOneWidget);
    expect(find.text(competencia.titulo), findsOneWidget);
  });
}
