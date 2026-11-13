import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../data/competencia_draft.dart';
import '../repositories/competencias_repository.dart';

// Provider del repositorio: es el punto que las pruebas reemplazan con
// `competenciasRepositoryProvider.overrideWithValue(falso)`.
final competenciasRepositoryProvider = Provider<CompetenciasRepository>((ref) {
  return CompetenciasRepository();
});

// Lista de competencias para el Feed.
// `retry: (_, _) => null` desactiva el reintento automático de Riverpod 3:
// si la consulta falla, la pantalla muestra el error y la persona decide
// cuándo reintentar con el botón (que invalida este provider).
final competenciasProvider = FutureProvider<List<Competencia>>((ref) {
  final repository = ref.watch(competenciasRepositoryProvider);
  return repository.obtenerCompetencias();
}, retry: (_, _) => null);

// Una competencia por id, para el Detalle. Devuelve null si no existe.
final competenciaPorIdProvider = FutureProvider.family<Competencia?, String>((
  ref,
  id,
) {
  final repository = ref.watch(competenciasRepositoryProvider);
  return repository.obtenerCompetenciaPorId(id);
}, retry: (_, _) => null);

// Ids de las competencias guardadas en «Mis eventos». Sin reintento
// automático, como el resto.
final guardadosProvider = FutureProvider<Set<String>>((ref) {
  final repository = ref.watch(competenciasRepositoryProvider);
  return repository.obtenerIdsGuardados();
}, retry: (_, _) => null);

final competenciasActionsProvider = Provider<CompetenciasActions>((ref) {
  return CompetenciasActions(ref, ref.watch(competenciasRepositoryProvider));
});

class CompetenciasActions {
  CompetenciasActions(this._ref, this._repository);

  final Ref _ref;
  final CompetenciasRepository _repository;

  Future<Competencia> crear(CompetenciaDraft draft) async {
    final competencia = await _repository.crearCompetencia(draft);
    _ref.invalidate(competenciasProvider);
    _ref.invalidate(competenciaPorIdProvider(competencia.id));
    return competencia;
  }

  Future<void> actualizar(String id, CompetenciaDraft draft) async {
    await _repository.actualizarCompetencia(id, draft);
    _ref.invalidate(competenciasProvider);
    _ref.invalidate(competenciaPorIdProvider(id));
  }

  Future<void> eliminar(String id) async {
    await _repository.eliminarCompetencia(id);
    _ref.invalidate(competenciasProvider);
    _ref.invalidate(competenciaPorIdProvider(id));
    // La base borra el guardado junto con la competencia.
    _ref.invalidate(guardadosProvider);
  }

  // Guarda la competencia si no lo estaba, o la quita si ya lo estaba.
  // Devuelve true si quedó guardada.
  Future<bool> alternarGuardado(String id, {required bool guardada}) async {
    if (guardada) {
      await _repository.quitarGuardado(id);
    } else {
      await _repository.guardarCompetencia(id);
    }
    _ref.invalidate(guardadosProvider);
    return !guardada;
  }
}
