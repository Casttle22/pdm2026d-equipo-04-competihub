import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

// Teselas para las pruebas del mapa, sin internet: imágenes transparentes en
// memoria o, con `fallar`, imágenes que no cargan (como sin conexión).
class TeselasDePrueba extends TileProvider {
  TeselasDePrueba({this.fallar = false});

  bool fallar;
  int pedidas = 0;

  static final Uint8List _pngTransparente = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    pedidas++;
    return fallar ? const _ImagenQueFalla() : MemoryImage(_pngTransparente);
  }
}

class _ImagenQueFalla extends ImageProvider<_ImagenQueFalla> {
  const _ImagenQueFalla();

  @override
  Future<_ImagenQueFalla> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ImagenQueFalla key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('sin conexión simulada')),
    );
  }
}
