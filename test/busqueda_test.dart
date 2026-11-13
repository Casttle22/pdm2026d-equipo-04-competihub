import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/utils/busqueda.dart';
import 'package:flutter_test/flutter_test.dart';

// Módulo 3: búsqueda por título, ubicación y descripción, sin distinguir
// mayúsculas ni tildes.
void main() {
  final olimpiada = competenciasMock.firstWhere(
    (c) => c.id == 'mock-academic-02',
  );
  final carrera = competenciasMock.firstWhere((c) => c.id == 'mock-sports-01');

  test('normalizarTexto quita tildes y mayúsculas', () {
    expect(normalizarTexto('Olimpíada de LÓGICA'), 'olimpiada de logica');
    expect(normalizarTexto('Órbita, pingüino, año'), 'orbita, pinguino, ano');
  });

  test('encuentra por título sin importar mayúsculas ni tildes', () {
    expect(coincideConBusqueda(olimpiada, 'LOGICA'), isTrue);
    expect(coincideConBusqueda(olimpiada, 'lógica'), isTrue);
    expect(coincideConBusqueda(olimpiada, 'olimpíada'), isTrue);
    expect(coincideConBusqueda(carrera, 'logica'), isFalse);
  });

  test('encuentra por ubicación y por descripción', () {
    expect(coincideConBusqueda(carrera, 'parque nube'), isTrue);
    expect(coincideConBusqueda(olimpiada, 'acertijos'), isTrue);
    expect(coincideConBusqueda(olimpiada, 'parque'), isFalse);
  });

  test('con varias palabras, todas deben aparecer', () {
    expect(coincideConBusqueda(carrera, 'carrera kilometros'), isTrue);
    expect(coincideConBusqueda(carrera, 'carrera ajedrez'), isFalse);
  });

  test('una consulta vacía o de espacios coincide con todo', () {
    for (final competencia in competenciasMock) {
      expect(coincideConBusqueda(competencia, ''), isTrue);
      expect(coincideConBusqueda(competencia, '   '), isTrue);
    }
  });

  test('no busca en campos que no se prometen (reglas, costo)', () {
    // «dorsal» solo aparece en las instrucciones de la carrera.
    expect(coincideConBusqueda(carrera, 'dorsal'), isFalse);
  });

  test('encuentra por organizador, como promete el buscador', () {
    final copa = competenciasMock.firstWhere((c) => c.id == 'mock-esports-01');
    expect(copa.organizador, 'Club ficticio de arena digital');
    expect(coincideConBusqueda(copa, 'club arena'), isTrue);
    expect(coincideConBusqueda(carrera, 'club arena'), isFalse);
  });

  test('el filtro de ubicación pone las híbridas en ambas opciones', () {
    final porModalidad = {for (final c in competenciasMock) c.modalidad: c};
    final presencial = porModalidad['Presencial']!;
    final virtual = porModalidad['Virtual']!;
    final hibrida = porModalidad['Híbrida']!;
    for (final c in [presencial, virtual, hibrida]) {
      expect(coincideConUbicacion(c, FiltroUbicacion.todas), isTrue);
    }
    expect(
      coincideConUbicacion(presencial, FiltroUbicacion.quetzaltenango),
      isTrue,
    );
    expect(
      coincideConUbicacion(virtual, FiltroUbicacion.quetzaltenango),
      isFalse,
    );
    expect(
      coincideConUbicacion(hibrida, FiltroUbicacion.quetzaltenango),
      isTrue,
    );
    expect(coincideConUbicacion(presencial, FiltroUbicacion.online), isFalse);
    expect(coincideConUbicacion(virtual, FiltroUbicacion.online), isTrue);
    expect(coincideConUbicacion(hibrida, FiltroUbicacion.online), isTrue);
  });
}
