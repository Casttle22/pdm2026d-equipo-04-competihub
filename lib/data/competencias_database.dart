import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../utils/fechas.dart';
import 'competencia.dart';
import 'competencia_draft.dart';
import 'etapa.dart';
import 'mock_competencias.dart';

// Versión actual del esquema. Cada cambio de esquema o de datos sembrados
// sube este número y agrega un paso en _migrar. Historial:
// 1: tabla competencias con los datos de ejemplo de fechas fijas.
// 2: las fechas de los datos de ejemplo pasan a ser relativas al día de la
//    migración, para que no queden todos como finalizados.
// 3: columna fecha_limite_inscripcion (opcional).
// 4: ficha de torneo: formato, tamaño de equipo, premios y organizador
//    (todas opcionales).
// 5: tabla etapas (cronograma), que se borra junto con su competencia.
// 6: tabla guardados (Mis eventos), que también se borra con su competencia.
// 7: columnas latitud y longitud (opcionales) para el mapa.
const int versionEsquema = 7;

const String _tablaCompetencias = 'competencias';
const String _tablaEtapas = 'etapas';
const String _tablaGuardados = 'guardados';

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
      // SQLite no aplica las llaves foráneas si no se le pide en cada
      // conexión. Sin esto, borrar una competencia dejaría sus etapas.
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
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
      case 4:
        await _migrarAV4(database);
      case 5:
        await _migrarAV5(database);
      case 6:
        await _migrarAV6(database);
      case 7:
        await _migrarAV7(database);
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

// v4: ficha de torneo. Las columnas son opcionales: las competencias creadas
// en la app quedan sin ficha, en lugar de suponer un formato. Los ejemplos la
// toman de competenciasMock.
Future<void> _migrarAV4(Database database) async {
  for (final columna in [
    'formato TEXT',
    'tamano_equipo_min INTEGER',
    'tamano_equipo_max INTEGER',
    'premios TEXT',
    'organizador TEXT',
  ]) {
    await database.execute(
      'ALTER TABLE $_tablaCompetencias ADD COLUMN $columna',
    );
  }
  final batch = database.batch();
  for (final ejemplo in competenciasMock) {
    batch.update(
      _tablaCompetencias,
      <String, Object?>{
        'formato': ejemplo.formato?.name,
        'tamano_equipo_min': ejemplo.tamanoEquipoMin,
        'tamano_equipo_max': ejemplo.tamanoEquipoMax,
        'premios': ejemplo.premios,
        'organizador': ejemplo.organizador,
      },
      where: 'id = ?',
      whereArgs: [ejemplo.id],
    );
  }
  await batch.commit(noResult: true);
}

// v5: cronograma. Cada etapa pertenece a una competencia y se borra con ella
// (ON DELETE CASCADE). Los ejemplos que tienen cronograma lo reciben a partir
// de su fecha de inicio actual.
Future<void> _migrarAV5(Database database) async {
  await database.execute('''
    CREATE TABLE $_tablaEtapas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      competencia_id TEXT NOT NULL
        REFERENCES $_tablaCompetencias (id) ON DELETE CASCADE,
      nombre TEXT NOT NULL,
      fecha_hora INTEGER NOT NULL,
      descripcion TEXT,
      orden INTEGER NOT NULL
    )
  ''');
  await database.execute(
    'CREATE INDEX etapas_por_competencia '
    'ON $_tablaEtapas (competencia_id, orden)',
  );
  for (final id in etapasDeEjemplo.keys) {
    final filas = await database.query(
      _tablaCompetencias,
      columns: ['fecha_inicio'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (filas.isEmpty) {
      continue;
    }
    final inicio = DateTime.fromMillisecondsSinceEpoch(
      filas.single['fecha_inicio']! as int,
    );
    await _guardarEtapas(database, id, etapasDeEjemploDesde(id, inicio));
  }
}

// Reemplaza el cronograma de una competencia por `etapas`, en ese orden.
Future<void> _guardarEtapas(
  DatabaseExecutor database,
  String competenciaId,
  List<Etapa> etapas,
) async {
  await database.delete(
    _tablaEtapas,
    where: 'competencia_id = ?',
    whereArgs: [competenciaId],
  );
  for (final (orden, etapa) in etapas.indexed) {
    await database.insert(_tablaEtapas, <String, Object?>{
      'competencia_id': competenciaId,
      'nombre': etapa.nombre,
      'fecha_hora': etapa.fechaHora.millisecondsSinceEpoch,
      'descripcion': etapa.descripcion,
      'orden': orden,
    });
  }
}

// v6: competencias guardadas en «Mis eventos». Una fila por competencia
// guardada; si la competencia se borra, deja de estar guardada. Empieza vacía.
Future<void> _migrarAV6(Database database) async {
  await database.execute('''
    CREATE TABLE $_tablaGuardados (
      competencia_id TEXT PRIMARY KEY NOT NULL
        REFERENCES $_tablaCompetencias (id) ON DELETE CASCADE,
      guardado_en INTEGER NOT NULL
    )
  ''');
}

// v7: punto en el mapa. Las competencias creadas en la app quedan sin punto
// hasta que alguien lo elija; los ejemplos presenciales e híbridos reciben
// sus coordenadas ficticias.
Future<void> _migrarAV7(Database database) async {
  await database.execute(
    'ALTER TABLE $_tablaCompetencias ADD COLUMN latitud REAL',
  );
  await database.execute(
    'ALTER TABLE $_tablaCompetencias ADD COLUMN longitud REAL',
  );
  final batch = database.batch();
  for (final ejemplo in competenciasMock) {
    if (!ejemplo.tieneCoordenadas) {
      continue;
    }
    batch.update(
      _tablaCompetencias,
      <String, Object?>{
        'latitud': ejemplo.latitud,
        'longitud': ejemplo.longitud,
      },
      where: 'id = ?',
      whereArgs: [ejemplo.id],
    );
  }
  await batch.commit(noResult: true);
}

abstract class CompetenciasDataSource {
  Future<List<Competencia>> obtenerCompetencias();

  // Ids de las competencias guardadas en «Mis eventos».
  Future<Set<String>> obtenerIdsGuardados();

  Future<void> guardarCompetencia(String id);

  Future<void> quitarGuardado(String id);

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
  Future<Set<String>> obtenerIdsGuardados() async {
    final database = await _db;
    final filas = await database.query(
      _tablaGuardados,
      columns: ['competencia_id'],
    );
    return {for (final fila in filas) fila['competencia_id']! as String};
  }

  @override
  Future<void> guardarCompetencia(String id) async {
    final database = await _db;
    // Guardar dos veces no es un error: se ignora la segunda.
    await database.insert(_tablaGuardados, <String, Object?>{
      'competencia_id': id,
      'guardado_en': _ahora().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> quitarGuardado(String id) async {
    final database = await _db;
    await database.delete(
      _tablaGuardados,
      where: 'competencia_id = ?',
      whereArgs: [id],
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
    if (rows.isEmpty) {
      return null;
    }
    final etapas = await database.query(
      _tablaEtapas,
      where: 'competencia_id = ?',
      whereArgs: [id],
      orderBy: 'orden ASC',
    );
    return _fromMap(rows.single, etapas: etapas.map(_etapaDesdeFila).toList());
  }

  @override
  Future<Competencia> crearCompetencia(CompetenciaDraft draft) async {
    final database = await _db;
    final id = _generateId();
    // Competencia y etapas se guardan juntas: si algo falla, no queda nada a
    // medias.
    await database.transaction((txn) async {
      await txn.insert(_tableName, <String, Object?>{
        'id': id,
        ..._draftToMap(draft),
      });
      await _guardarEtapas(txn, id, draft.etapas);
    });
    return Competencia.desdeBorrador(id, draft);
  }

  @override
  Future<void> actualizarCompetencia(String id, CompetenciaDraft draft) async {
    final database = await _db;
    await database.transaction((txn) async {
      final affectedRows = await txn.update(
        _tableName,
        _draftToMap(draft),
        where: 'id = ?',
        whereArgs: [id],
      );
      if (affectedRows == 0) {
        throw StateError('No existe una competencia con id $id.');
      }
      await _guardarEtapas(txn, id, draft.etapas);
    });
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
      'formato': draft.formato?.name,
      'tamano_equipo_min': draft.tamanoEquipoMin,
      'tamano_equipo_max': draft.tamanoEquipoMax,
      'premios': draft.premios,
      'organizador': draft.organizador,
      'latitud': draft.latitud,
      'longitud': draft.longitud,
    };
  }

  static DateTime? _fechaONula(Object? milisegundos) {
    return milisegundos is int
        ? DateTime.fromMillisecondsSinceEpoch(milisegundos)
        : null;
  }

  static Etapa _etapaDesdeFila(Map<String, Object?> fila) {
    return Etapa(
      nombre: fila['nombre']! as String,
      fechaHora: _fechaONula(fila['fecha_hora'])!,
      descripcion: fila['descripcion'] as String?,
    );
  }

  static Competencia _fromMap(
    Map<String, Object?> map, {
    List<Etapa> etapas = const [],
  }) {
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
      formato: FormatoCompetencia.desdeTexto(map['formato'] as String?),
      tamanoEquipoMin: map['tamano_equipo_min'] as int?,
      tamanoEquipoMax: map['tamano_equipo_max'] as int?,
      premios: map['premios'] as String?,
      organizador: map['organizador'] as String?,
      etapas: etapas,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
    );
  }
}
