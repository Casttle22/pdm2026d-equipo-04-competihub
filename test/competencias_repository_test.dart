import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/repositories/competencias_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// Contrato del repositorio compartido por Feed y Detalle.
void main() {
  const repositorio = CompetenciasRepository(espera: Duration.zero);

  test('obtenerCompetencias devuelve los mocks sin alterarlos', () async {
    final competencias = await repositorio.obtenerCompetencias();

    expect(
      competencias.map((competencia) => competencia.id).toList(),
      competenciasMock.map((competencia) => competencia.id).toList(),
    );
  });

  test('obtenerCompetenciaPorId devuelve la competencia de ese id', () async {
    final esperada = competenciasMock[1];

    final competencia = await repositorio.obtenerCompetenciaPorId(esperada.id);

    expect(competencia?.id, esperada.id);
    expect(competencia?.titulo, esperada.titulo);
  });

  test('obtenerCompetenciaPorId devuelve null si el id no existe', () async {
    final competencia = await repositorio.obtenerCompetenciaPorId(
      'id-inexistente',
    );

    expect(competencia, isNull);
  });
}
