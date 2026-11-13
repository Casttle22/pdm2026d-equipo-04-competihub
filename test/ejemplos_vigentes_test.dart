import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/main.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 1: con las fechas relativas, el Inicio muestra ejemplos vigentes y
// una sola finalizada, también en un teléfono angosto con texto grande.
void main() {
  final hoy = DateTime(2026, 11, 11, 10, 30);

  testWidgets('A 360 dp y texto 2.0, los ejemplos vigentes se ven sin '
      'desbordes', (tester) async {
    usarTelefono360(tester);
    final ejemplos = ordenarPorCercania(competenciasDeEjemplo(hoy), hoy);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          competenciasRepositoryProvider.overrideWithValue(
            FakeCompetenciasRepository.conDatos(ejemplos),
          ),
          relojProvider.overrideWithValue(() => hoy),
        ],
        child: const MaterialApp(builder: textoGrande, home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6 competencias disponibles'), findsOneWidget);
    expect(find.text('5 por venir · 1 ya finalizó'), findsOneWidget);

    final lista = find.byType(Scrollable).first;
    // En el carrusel, el tiempo restante va en la misma línea que la fecha.
    await tester.scrollUntilVisible(
      find.textContaining('Faltan 3 días'),
      200,
      scrollable: lista,
    );
    await tester.scrollUntilVisible(
      find.text('Finalizada'),
      200,
      scrollable: lista,
    );
    expect(find.text('Finalizada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('competenciasDeEjemplo no cambia nada más que las fechas', () {
    final ejemplos = competenciasDeEjemplo(hoy);
    expect(ejemplos.length, competenciasMock.length);
    for (var i = 0; i < ejemplos.length; i++) {
      final base = competenciasMock[i];
      final ejemplo = ejemplos[i];
      expect(ejemplo.id, base.id);
      expect(ejemplo.titulo, base.titulo);
      expect(ejemplo.esDeEjemplo, isTrue);
      expect(ejemplo.fechaInicio.hour, base.fechaInicio.hour);
      expect(ejemplo.fechaFin == null, base.fechaFin == null);
    }
    expect(ejemplos.where((c) => estaFinalizada(c, hoy)).length, 1);
  });
}
