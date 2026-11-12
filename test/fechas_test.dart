import 'package:competihub/data/competencia.dart';
import 'package:competihub/data/mock_competencias.dart';
import 'package:competihub/utils/fechas.dart';
import 'package:flutter_test/flutter_test.dart';

// Competencia mínima para probar fechas; solo importan id, inicio y fin.
Competencia competencia(String id, DateTime inicio, {DateTime? fin}) {
  return Competencia(
    id: id,
    titulo: 'Competencia $id',
    categoria: 'Otras',
    fechaInicio: inicio,
    ubicacion: 'Lugar de prueba',
    modalidad: 'Presencial',
    descripcion: 'Descripción de prueba',
    reglas: 'Reglas de prueba',
    costo: 'Gratis',
    instruccionesParticipacion: 'Instrucciones de prueba',
    fechaFin: fin,
  );
}

void main() {
  // Martes 10 de noviembre de 2026, mediodía.
  final ahora = DateTime(2026, 11, 10, 12);

  group('formato de fechas', () {
    test('la fecha legible incluye día de la semana y mes abreviado', () {
      expect(formatearFechaLegible(DateTime(2026, 11, 14)), 'sáb 14 nov 2026');
      expect(formatearFechaLegible(DateTime(2026, 1, 5)), 'lun 5 ene 2026');
      expect(formatearFechaLegible(DateTime(2026, 12, 31)), 'jue 31 dic 2026');
    });

    test('la hora usa dos dígitos', () {
      expect(formatearHora(DateTime(2026, 1, 5, 8, 5)), '08:05');
      expect(formatearHora(DateTime(2026, 12, 31, 23, 59)), '23:59');
    });

    test('fecha y hora van en una sola línea', () {
      expect(
        formatearFechaHoraLegible(DateTime(2026, 11, 14, 14)),
        'sáb 14 nov 2026 · 14:00',
      );
    });
  });

  group('etiqueta de tiempo', () {
    test('cuenta los días que faltan', () {
      final c = competencia('a', DateTime(2026, 11, 14, 14));
      expect(etiquetaTemporal(c, ahora), 'Faltan 4 días');
      expect(estadoTemporal(c, ahora), EstadoTemporal.proxima);
    });

    test('mañana se cuenta por día de calendario, no por horas', () {
      final c = competencia('a', DateTime(2026, 11, 11, 0, 10));
      final casiMedianoche = DateTime(2026, 11, 10, 23, 50);
      expect(etiquetaTemporal(c, casiMedianoche), 'Mañana');
    });

    test('hoy, antes y después de la hora de inicio', () {
      final masTarde = competencia('a', DateTime(2026, 11, 10, 18));
      final yaEmpezo = competencia('b', DateTime(2026, 11, 10, 8));
      expect(etiquetaTemporal(masTarde, ahora), 'Hoy');
      // Sin fecha de fin sigue contando como de hoy hasta que termina el día.
      expect(etiquetaTemporal(yaEmpezo, ahora), 'Hoy');
      expect(estaFinalizada(yaEmpezo, ahora), isFalse);
    });

    test('en curso cuando ya empezó y aún no llega su fin', () {
      final c = competencia(
        'a',
        DateTime(2026, 11, 9, 10),
        fin: DateTime(2026, 11, 11, 12),
      );
      expect(etiquetaTemporal(c, ahora), 'En curso');
      expect(estadoTemporal(c, ahora), EstadoTemporal.enCurso);
    });

    test('finalizada cuando ya pasó su fin', () {
      final c = competencia(
        'a',
        DateTime(2026, 11, 7, 10),
        fin: DateTime(2026, 11, 8, 12),
      );
      expect(etiquetaTemporal(c, ahora), 'Finalizada');
      expect(estaFinalizada(c, ahora), isTrue);
    });

    test('sin fecha de fin, finaliza al terminar el día de inicio', () {
      final ayer = competencia('a', DateTime(2026, 11, 9, 20));
      expect(etiquetaTemporal(ayer, ahora), 'Finalizada');
      expect(estadoTemporal(ayer, ahora), EstadoTemporal.finalizada);
    });
  });

  group('orden del Feed', () {
    test('próximas primero y finalizadas al final', () {
      final pasadaVieja = competencia('pasada-vieja', DateTime(2026, 9, 12));
      final proximaLejana = competencia(
        'proxima-lejana',
        DateTime(2026, 11, 20),
      );
      final pasadaReciente = competencia(
        'pasada-reciente',
        DateTime(2026, 11, 7),
      );
      final proximaCercana = competencia(
        'proxima-cercana',
        DateTime(2026, 11, 14),
      );
      final original = [
        pasadaVieja,
        proximaLejana,
        pasadaReciente,
        proximaCercana,
      ];

      final ordenadas = ordenarPorCercania(original, ahora);

      expect(ordenadas.map((c) => c.id), [
        'proxima-cercana',
        'proxima-lejana',
        'pasada-reciente',
        'pasada-vieja',
      ]);
      // No modifica la lista recibida.
      expect(original.first, same(pasadaVieja));
      expect(original.length, 4);
    });

    test('con la misma fecha conserva el orden original', () {
      final primera = competencia('primera', DateTime(2026, 11, 14, 9));
      final segunda = competencia('segunda', DateTime(2026, 11, 14, 9));

      final ordenadas = ordenarPorCercania([primera, segunda], ahora);

      expect(ordenadas.map((c) => c.id), ['primera', 'segunda']);
    });

    test('ordena los datos de ejemplo según la fecha de hoy', () {
      final ordenadas = ordenarPorCercania(competenciasMock, ahora);

      expect(ordenadas.map((c) => c.id), [
        'mock-other-01',
        'mock-academic-02',
        'mock-sports-01',
        'mock-academic-01',
        'mock-esports-01',
        'mock-esports-02',
      ]);
    });
  });
}
