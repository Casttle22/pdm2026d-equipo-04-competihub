import 'package:competihub/data/competencia.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/providers/reloj_provider.dart';
import 'package:competihub/repositories/competencias_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  // Mis eventos en memoria. Las pruebas pueden empezar con algunas
  // guardadas, o hacer que guardar falle.
  final guardados = <String>{};
  Object? errorAlGuardar;

  @override
  Future<Set<String>> obtenerIdsGuardados() async => {...guardados};

  @override
  Future<void> guardarCompetencia(String id) async {
    final error = errorAlGuardar;
    if (error != null) {
      throw error;
    }
    guardados.add(id);
  }

  @override
  Future<void> quitarGuardado(String id) async {
    final error = errorAlGuardar;
    if (error != null) {
      throw error;
    }
    guardados.remove(id);
  }

  final idsConsultados = <String>[];

  @override
  Future<List<Competencia>> obtenerCompetencias() {
    llamadas++;
    return respuesta();
  }

  @override
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

// Hora fija de las pruebas que no eligen otra: 1 de diciembre de 2026, cuando
// todas las competencias de `competenciasMock` ya finalizaron. Así el
// resultado no depende del día en que se ejecutan.
final DateTime relojDePrueba = DateTime(2026, 12, 1, 12);

// Monta `child` con el repositorio falso en lugar del real y con la hora
// fija (`ahora`, o relojDePrueba).
Widget conRepositorio(
  CompetenciasRepository repositorio,
  Widget child, {
  DateTime? ahora,
}) {
  return ProviderScope(
    overrides: [
      competenciasRepositoryProvider.overrideWithValue(repositorio),
      relojProvider.overrideWithValue(() => ahora ?? relojDePrueba),
    ],
    child: child,
  );
}

// La lista vertical del Inicio. Desde que el Inicio tiene un campo de
// búsqueda y la fila de Destacados hay más de un área desplazable en
// pantalla, así que las pruebas indican cuál quieren mover.
Finder get listaDeInicio => find
    .descendant(
      of: find.byKey(const ValueKey('inicio-lista')),
      matching: find.byType(Scrollable),
    )
    .first;
