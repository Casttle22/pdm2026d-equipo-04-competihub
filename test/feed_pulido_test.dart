import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';

// Pruebas del pulido del Feed. Fijan la hora con relojProvider para que las
// etiquetas de tiempo no dependan del día en que se ejecutan.
void main() {
  // Martes 10 de noviembre de 2026, mediodía.
  final ahora = DateTime(2026, 11, 10, 12);

  Widget feedCon(List<Competencia> datos, {DateTime? hora}) {
    return ProviderScope(
      overrides: [
        competenciasRepositoryProvider.overrideWithValue(
          FakeCompetenciasRepository.conDatos(datos),
        ),
        relojProvider.overrideWithValue(() => hora ?? ahora),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  Competencia creadaEnLaApp() {
    final base = competenciasMock.first;
    return Competencia(
      id: 'local-prueba-1',
      titulo: 'Torneo creado en la app',
      categoria: base.categoria,
      fechaInicio: DateTime(2026, 11, 20, 9),
      ubicacion: 'Gimnasio de prueba',
      modalidad: base.modalidad,
      descripcion: base.descripcion,
      reglas: base.reglas,
      costo: 'Q10',
      instruccionesParticipacion: base.instruccionesParticipacion,
    );
  }

  testWidgets('La tarjeta muestra cuánto falta, fecha legible, lugar y costo', (
    tester,
  ) async {
    final competencia = competenciasMock.firstWhere(
      (c) => c.id == 'mock-other-01',
    );
    await tester.pumpWidget(feedCon([competencia]));
    await tester.pumpAndSettle();

    final tarjeta = find.byKey(ValueKey(competencia.id));
    Finder enTarjeta(String texto) =>
        find.descendant(of: tarjeta, matching: find.text(texto));

    expect(enTarjeta('Faltan 4 días'), findsOneWidget);
    expect(enTarjeta('sáb 14 nov 2026 · 14:00'), findsOneWidget);
    expect(enTarjeta('Ubicación: ${competencia.ubicacion}'), findsOneWidget);
    expect(enTarjeta('Costo: ${competencia.costo}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El contador aclara cuántas competencias ya finalizaron', (
    tester,
  ) async {
    // Mismo orden que entrega la base de datos: próximas primero.
    final ordenadas = ordenarPorCercania(competenciasMock, ahora);
    await tester.pumpWidget(feedCon(ordenadas));
    await tester.pumpAndSettle();

    expect(find.text('6 competencias disponibles'), findsOneWidget);
    expect(find.text('1 por venir · 5 ya finalizaron'), findsOneWidget);
    // El rótulo separa las finalizadas de las que aún se pueden aprovechar.
    // Con Destacados arriba, queda más abajo: se desplaza hasta verlo.
    await tester.scrollUntilVisible(
      find.text('Finalizadas'),
      200,
      scrollable: listaDeInicio,
    );
    expect(find.text('Finalizadas'), findsOneWidget);
    expect(find.text('Finalizada'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sin competencias pasadas no se menciona ninguna finalizada', (
    tester,
  ) async {
    await tester.pumpWidget(
      feedCon(competenciasMock, hora: DateTime(2026, 9, 1, 12)),
    );
    await tester.pumpAndSettle();

    expect(find.text('6 competencias disponibles'), findsOneWidget);
    expect(find.textContaining('finaliz'), findsNothing);
    expect(find.text('Finalizadas'), findsNothing);
    expect(find.text('Finalizada'), findsNothing);
  });

  testWidgets('Sin competencias de ejemplo no aparece el aviso de ficticias', (
    tester,
  ) async {
    await tester.pumpWidget(feedCon([creadaEnLaApp()]));
    await tester.pumpAndSettle();

    expect(find.text('Torneo creado en la app'), findsOneWidget);
    expect(find.textContaining('ficticias'), findsNothing);
  });

  testWidgets('Con ejemplos y competencias propias, el aviso lo distingue', (
    tester,
  ) async {
    await tester.pumpWidget(feedCon([competenciasMock.first, creadaEnLaApp()]));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Las competencias de ejemplo son ficticias. No son eventos reales.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Un lector de pantalla recibe la tarjeta como un solo resumen', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final competencia = competenciasMock.firstWhere(
      (c) => c.id == 'mock-other-01',
    );
    await tester.pumpWidget(feedCon([competencia]));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp(r'Faltan 4 días.*Ubicación: .*Costo: Consultar \(simulado\)'),
      ),
      findsWidgets,
    );
    semantics.dispose();
  });
}
