// Un elemento de la sección «Fotos y videos» del Detalle.
//
// Por ahora solo lo tienen las competencias de ejemplo: no se guarda en
// SQLite ni se edita en el formulario (pendiente para una versión siguiente).
enum TipoMedia { imagen, video }

class MediaCompetencia {
  const MediaCompetencia({
    required this.tipo,
    required this.fuente,
    required this.titulo,
    this.miniatura,
  });

  final TipoMedia tipo;

  // Imagen: un asset («assets/imagenes/…») o una URL http(s).
  // Video: la URL que se abre en otra app.
  final String fuente;

  final String titulo;

  // Imagen que se muestra en la miniatura de un video (asset o URL). Si no
  // hay, se usa el fondo de la categoría.
  final String? miniatura;

  bool get esVideo => tipo == TipoMedia.video;

  // Imagen que se muestra en la fila de miniaturas.
  String? get imagenDeMiniatura => esVideo ? miniatura : fuente;
}
