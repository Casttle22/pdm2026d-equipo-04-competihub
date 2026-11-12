import '../data/competencia.dart';

// Utilidades de fecha del Feed y del Detalle. Son funciones puras: reciben
// la hora actual como parámetro para poder probarlas con una fecha fija.

const List<String> _diasCortos = [
  'lun',
  'mar',
  'mié',
  'jue',
  'vie',
  'sáb',
  'dom',
];

const List<String> _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _dosDigitos(int numero) => numero.toString().padLeft(2, '0');

// Ejemplo: «sáb 14 nov 2026».
String formatearFechaLegible(DateTime fecha) {
  final dia = _diasCortos[fecha.weekday - 1];
  final mes = _mesesCortos[fecha.month - 1];
  return '$dia ${fecha.day} $mes ${fecha.year}';
}

// Ejemplo: «14:00».
String formatearHora(DateTime fecha) =>
    '${_dosDigitos(fecha.hour)}:${_dosDigitos(fecha.minute)}';

// Ejemplo: «sáb 14 nov 2026 · 14:00».
String formatearFechaHoraLegible(DateTime fecha) =>
    '${formatearFechaLegible(fecha)} · ${formatearHora(fecha)}';

enum EstadoTemporal { proxima, enCurso, finalizada }

// Una competencia con fecha de fin termina en ese momento. Si no tiene fin,
// se considera finalizada cuando termina el día de su inicio: sin hora de
// cierre no se puede saber más.
bool estaFinalizada(Competencia competencia, DateTime ahora) {
  final fin = competencia.fechaFin;
  if (fin != null) {
    return ahora.isAfter(fin);
  }
  final inicio = competencia.fechaInicio;
  final diaSiguiente = DateTime(inicio.year, inicio.month, inicio.day + 1);
  return !ahora.isBefore(diaSiguiente);
}

EstadoTemporal estadoTemporal(Competencia competencia, DateTime ahora) {
  if (estaFinalizada(competencia, ahora)) {
    return EstadoTemporal.finalizada;
  }
  if (ahora.isBefore(competencia.fechaInicio)) {
    return EstadoTemporal.proxima;
  }
  return EstadoTemporal.enCurso;
}

// Días de calendario entre hoy y la fecha. Se calcula en UTC para que un
// cambio de horario no altere la cuenta.
int diasHasta(DateTime fecha, DateTime ahora) {
  final destino = DateTime.utc(fecha.year, fecha.month, fecha.day);
  final hoy = DateTime.utc(ahora.year, ahora.month, ahora.day);
  return destino.difference(hoy).inDays;
}

// Texto corto que responde «¿todavía llego?»: Finalizada, En curso, Hoy,
// Mañana o Faltan N días.
String etiquetaTemporal(Competencia competencia, DateTime ahora) {
  final estado = estadoTemporal(competencia, ahora);
  if (estado == EstadoTemporal.finalizada) {
    return 'Finalizada';
  }
  if (estado == EstadoTemporal.enCurso && competencia.fechaFin != null) {
    return 'En curso';
  }
  final dias = diasHasta(competencia.fechaInicio, ahora);
  if (dias <= 0) {
    return 'Hoy';
  }
  if (dias == 1) {
    return 'Mañana';
  }
  return 'Faltan $dias días';
}

// Orden del Feed: primero lo que todavía se puede aprovechar, de lo más
// cercano a lo más lejano; al final las finalizadas, de la más reciente a la
// más antigua. Con fechas iguales se conserva el orden original.
List<Competencia> ordenarPorCercania(
  Iterable<Competencia> competencias,
  DateTime ahora,
) {
  final entradas =
      <({int posicion, Competencia competencia, bool finalizada})>[];
  var posicion = 0;
  for (final competencia in competencias) {
    entradas.add((
      posicion: posicion,
      competencia: competencia,
      finalizada: estaFinalizada(competencia, ahora),
    ));
    posicion++;
  }
  entradas.sort((a, b) {
    if (a.finalizada != b.finalizada) {
      return a.finalizada ? 1 : -1;
    }
    final porFecha = a.competencia.fechaInicio.compareTo(
      b.competencia.fechaInicio,
    );
    if (porFecha != 0) {
      return a.finalizada ? -porFecha : porFecha;
    }
    return a.posicion.compareTo(b.posicion);
  });
  return [for (final entrada in entradas) entrada.competencia];
}
