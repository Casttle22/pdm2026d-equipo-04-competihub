import '../data/competencia.dart';
import '../data/competencia_draft.dart';
import '../data/competencias_database.dart';

// Única fuente de competencias de la app. La implementación predeterminada
// persiste los datos en SQLite.
//
// Contrato:
// - Lista vacía: la consulta funcionó, pero no hay competencias.
// - null en obtenerCompetenciaPorId: no existe una competencia con ese id.
// - Excepción: la consulta falló.
//
// En las pruebas se reemplaza por un repositorio falso que extiende esta
// clase (ver test/fakes/fake_competencias_repository.dart).
class CompetenciasRepository {
  CompetenciasRepository({
    CompetenciasDataSource? dataSource,
    this.espera = Duration.zero,
  }) : _dataSource = dataSource ?? CompetenciasDatabase();

  final Duration espera;
  final CompetenciasDataSource _dataSource;

  Future<List<Competencia>> obtenerCompetencias() async {
    await Future<void>.delayed(espera);
    return _dataSource.obtenerCompetencias();
  }

  Future<Competencia?> obtenerCompetenciaPorId(String id) async {
    await Future<void>.delayed(espera);
    return _dataSource.obtenerCompetenciaPorId(id);
  }

  Future<Competencia> crearCompetencia(CompetenciaDraft draft) {
    return _dataSource.crearCompetencia(draft);
  }

  Future<void> actualizarCompetencia(String id, CompetenciaDraft draft) {
    return _dataSource.actualizarCompetencia(id, draft);
  }

  Future<void> eliminarCompetencia(String id) {
    return _dataSource.eliminarCompetencia(id);
  }

  // Mis eventos: competencias guardadas en este teléfono.
  Future<Set<String>> obtenerIdsGuardados() {
    return _dataSource.obtenerIdsGuardados();
  }

  Future<void> guardarCompetencia(String id) {
    return _dataSource.guardarCompetencia(id);
  }

  Future<void> quitarGuardado(String id) {
    return _dataSource.quitarGuardado(id);
  }
}
