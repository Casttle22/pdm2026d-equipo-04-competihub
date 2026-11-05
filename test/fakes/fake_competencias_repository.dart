import 'package:competihub/data/competencia.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/repositories/competencias_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repositorio falso para pruebas: responde lo que la prueba indique, sin
// esperas reales. `respuesta` puede cambiarse durante la prueba (por ejemplo,
// fallar primero y devolver datos después) y `llamadas` cuenta las consultas.
// El Detalle usa su propia respuesta y contador por id sin cambiar el Feed.
class FakeCompetenciasRepository extends CompetenciasRepository {
  FakeCompetenciasRepository(this.respuesta, {this.respuestaPorId});

  FakeCompetenciasRepository.conDatos(List<Competencia> competencias)
    : this(() async => competencias);

  Future<List<Competencia>> Function() respuesta;
  Future<Competencia?> Function(String id)? respuestaPorId;
  var llamadas = 0;
  var llamadasPorId = 0;
  final idsConsultados = <String>[];

  @override
  Future<List<Competencia>> obtenerCompetencias() {
    llamadas++;
    return respuesta();
  }

  @override
  Future<Competencia?> obtenerCompetenciaPorId(String id) {
    llamadasPorId++;
    idsConsultados.add(id);

    final consultaPorId = respuestaPorId;
    if (consultaPorId != null) {
      return consultaPorId(id);
    }

    // Por defecto la búsqueda usa la colección falsa, no el repositorio real.
    // Así siguen funcionando los tests antiguos que llaman a conDatos(...).
    return respuesta().then((competencias) {
      for (final competencia in competencias) {
        if (competencia.id == id) return competencia;
      }
      return null;
    });
  }
}

// Monta `child` con el repositorio falso en lugar del real.
Widget conRepositorio(CompetenciasRepository repositorio, Widget child) {
  return ProviderScope(
    overrides: [competenciasRepositoryProvider.overrideWithValue(repositorio)],
    child: child,
  );
}
