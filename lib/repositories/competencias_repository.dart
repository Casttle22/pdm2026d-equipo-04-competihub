import '../data/competencia.dart';
import '../data/mock_competencias.dart';

// Única fuente de competencias de la app (S14).
// Hoy lee los datos ficticios de competenciasMock y simula una espera breve
// para que la pantalla pueda mostrar el estado de carga. Si mañana los datos
// vienen de otro lugar, solo cambia esta clase.
//
// Contrato:
// - Lista vacía: la consulta funcionó, pero no hay competencias.
// - null en obtenerCompetenciaPorId: no existe una competencia con ese id.
// - Excepción: la consulta falló.
//
// En las pruebas se reemplaza por un repositorio falso que extiende esta
// clase (ver test/fakes/fake_competencias_repository.dart).
class CompetenciasRepository {
  const CompetenciasRepository({
    this.espera = const Duration(milliseconds: 600),
  });

  final Duration espera;

  Future<List<Competencia>> obtenerCompetencias() async {
    await Future<void>.delayed(espera);
    return competenciasMock;
  }

  Future<Competencia?> obtenerCompetenciaPorId(String id) async {
    await Future<void>.delayed(espera);
    for (final competencia in competenciasMock) {
      if (competencia.id == id) {
        return competencia;
      }
    }
    return null;
  }
}
