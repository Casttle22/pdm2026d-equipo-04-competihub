import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/base_de_prueba.dart';

// Módulo 1 (Issue 9): datos de ejemplo con fechas vigentes.
void main() {
  // Miércoles 11 de noviembre de 2026, 10:30.
  final hoy = DateTime(2026, 11, 11, 10, 30);

  DateTime fecha(Object? milisegundos) =>
      DateTime.fromMillisecondsSinceEpoch(milisegundos! as int);

  test('fechasDeEjemplo conserva la hora y la duración de cada ejemplo', () {
    final copa = fechasDeEjemplo('mock-esports-01', hoy)!;
    expect(copa.inicio, DateTime(2026, 11, 14, 18));
    expect(copa.fin, DateTime(2026, 11, 14, 21));

    // Dura dos días en los datos base.
    final olimpiada = fechasDeEjemplo('mock-academic-02', hoy)!;
    expect(olimpiada.inicio, DateTime(2026, 11, 29, 10));
    expect(olimpiada.fin, DateTime(2026, 11, 30, 12));

    final carrera = fechasDeEjemplo('mock-sports-01', hoy)!;
    expect(carrera.inicio, DateTime(2026, 11, 23, 7, 30));
    expect(carrera.fin, isNull);

    expect(fechasDeEjemplo('local-1', hoy), isNull);
    expect(fechasDeEjemplo('mock-desconocida', hoy), isNull);
  });

  test('Todos los ejemplos tienen fecha relativa y solo uno queda en el '
      'pasado', () {
    expect(
      diasDeInicioDeEjemplo.keys.toSet(),
      competenciasMock.map((c) => c.id).toSet(),
    );
    expect(diasDeInicioDeEjemplo.values.where((dias) => dias < 0).length, 1);
  });

  test('Una instalación nueva siembra los ejemplos con fechas relativas al '
      'día de creación', () async {
    final base = await BaseDePrueba.crear();
    final db = await base.abrir(version: 2, hoy: hoy);
    final filas = await db.query('competencias');
    await db.close();

    expect(filas.length, competenciasMock.length);
    for (final fila in filas) {
      final esperadas = fechasDeEjemplo(fila['id']! as String, hoy)!;
      expect(fecha(fila['fecha_inicio']), esperadas.inicio);
    }
  });

  test('La migración a v2 actualiza solo las filas «mock-» y no toca las '
      'creadas en la app', () async {
    final base = await BaseDePrueba.crear();

    // Base de la versión 1, con una competencia creada por la persona y un
    // ejemplo eliminado.
    final v1 = await base.abrir(version: 1, hoy: hoy);
    final filaUsuario = filaDeUsuarioV1();
    await v1.insert('competencias', filaUsuario);
    await v1.delete(
      'competencias',
      where: 'id = ?',
      whereArgs: ['mock-sports-01'],
    );
    final antes = {
      for (final fila in await v1.query('competencias'))
        fila['id']! as String: fila,
    };
    expect(await versionDe(v1), 1);
    await v1.close();

    final v2 = await base.abrir(version: 2, hoy: hoy);
    expect(await versionDe(v2), 2);
    final despues = {
      for (final fila in await v2.query('competencias'))
        fila['id']! as String: fila,
    };
    await v2.close();

    // La competencia de la persona queda idéntica, columna por columna.
    expect(despues['local-1'], filaUsuario);
    // No se repone el ejemplo que la persona eliminó.
    expect(despues.containsKey('mock-sports-01'), isFalse);
    expect(despues.length, antes.length);

    for (final id in despues.keys.where((id) => id.startsWith('mock-'))) {
      final esperadas = fechasDeEjemplo(id, hoy)!;
      expect(fecha(despues[id]!['fecha_inicio']), esperadas.inicio, reason: id);
      final fin = despues[id]!['fecha_fin'];
      expect(fin == null ? null : fecha(fin), esperadas.fin, reason: id);
      // El resto de las columnas no cambia.
      final sinFechas = Map.of(despues[id]!)
        ..remove('fecha_inicio')
        ..remove('fecha_fin');
      final antesSinFechas = Map.of(antes[id]!)
        ..remove('fecha_inicio')
        ..remove('fecha_fin');
      expect(sinFechas, antesSinFechas, reason: id);
    }
  });

  test('Tras la migración, el Feed recibe las próximas primero y exactamente '
      'una finalizada al final', () async {
    final base = await BaseDePrueba.crear();
    final v1 = await base.abrir(version: 1, hoy: hoy);
    await v1.close();

    final datos = CompetenciasDatabase(
      openDatabase: () => base.abrir(version: 2, hoy: hoy),
      ahora: () => hoy,
    );
    final competencias = await datos.obtenerCompetencias();

    final finalizadas = competencias
        .where((c) => estaFinalizada(c, hoy))
        .toList();
    expect(finalizadas.map((c) => c.id), ['mock-esports-02']);
    expect(competencias.last.id, 'mock-esports-02');
    expect(competencias.first.id, 'mock-esports-01');
    expect(competencias.every((c) => c.esDeEjemplo), isTrue);
  });
}
