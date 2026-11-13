import 'dart:io';

import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/screens/competition_detail_screen.dart';
import 'package:competihub/servicios/abridor_de_mapas.dart';
import 'package:competihub/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_competencias_repository.dart';
import 'fakes/pantalla_prueba.dart';

// Módulo 9: «Cómo llegar» con url_launcher.
void main() {
  final hoy = DateTime(2026, 11, 12, 9);

  Competencia propia(String modalidad) {
    final base = competenciasMock.first;
    return Competencia(
      id: 'local-lugar',
      titulo: 'Torneo en el gimnasio',
      categoria: 'Deportiva',
      fechaInicio: DateTime(2026, 12, 20, 9),
      ubicacion: 'Gimnasio municipal, zona 3',
      modalidad: modalidad,
      descripcion: base.descripcion,
      reglas: base.reglas,
      costo: base.costo,
      instruccionesParticipacion: base.instruccionesParticipacion,
    );
  }

  group('Enlaces', () {
    test('sin coordenadas: geo: con búsqueda y respaldo web', () {
      final enlaces = enlacesDeMapa('Gimnasio municipal, zona 3');
      expect(
        enlaces.first.toString(),
        'geo:0,0?q=Gimnasio%20municipal%2C%20zona%203',
      );
      expect(enlaces.last.host, 'www.google.com');
      expect(enlaces.last.queryParameters, {
        'api': '1',
        'query': 'Gimnasio municipal, zona 3',
      });
    });

    test('con coordenadas: apunta al punto exacto', () {
      final enlaces = enlacesDeMapa(
        'Parque',
        latitud: 14.8347,
        longitud: -91.5181,
      );
      expect(enlaces.first.toString(), startsWith('geo:14.8347,-91.5181?q='));
      expect(enlaces.last.queryParameters['query'], '14.8347,-91.5181');
    });

    test('abrir prueba geo: y, si falla, el respaldo web', () async {
      final intentos = <Uri>[];
      final abridor = AbridorDeMapas(
        lanzar: (uri) async {
          intentos.add(uri);
          return uri.scheme == 'https';
        },
      );
      expect(await abridor.abrir('Gimnasio'), isTrue);
      expect(intentos.map((u) => u.scheme), ['geo', 'https']);
    });

    test('abrir devuelve false si nada se puede abrir', () async {
      final abridor = AbridorDeMapas(lanzar: (_) async => false);
      expect(await abridor.abrir('Gimnasio'), isFalse);
    });

    test('solo presenciales e híbridas admiten Cómo llegar', () {
      expect(admiteComoLlegar('Presencial'), isTrue);
      expect(admiteComoLlegar('Híbrida'), isTrue);
      expect(admiteComoLlegar('Virtual'), isFalse);
    });

    test('el AndroidManifest declara las consultas de geo: y https:', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:scheme="geo"'));
      expect(manifest, contains('android:scheme="https"'));
    });
  });

  group('Detalle', () {
    late List<Uri> abiertos;
    late bool resultado;

    Widget detalle(Competencia competencia, {TransitionBuilder? builder}) {
      return ProviderScope(
        overrides: [
          competenciasRepositoryProvider.overrideWithValue(
            FakeCompetenciasRepository.conDatos([competencia]),
          ),
          relojProvider.overrideWithValue(() => hoy),
          abridorDeMapasProvider.overrideWithValue(
            AbridorDeMapas(
              lanzar: (uri) async {
                abiertos.add(uri);
                return resultado;
              },
            ),
          ),
        ],
        child: MaterialApp(
          theme: temaCompetihub(),
          builder: builder,
          home: CompetitionDetailScreen(competitionId: competencia.id),
        ),
      );
    }

    final boton = find.byKey(const ValueKey('detalle-como-llegar'));

    Future<void> tocarBoton(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        boton,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    setUp(() {
      abiertos = [];
      resultado = true;
    });

    testWidgets('en una presencial abre la app de mapas con la dirección', (
      tester,
    ) async {
      await tester.pumpWidget(detalle(propia('Presencial')));
      await tester.pumpAndSettle();
      await tocarBoton(tester);

      expect(abiertos, hasLength(1));
      expect(abiertos.single.scheme, 'geo');
      expect(
        Uri.decodeComponent(abiertos.single.query),
        'q=Gimnasio municipal, zona 3',
      );
      expect(find.text('No se pudo abrir una app de mapas.'), findsNothing);
    });

    testWidgets('también aparece en las híbridas, pero no en las virtuales', (
      tester,
    ) async {
      await tester.pumpWidget(detalle(propia('Híbrida')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detalle-acciones')), findsOneWidget);
      expect(boton, findsOneWidget);

      await tester.pumpWidget(detalle(propia('Virtual')));
      await tester.pumpAndSettle();
      expect(boton, findsNothing);
    });

    testWidgets('si no se puede abrir, lo dice y permite copiar la dirección', (
      tester,
    ) async {
      resultado = false;
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'Clipboard.setData') {
            copiado = (llamada.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(detalle(propia('Presencial')));
      await tester.pumpAndSettle();
      await tocarBoton(tester);

      // Probó las dos vías antes de rendirse.
      expect(abiertos.map((u) => u.scheme), ['geo', 'https']);
      expect(find.text('No se pudo abrir una app de mapas.'), findsOneWidget);

      await tester.tap(find.text('Copiar dirección'));
      await tester.pumpAndSettle();
      expect(copiado, 'Gimnasio municipal, zona 3');
      expect(find.text('Dirección copiada.'), findsOneWidget);
    });

    testWidgets('en una de ejemplo avisa que la ubicación es ficticia', (
      tester,
    ) async {
      final ejemplo = competenciasMock.firstWhere(
        (c) => c.id == 'mock-sports-01',
      );
      await tester.pumpWidget(detalle(ejemplo));
      await tester.pumpAndSettle();
      await tocarBoton(tester);

      expect(find.text('Ubicación ficticia'), findsOneWidget);
      expect(abiertos, isEmpty);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(abiertos, isEmpty);

      await tester.tap(boton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('como-llegar-abrir-igual')));
      await tester.pumpAndSettle();
      expect(abiertos, hasLength(1));
    });

    testWidgets('a 360 dp y texto 2.0, la fila de acciones no se desborda', (
      tester,
    ) async {
      usarTelefono360(tester);
      await tester.pumpWidget(
        detalle(propia('Presencial'), builder: textoGrande),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        boton,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Con texto grande, los botones pasan a otra línea.
      final guardar = tester.getTopLeft(
        find.byKey(const ValueKey('guardar-local-lugar')),
      );
      expect(tester.getTopLeft(boton).dy, greaterThan(guardar.dy));
    });
  });
}
