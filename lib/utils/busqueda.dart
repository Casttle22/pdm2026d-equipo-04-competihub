import '../data/competencia.dart';
import 'fechas.dart';

// Búsqueda del Inicio: funciones puras para poder probarlas sin interfaz.

const Map<String, String> _sinTilde = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
};

// Minúsculas y sin tildes, para comparar «Olimpiada» con «olimpíada» o
// «LOGICA» con «lógica».
String normalizarTexto(String texto) {
  final salida = StringBuffer();
  for (final caracter in texto.toLowerCase().split('')) {
    salida.write(_sinTilde[caracter] ?? caracter);
  }
  return salida.toString();
}

// Una competencia coincide si cada palabra de la consulta aparece en su
// título, su ubicación, su descripción o su organizador. Una consulta vacía
// coincide con todas.
bool coincideConBusqueda(Competencia competencia, String consulta) {
  final palabras = normalizarTexto(
    consulta,
  ).split(RegExp(r'\s+')).where((palabra) => palabra.isNotEmpty);
  if (palabras.isEmpty) {
    return true;
  }
  final contenido = normalizarTexto(
    '${competencia.titulo}\n${competencia.ubicacion}\n'
    '${competencia.descripcion}\n${competencia.organizador ?? ''}',
  );
  return palabras.every(contenido.contains);
}

// Píldora de ubicación del Inicio. Las híbridas aparecen en las dos
// opciones, porque se puede asistir en persona o en línea.
enum FiltroUbicacion {
  todas('Todas', 'Todas las ubicaciones'),
  quetzaltenango('Quetzaltenango', 'Quetzaltenango (presencial e híbrida)'),
  online('Online', 'Online (virtual e híbrida)');

  const FiltroUbicacion(this.etiqueta, this.descripcion);

  final String etiqueta;
  final String descripcion;
}

bool coincideConUbicacion(Competencia competencia, FiltroUbicacion filtro) {
  return switch (filtro) {
    FiltroUbicacion.todas => true,
    FiltroUbicacion.quetzaltenango =>
      competencia.modalidad == 'Presencial' ||
          competencia.modalidad == 'Híbrida',
    FiltroUbicacion.online =>
      competencia.modalidad == 'Virtual' || competencia.modalidad == 'Híbrida',
  };
}

// Filtros de la pestaña Explorar. Cada uno vacío (null o false) significa
// «sin filtrar por eso».
class FiltrosExplorar {
  const FiltrosExplorar({
    this.consulta = '',
    this.categoria,
    this.modalidad,
    this.formato,
    this.soloInscripcionAbierta = false,
    this.incluirFinalizadas = false,
  });

  final String consulta;
  final String? categoria;
  final String? modalidad;
  final FormatoCompetencia? formato;

  // Solo las que tienen fecha límite y todavía aceptan inscripciones.
  final bool soloInscripcionAbierta;

  // Por defecto Explorar muestra solo lo que todavía se puede aprovechar.
  final bool incluirFinalizadas;

  // true si hay algún filtro distinto del estado inicial (la búsqueda no
  // cuenta: tiene su propio botón para borrarla).
  bool get hayFiltros =>
      categoria != null ||
      modalidad != null ||
      formato != null ||
      soloInscripcionAbierta ||
      incluirFinalizadas;

  FiltrosExplorar copiar({
    String? consulta,
    String? Function()? categoria,
    String? Function()? modalidad,
    FormatoCompetencia? Function()? formato,
    bool? soloInscripcionAbierta,
    bool? incluirFinalizadas,
  }) {
    return FiltrosExplorar(
      consulta: consulta ?? this.consulta,
      categoria: categoria == null ? this.categoria : categoria(),
      modalidad: modalidad == null ? this.modalidad : modalidad(),
      formato: formato == null ? this.formato : formato(),
      soloInscripcionAbierta:
          soloInscripcionAbierta ?? this.soloInscripcionAbierta,
      incluirFinalizadas: incluirFinalizadas ?? this.incluirFinalizadas,
    );
  }
}

// Las competencias que pasan todos los filtros, próximas primero (y las
// finalizadas al final, si se incluyen).
List<Competencia> aplicarFiltros(
  Iterable<Competencia> competencias,
  FiltrosExplorar filtros,
  DateTime ahora,
) {
  final resultado = competencias.where((competencia) {
    if (!filtros.incluirFinalizadas && estaFinalizada(competencia, ahora)) {
      return false;
    }
    if (filtros.categoria != null &&
        competencia.categoria != filtros.categoria) {
      return false;
    }
    if (filtros.modalidad != null &&
        competencia.modalidad != filtros.modalidad) {
      return false;
    }
    if (filtros.formato != null && competencia.formato != filtros.formato) {
      return false;
    }
    if (filtros.soloInscripcionAbierta) {
      final estado = estadoInscripcion(competencia, ahora);
      if (estado == null || estado == EstadoInscripcion.cerradas) {
        return false;
      }
    }
    return coincideConBusqueda(competencia, filtros.consulta);
  });
  return ordenarPorCercania(resultado, ahora);
}
