import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../utils/fechas.dart';
import 'competencia.dart';
import 'competencia_draft.dart';
import 'mock_competencias.dart';

// Versión actual del esquema. Cada cambio de esquema o de datos sembrados
// sube este número y agrega un paso en _migrar. Historial:
// 1: tabla competencias con los datos de ejemplo de fechas fijas.
// 2: las fechas de los datos de ejemplo pasan a ser relativas al día de la
//    migración, para que no queden todos como finalizados.
// 3: columna fecha_limite_inscripcion (opcional).
const int versionEsquema = 3;

const String _tablaCompetencias = 'competencias';

// Abre la base de datos y la lleva a `version`. Recibe la fábrica y la hora
// para poder probar las migraciones con sqflite_common_ffi y una fecha fija;
// `version` solo se cambia en las pruebas, para construir una base antigua.
//
// Una instalación nueva crea el esquema de la versión 1 y recorre las mismas
// migraciones que una instalación existente: así hay un solo camino que
// mantener y probar.
Future<Database> abrirBaseCompetihub({
  required DatabaseFactory fabrica,
  required String ruta,
  required DateTime Function() ahora,
  int version = versionEsquema,
}) {
  return fabrica.openDatabase(
    ruta,
    options: OpenDatabaseOptions(
      version: version,
      onCreate: (database, version) async {
        await _crearEsquemaV1(database);
        await _migrar(database, 1, version, ahora());
      },
      onUpgrade: (database, anterior, nueva) =>
          _migrar(database, anterior, nueva, ahora()),
    ),
  );
}

Future<void> _crearEsquemaV1(Database database) async {
  await database.execute('''
    CREATE TABLE $_tablaCompetencias (
      id TEXT PRIMARY KEY NOT NULL,
      titulo TEXT NOT NULL,
      categoria TEXT NOT NULL,
      fecha_inicio INTEGER NOT NULL,
      ubicacion TEXT NOT NULL,
      modalidad TEXT NOT NULL,
      descripcion TEXT NOT NULL,
      reglas TEXT NOT NULL,
      costo TEXT NOT NULL,
      instrucciones_participacion TEXT NOT NULL,
      fecha_fin INTEGER,
      inscripcion_url TEXT,
      contacto TEXT,
      imagen_url TEXT
    )
  ''');

  final batch = database.batch();
  for (final competencia in competenciasMock) {
    batch.insert(_tablaCompetencias, <String, Object?>{
      'id': competencia.id,
      'titulo': competencia.titulo,
      'categoria': competencia.categoria,
      'fecha_inicio': competencia.fechaInicio.millisecondsSinceEpoch,
      'ubicacion': competencia.ubicacion,
      'modalidad': competencia.modalidad,
      'descripcion': competencia.descripcion,
      'reglas': competencia.reglas,
      'costo': competencia.costo,
      'instrucciones_participacion': competencia.instruccionesParticipacion,
      'fecha_fin': competencia.fechaFin?.millisecondsSinceEpoch,
      'inscripcion_url': competencia.inscripcionUrl,
      'contacto': competencia.contacto,
      'imagen_url': competencia.imagenUrl,
    });
  }
  await batch.commit(noResult: true);
}

// Aplica en orden los pasos que faltan entre dos versiones. Ningún paso
// borra ni modifica las competencias creadas en la app (ids «local-»).
Future<void> _migrar(
  Database database,
  int anterior,
  int nueva,
  DateTime hoy,
) async {
  for (var version = anterior + 1; version <= nueva; version++) {
    switch (version) {
      case 2:
        await _migrarAV2(database, hoy);
      case 3:
        await _migrarAV3(database, hoy);
    }
  }
}

// v2: recalcula las fechas de las competencias de ejemplo (ids «mock-») que
// sigan en la base. No vuelve a crear las que la persona haya eliminado.
Future<void> _migrarAV2(Database database, DateTime hoy) async {
  final filas = await database.query(
    _tablaCompetencias,
    columns: ['id'],
    where: "id LIKE 'mock-%'",
  );
  final batch = database.batch();
  for (final fila in filas) {
    final id = fila['id']! as String;
    final fechas = fechasDeEjemplo(id, hoy);
    if (fechas == null) {
      continue;
    }
    batch.update(
      _tablaCompetencias,
      <String, Object?>{
        'fecha_inicio': fechas.inicio.millisecondsSinceEpoch,
        'fecha_fin': fechas.fin?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  await batch.commit(noResult: true);
}

// v3: fecha límite de inscripción. La columna es opcional, así que las
// competencias existentes quedan sin límite (y sin estado de inscripción).
// A los ejemplos se les asigna uno para que los cuatro estados se puedan ver.
Future<void> _migrarAV3(Database database, DateTime hoy) async {
  await database.execute(
    'ALTER TABLE $_tablaCompetencias '
    'ADD COLUMN fecha_limite_inscripcion INTEGER',
  );
  final batch = database.batch();
  for (final id in diasDeCierreDeEjemplo.keys) {
    batch.update(
      _tablaCompetencias,
      <String, Object?>{
        'fecha_limite_inscripcion': limiteDeInscripcionDeEjemplo(
          id,
          hoy,
        )?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  await batch.commit(noResult: true);
}

abstract class CompetenciasDataSource {
  Future<List<Competencia>> obtenerCompetencias();

  Future<Competencia?> obtenerCompetenciaPorId(String id);

  Future<Competencia> crearCompetencia(CompetenciaDraft draft);

  Future<void> actualizarCompetencia(String id, CompetenciaDraft draft);

  Future<void> eliminarCompetencia(String id);
}

class CompetenciasDatabase implements CompetenciasDataSource {
  CompetenciasDatabase({
    Future<Database> Function()? openDatabase,
    DateTime Function()? ahora,
  }) : _openDatabase = openDatabase ?? _openDefaultDatabase,
       _ahora = ahora ?? DateTime.now;

  static const _databaseName = 'competihub.db';
  static const _tableName = _tablaCompetencias;

  final Future<Database> Function() _openDatabase;
  final DateTime Function() _ahora;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _openDatabase();

  static Future<Database> _openDefaultDatabase() async {
    final databasesPath = await getDatabasesPath();
    return abrirBaseCompetihub(
      fabrica: databaseFactory,
      ruta: '$databasesPath/$_databaseName',
      ahora: DateTime.now,
    );
  }

  @override
  Future<List<Competencia>> obtenerCompetencias() async {
    final database = await _db;
    final rows = await database.query(_tableName, orderBy: 'rowid ASC');
    // Próximas primero y finalizadas al final (ver lib/utils/fechas.dart).
    return List<Competencia>.unmodifiable(
      ordenarPorCercania(rows.map(_fromMap), _ahora()),
    );
  }

  @override
  Future<Competencia?> obtenerCompetenciaPorId(String id) async {
    final database = await _db;
    final rows = await database.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromMap(rows.single);
  }

  @override
  Future<Competencia> crearCompetencia(CompetenciaDraft draft) async {
    final database = await _db;
    final id = _generateId();
    await database.insert(_tableName, <String, Object?>{
      'id': id,
      ..._draftToMap(draft),
    });
    return Competencia.desdeBorrador(id, draft);
  }

  @override
  Future<void> actualizarCompetencia(String id, CompetenciaDraft draft) async {
    final database = await _db;
    final affectedRows = await database.update(
      _tableName,
      _draftToMap(draft),
      where: 'id = ?',
      whereArgs: [id],
    );
    if (affectedRows == 0) {
      throw StateError('No existe una competencia con id $id.');
    }
  }

  @override
  Future<void> eliminarCompetencia(String id) async {
    final database = await _db;
    final affectedRows = await database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (affectedRows == 0) {
      throw StateError('No existe una competencia con id $id.');
    }
  }

  static String _generateId() {
    final random = Random.secure();
    final suffix = List.generate(
      4,
      (_) => random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    return 'local-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  // Columnas que vienen del formulario (todas menos el id).
  static Map<String, Object?> _draftToMap(CompetenciaDraft draft) {
    return <String, Object?>{
      'titulo': draft.titulo,
      'categoria': draft.categoria,
      'fecha_inicio': draft.fechaInicio.millisecondsSinceEpoch,
      'ubicacion': draft.ubicacion,
      'modalidad': draft.modalidad,
      'descripcion': draft.descripcion,
      'reglas': draft.reglas,
      'costo': draft.costo,
      'instrucciones_participacion': draft.instruccionesParticipacion,
      'fecha_fin': draft.fechaFin?.millisecondsSinceEpoch,
      'inscripcion_url': draft.inscripcionUrl,
      'contacto': draft.contacto,
      'imagen_url': draft.imagenUrl,
      'fecha_limite_inscripcion':
          draft.fechaLimiteInscripcion?.millisecondsSinceEpoch,
    };
  }

  static DateTime? _fechaONula(Object? milisegundos) {
    return milisegundos is int
        ? DateTime.fromMillisecondsSinceEpoch(milisegundos)
        : null;
  }

  static Competencia _fromMap(Map<String, Object?> map) {
    return Competencia(
      id: map['id']! as String,
      titulo: map['titulo']! as String,
      categoria: map['categoria']! as String,
      fechaInicio: _fechaONula(map['fecha_inicio'])!,
      ubicacion: map['ubicacion']! as String,
      modalidad: map['modalidad']! as String,
      descripcion: map['descripcion']! as String,
      reglas: map['reglas']! as String,
      costo: map['costo']! as String,
      instruccionesParticipacion: map['instrucciones_participacion']! as String,
      fechaFin: _fechaONula(map['fecha_fin']),
      inscripcionUrl: map['inscripcion_url'] as String?,
      contacto: map['contacto'] as String?,
      imagenUrl: map['imagen_url'] as String?,
      fechaLimiteInscripcion: _fechaONula(map['fecha_limite_inscripcion']),
    );
  }
}
