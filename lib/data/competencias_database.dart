import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../utils/fechas.dart';
import 'competencia.dart';
import 'competencia_draft.dart';
import 'mock_competencias.dart';

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
  static const _tableName = 'competencias';

  final Future<Database> Function() _openDatabase;
  final DateTime Function() _ahora;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _openDatabase();

  static Future<Database> _openDefaultDatabase() async {
    final databasesPath = await getDatabasesPath();
    return openDatabase(
      '$databasesPath/$_databaseName',
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_tableName (
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
          batch.insert(_tableName, _toMap(competencia));
        }
        await batch.commit(noResult: true);
      },
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
    final competencia = _fromDraft(id, draft);
    await database.insert(_tableName, _toMap(competencia));
    return competencia;
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

  static Map<String, Object?> _toMap(Competencia competencia) {
    return <String, Object?>{
      'id': competencia.id,
      ..._valuesToMap(
        titulo: competencia.titulo,
        categoria: competencia.categoria,
        fechaInicio: competencia.fechaInicio,
        ubicacion: competencia.ubicacion,
        modalidad: competencia.modalidad,
        descripcion: competencia.descripcion,
        reglas: competencia.reglas,
        costo: competencia.costo,
        instruccionesParticipacion: competencia.instruccionesParticipacion,
        fechaFin: competencia.fechaFin,
        inscripcionUrl: competencia.inscripcionUrl,
        contacto: competencia.contacto,
        imagenUrl: competencia.imagenUrl,
      ),
    };
  }

  static Map<String, Object?> _draftToMap(CompetenciaDraft draft) {
    return _valuesToMap(
      titulo: draft.titulo,
      categoria: draft.categoria,
      fechaInicio: draft.fechaInicio,
      ubicacion: draft.ubicacion,
      modalidad: draft.modalidad,
      descripcion: draft.descripcion,
      reglas: draft.reglas,
      costo: draft.costo,
      instruccionesParticipacion: draft.instruccionesParticipacion,
      fechaFin: draft.fechaFin,
      inscripcionUrl: draft.inscripcionUrl,
      contacto: draft.contacto,
      imagenUrl: draft.imagenUrl,
    );
  }

  static Competencia _fromDraft(String id, CompetenciaDraft draft) {
    return Competencia(
      id: id,
      titulo: draft.titulo,
      categoria: draft.categoria,
      fechaInicio: draft.fechaInicio,
      ubicacion: draft.ubicacion,
      modalidad: draft.modalidad,
      descripcion: draft.descripcion,
      reglas: draft.reglas,
      costo: draft.costo,
      instruccionesParticipacion: draft.instruccionesParticipacion,
      fechaFin: draft.fechaFin,
      inscripcionUrl: draft.inscripcionUrl,
      contacto: draft.contacto,
      imagenUrl: draft.imagenUrl,
    );
  }

  static String _generateId() {
    final random = Random.secure();
    final suffix = List.generate(
      4,
      (_) => random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    return 'local-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  static Map<String, Object?> _valuesToMap({
    required String titulo,
    required String categoria,
    required DateTime fechaInicio,
    required String ubicacion,
    required String modalidad,
    required String descripcion,
    required String reglas,
    required String costo,
    required String instruccionesParticipacion,
    required DateTime? fechaFin,
    required String? inscripcionUrl,
    required String? contacto,
    required String? imagenUrl,
  }) {
    return <String, Object?>{
      'titulo': titulo,
      'categoria': categoria,
      'fecha_inicio': fechaInicio.millisecondsSinceEpoch,
      'ubicacion': ubicacion,
      'modalidad': modalidad,
      'descripcion': descripcion,
      'reglas': reglas,
      'costo': costo,
      'instrucciones_participacion': instruccionesParticipacion,
      'fecha_fin': fechaFin?.millisecondsSinceEpoch,
      'inscripcion_url': inscripcionUrl,
      'contacto': contacto,
      'imagen_url': imagenUrl,
    };
  }

  static Competencia _fromMap(Map<String, Object?> map) {
    return Competencia(
      id: map['id']! as String,
      titulo: map['titulo']! as String,
      categoria: map['categoria']! as String,
      fechaInicio: DateTime.fromMillisecondsSinceEpoch(
        map['fecha_inicio']! as int,
      ),
      ubicacion: map['ubicacion']! as String,
      modalidad: map['modalidad']! as String,
      descripcion: map['descripcion']! as String,
      reglas: map['reglas']! as String,
      costo: map['costo']! as String,
      instruccionesParticipacion: map['instrucciones_participacion']! as String,
      fechaFin: switch (map['fecha_fin']) {
        final int milliseconds => DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
        ),
        _ => null,
      },
      inscripcionUrl: map['inscripcion_url'] as String?,
      contacto: map['contacto'] as String?,
      imagenUrl: map['imagen_url'] as String?,
    );
  }
}
