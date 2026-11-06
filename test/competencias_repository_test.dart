import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/competencia_draft.dart';
import 'package:competihub/data/competencias_database.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/repositories/competencias_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryDataSource dataSource;
  late CompetenciasRepository repositorio;

  setUp(() {
    dataSource = _MemoryDataSource(competenciasMock);
    repositorio = CompetenciasRepository(dataSource: dataSource);
  });

  test('conserva las consultas de lista y por id', () async {
    final competencias = await repositorio.obtenerCompetencias();
    final esperada = competenciasMock[1];

    expect(
      competencias.map((competencia) => competencia.id),
      competenciasMock.map((competencia) => competencia.id),
    );
    expect(
      await repositorio.obtenerCompetenciaPorId(esperada.id),
      same(esperada),
    );
    expect(await repositorio.obtenerCompetenciaPorId('id-inexistente'), isNull);
  });

  test('crea competencias con ids únicos generados por datos', () async {
    final draft = _draftFrom(competenciasMock.first, titulo: 'Nueva');

    final primera = await repositorio.crearCompetencia(draft);
    final segunda = await repositorio.crearCompetencia(draft);

    expect(primera.id, isNot(segunda.id));
    expect(primera.titulo, 'Nueva');
    expect(await repositorio.obtenerCompetenciaPorId(primera.id), isNotNull);
  });

  test('actualiza los datos sin cambiar el id', () async {
    final original = competenciasMock.first;
    final draft = _draftFrom(original, titulo: 'Título editado');

    await repositorio.actualizarCompetencia(original.id, draft);
    final actualizada = await repositorio.obtenerCompetenciaPorId(original.id);

    expect(actualizada?.id, original.id);
    expect(actualizada?.titulo, 'Título editado');
  });

  test('elimina y no repone datos cuando la fuente queda vacía', () async {
    for (final competencia in competenciasMock) {
      await repositorio.eliminarCompetencia(competencia.id);
    }

    expect(await repositorio.obtenerCompetencias(), isEmpty);

    final repositorioReabierto = CompetenciasRepository(dataSource: dataSource);
    expect(await repositorioReabierto.obtenerCompetencias(), isEmpty);
  });

  test('actualizar o eliminar un id inexistente reporta error', () async {
    final draft = _draftFrom(competenciasMock.first);

    await expectLater(
      repositorio.actualizarCompetencia('no-existe', draft),
      throwsStateError,
    );
    await expectLater(
      repositorio.eliminarCompetencia('no-existe'),
      throwsStateError,
    );
  });
}

CompetenciaDraft _draftFrom(Competencia competencia, {String? titulo}) {
  return CompetenciaDraft(
    titulo: titulo ?? competencia.titulo,
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

class _MemoryDataSource implements CompetenciasDataSource {
  _MemoryDataSource(Iterable<Competencia> seed) : _items = [...seed];

  final List<Competencia> _items;
  var _nextId = 1;

  @override
  Future<List<Competencia>> obtenerCompetencias() async => [..._items];

  @override
  Future<Competencia?> obtenerCompetenciaPorId(String id) async {
    for (final competencia in _items) {
      if (competencia.id == id) {
        return competencia;
      }
    }
    return null;
  }

  @override
  Future<Competencia> crearCompetencia(CompetenciaDraft draft) async {
    final competencia = _fromDraft('created-${_nextId++}', draft);
    _items.add(competencia);
    return competencia;
  }

  @override
  Future<void> actualizarCompetencia(String id, CompetenciaDraft draft) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('No existe una competencia con id $id.');
    }
    _items[index] = _fromDraft(id, draft);
  }

  @override
  Future<void> eliminarCompetencia(String id) async {
    final previousLength = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length == previousLength) {
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
