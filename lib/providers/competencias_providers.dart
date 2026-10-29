import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../repositories/competencias_repository.dart';

// Provider del repositorio: es el punto que las pruebas reemplazan con
// `competenciasRepositoryProvider.overrideWithValue(falso)`.
final competenciasRepositoryProvider = Provider<CompetenciasRepository>((ref) {
  return const CompetenciasRepository();
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
// Se deja preparado como parte del contrato compartido; la pantalla de
// Detalle lo adoptará en el trabajo de su pareja.
final competenciaPorIdProvider = FutureProvider.family<Competencia?, String>((
  ref,
  id,
) {
  final repository = ref.watch(competenciasRepositoryProvider);
  return repository.obtenerCompetenciaPorId(id);
}, retry: (_, _) => null);
