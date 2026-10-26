import 'package:competihub/data/competencia.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/repositories/competencias_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repositorio falso para pruebas: responde lo que la prueba indique, sin
// esperas reales. `respuesta` puede cambiarse durante la prueba (por ejemplo,
// fallar primero y devolver datos después) y `llamadas` cuenta las consultas.
class FakeCompetenciasRepository extends CompetenciasRepository {
  FakeCompetenciasRepository(this.respuesta);

  FakeCompetenciasRepository.conDatos(List<Competencia> competencias)
    : this(() async => competencias);

  Future<List<Competencia>> Function() respuesta;
  var llamadas = 0;

  @override
  Future<List<Competencia>> obtenerCompetencias() {
    llamadas++;
    return respuesta();
  }
}

// Monta `child` con el repositorio falso en lugar del real.
Widget conRepositorio(CompetenciasRepository repositorio, Widget child) {
  return ProviderScope(
    overrides: [competenciasRepositoryProvider.overrideWithValue(repositorio)],
    child: child,
  );
}
