// Créditos de las imágenes incluidas en la app (assets/imagenes/). Todas
// vienen de Wikimedia Commons con licencia libre; la fuente completa está en
// docs/creditos_imagenes.md. CC BY pide atribución visible: la app muestra
// este crédito debajo de la imagen en el Detalle y en la vista ampliada.
const Map<String, String> creditosDeImagenes = {
  'assets/imagenes/portada_esports.jpg':
      'Foto: Mzacha · Dominio público · Wikimedia Commons',
  'assets/imagenes/portada_programacion.jpg':
      'Foto: Sai Kiran Anagani · CC0 · Wikimedia Commons',
  'assets/imagenes/portada_carrera.jpg':
      'Foto: Petewarrior · CC BY 4.0 · Wikimedia Commons',
  'assets/imagenes/portada_logica.jpg':
      'Foto: Wilfredor · CC0 · Wikimedia Commons',
  'assets/imagenes/portada_ilustracion.jpg':
      'Foto: Artsy Crafty · CC0 · Wikimedia Commons',
  'assets/imagenes/portada_estrategia.jpg':
      'Foto: Mshuang2 · CC0 · Wikimedia Commons',
  'assets/imagenes/galeria_ajedrez_perfil.jpg':
      'Foto: Wilfredor · CC0 · Wikimedia Commons',
  'assets/imagenes/galeria_ajedrez_dorado.jpg':
      "Foto: The People's Internet · CC0 · Wikimedia Commons",
  'assets/imagenes/galeria_pista.jpg':
      'Foto: Petewarrior · CC BY 4.0 · Wikimedia Commons',
};

// Crédito de una imagen incluida, o null si es una URL externa o no se
// conoce.
String? creditoDeImagen(String? fuente) =>
    fuente == null ? null : creditosDeImagenes[fuente.trim()];

// true si la fuente es una imagen incluida en la app (no una URL).
bool esAssetLocal(String fuente) => fuente.trim().startsWith('assets/');
