import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/servicios/compartir.dart';
import 'package:competihub/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 11: compartir con share_plus.

class _CompartidorDePrueba extends Compartidor {
  final compartidos = <({String texto, String? asunto})>[];
  Object? error;

  @override
  Future<void> compartir(String texto, {String? asunto}) async {
    final error = this.error;
    if (error != null) {
      throw error;
    }
    compartidos.add((texto: texto, asunto: asunto));
  }
}

void main() {
  final hoy = DateTime(2026, 11, 12, 9);

  Competencia propia({String? enlace}) {
    return Competencia(
      id: 'local-compartir',
      titulo: 'Hackatón de la facultad',
      categoria: 'Académica',
      fechaInicio: DateTime(2026, 12, 5, 8, 30),
      ubicacion: 'Edificio T3, salón 201',
      modalidad: 'Presencial',
      descripcion: 'Un día de programación.',
      reglas: 'Equipos de 3.',
      costo: 'Gratis',
      instruccionesParticipacion: 'Inscribirse en el formulario.',
      inscripcionUrl: enlace,
    );
  }

  group('Texto', () {
    test('incluye título, fecha, lugar, costo, cómo participar y enlace', () {
      final texto = textoParaCompartir(
        propia(enlace: 'https://example.com/hackaton'),
      );
      expect(
        texto,
        'Hackatón de la facultad\n'
        '\n'
        'Fecha: sáb 5 dic 2026 · 08:30\n'
        'Lugar: Edificio T3, salón 201 (Presencial)\n'
        'Costo: Gratis\n'
        '\n'
        'Cómo participar: Inscribirse en el formulario.\n'
        'Enlace: https://example.com/hackaton\n'
        '\n'
        'Compartido desde CompetiHub.',
      );
    });

    test('sin enlace no agrega la línea del enlace', () {
      expect(textoParaCompartir(propia()), isNot(contains('Enlace:')));
    });

    test('en las de ejemplo, lo primero que dice es que es ficticia', () {
      for (final ejemplo in competenciasMock) {
        final texto = textoParaCompartir(ejemplo);
        expect(
          texto.split('\n').first,
          'Competencia FICTICIA de ejemplo (no es un evento real).',
          reason: ejemplo.id,
        );
      }
      expect(textoParaCompartir(propia()), isNot(contains('FICTICIA')));
    });
  });

  group('Detalle', () {
    late _CompartidorDePrueba compartidor;

    setUp(() => compartidor = _CompartidorDePrueba());

    Widget detalle(Competencia competencia, {TransitionBuilder? builder}) {
      return ProviderScope(
        overrides: [
          competenciasRepositoryProvider.overrideWithValue(
            FakeCompetenciasRepository.conDatos([competencia]),
          ),
          relojProvider.overrideWithValue(() => hoy),
          compartidorProvider.overrideWithValue(compartidor),
        ],
        child: MaterialApp(
          theme: temaCompetihub(),
          builder: builder,
          home: CompetitionDetailScreen(competitionId: competencia.id),
        ),
      );
    }

    final boton = find.byKey(const ValueKey('detalle-compartir'));

    Future<void> tocar(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        boton,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    testWidgets('el botón comparte el texto con el título como asunto', (
      tester,
    ) async {
      final competencia = propia(enlace: 'https://example.com/hackaton');
      await tester.pumpWidget(detalle(competencia));
      await tester.pumpAndSettle();
      await tocar(tester);

      expect(compartidor.compartidos, hasLength(1));
      expect(
        compartidor.compartidos.single.texto,
        textoParaCompartir(competencia),
      );
      expect(compartidor.compartidos.single.asunto, 'Hackatón de la facultad');
    });

    testWidgets('también está en las competencias virtuales', (tester) async {
      await tester.pumpWidget(
        detalle(competenciasMock.firstWhere((c) => c.modalidad == 'Virtual')),
      );
      await tester.pumpAndSettle();
      await tocar(tester);
      expect(compartidor.compartidos.single.texto, contains('FICTICIA'));
    });

    testWidgets('si falla, lo dice', (tester) async {
      compartidor.error = Exception('sin apps para compartir');
      await tester.pumpWidget(detalle(propia()));
      await tester.pumpAndSettle();
      await tocar(tester);
      expect(find.text('No se pudo compartir.'), findsOneWidget);
    });

    testWidgets('a 360 dp y texto 2.0, la fila de acciones con los tres '
        'botones no se desborda', (tester) async {
      usarTelefono360(tester);
      await tester.pumpWidget(detalle(propia(), builder: textoGrande));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        boton,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detalle-como-llegar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
