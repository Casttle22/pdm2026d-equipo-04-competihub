import '../data/competencia.dart';

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
