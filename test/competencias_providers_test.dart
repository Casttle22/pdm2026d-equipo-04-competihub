import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/providers/competencias_providers.dart';
import 'package:competihub/repositories/competencias_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las acciones refrescan lista y detalle después de escribir', () async {
    final repository = _CrudRepository([competenciasMock.first]);
    final container = ProviderContainer(
      overrides: [competenciasRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final id = competenciasMock.first.id;

    await container.read(competenciasProvider.future);
    await container.read(competenciaPorIdProvider(id).future);

    final draft = _draftFrom(competenciasMock.first, titulo: 'Editada');
    await container.read(competenciasActionsProvider).actualizar(id, draft);

    final lista = await container.read(competenciasProvider.future);
    final detalle = await container.read(competenciaPorIdProvider(id).future);
    expect(lista.single.titulo, 'Editada');
    expect(detalle?.titulo, 'Editada');

    await container.read(competenciasActionsProvider).eliminar(id);
    expect(await container.read(competenciasProvider.future), isEmpty);
    expect(await container.read(competenciaPorIdProvider(id).future), isNull);
  });

  test('una escritura fallida no invalida las consultas', () async {
    final repository = _CrudRepository([competenciasMock.first]);
    final container = ProviderContainer(
      overrides: [competenciasRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(competenciasProvider.future);
    expect(repository.listReads, 1);

    await expectLater(
      container
          .read(competenciasActionsProvider)
          .eliminar('identificador-inexistente'),
      throwsStateError,
    );

    await container.read(competenciasProvider.future);
    expect(repository.listReads, 1);
  });
}

CompetenciaDraft _draftFrom(Competencia competencia, {required String titulo}) {
  return CompetenciaDraft(
    titulo: titulo,
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
  );
}

class _CrudRepository extends CompetenciasRepository {
  _CrudRepository(this.items);

  final List<Competencia> items;
  var listReads = 0;

  @override
  Future<List<Competencia>> obtenerCompetencias() async {
    listReads++;
    return [...items];
  }

  @override
  Future<Competencia?> obtenerCompetenciaPorId(String id) async {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> actualizarCompetencia(String id, CompetenciaDraft draft) async {
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('No existe una competencia con id $id.');
    }
    items[index] = _fromDraft(id, draft);
  }

  @override
  Future<void> eliminarCompetencia(String id) async {
    final previousLength = items.length;
    items.removeWhere((item) => item.id == id);
    if (items.length == previousLength) {
      throw StateError('No existe una competencia con id $id.');
    }
  }

  Competencia _fromDraft(String id, CompetenciaDraft draft) {
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
}
