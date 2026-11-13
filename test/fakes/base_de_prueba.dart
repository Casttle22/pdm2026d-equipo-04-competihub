import 'dart:io';

import 'package:competihub/data/competencias_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Base de datos SQLite real (en un archivo temporal) para probar las
// migraciones. sqflite_common_ffi es solo dependencia de desarrollo.
class BaseDePrueba {
  BaseDePrueba._(this._carpeta);

  final Directory _carpeta;

  String get ruta => '${_carpeta.path}/competihub_prueba.db';

  // Crea la carpeta temporal y la borra al terminar la prueba.
  static Future<BaseDePrueba> crear() async {
    sqfliteFfiInit();
    final carpeta = await Directory.systemTemp.createTemp('competihub_');
    addTearDown(() async {
      try {
        await carpeta.delete(recursive: true);
      } on FileSystemException {
        // En Windows el archivo puede seguir en uso un instante; no afecta.
      }
    });
    return BaseDePrueba._(carpeta);
  }

  // Abre (o migra) la base en la versión indicada, con una fecha fija.
  Future<Database> abrir({required int version, required DateTime hoy}) {
    return abrirBaseCompetihub(
      fabrica: databaseFactoryFfiNoIsolate,
      ruta: ruta,
      ahora: () => hoy,
      version: version,
    );
  }
}

// Versión del esquema guardada en el archivo.
Future<int> versionDe(Database db) async {
  final filas = await db.rawQuery('PRAGMA user_version');
  return filas.single.values.single! as int;
}

// Fila de una competencia creada en la app, con las columnas de la versión 1.
Map<String, Object?> filaDeUsuarioV1({
  String id = 'local-1',
  String titulo = 'Torneo de la facultad',
}) {
  return <String, Object?>{
    'id': id,
    'titulo': titulo,
    'categoria': 'Deportiva',
    'fecha_inicio': DateTime(2026, 3, 5, 15).millisecondsSinceEpoch,
    'ubicacion': 'Cancha central',
    'modalidad': 'Presencial',
    'descripcion': 'Creada por una persona en la app.',
    'reglas': 'Equipos de cinco.',
    'costo': 'Q20',
    'instrucciones_participacion': 'Anotarse en la cancha.',
    'fecha_fin': DateTime(2026, 3, 5, 18).millisecondsSinceEpoch,
    'inscripcion_url': 'https://example.com/torneo',
    'contacto': 'torneo@example.com',
    'imagen_url': null,
  };
}
