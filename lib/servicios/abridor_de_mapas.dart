import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// Abre la app de mapas del teléfono en una ubicación. Es una clase aparte
// (y un provider) para que las pruebas la reemplacen sin abrir nada.
class AbridorDeMapas {
  const AbridorDeMapas({Future<bool> Function(Uri uri)? lanzar})
    : _lanzar = lanzar ?? _lanzarExterno;

  final Future<bool> Function(Uri uri) _lanzar;

  static Future<bool> _lanzarExterno(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  // Intenta primero con geo: (lo atiende cualquier app de mapas de Android)
  // y, si no hay ninguna, con el enlace web de Google Maps, que abre el
  // navegador. Devuelve false si no se pudo abrir nada.
  Future<bool> abrir(
    String direccion, {
    double? latitud,
    double? longitud,
  }) async {
    for (final uri in enlacesDeMapa(
      direccion,
      latitud: latitud,
      longitud: longitud,
    )) {
      if (await _lanzar(uri)) {
        return true;
      }
    }
    return false;
  }
}

// Enlaces para abrir una ubicación, en orden de preferencia. Con
// coordenadas, el punto exacto; sin ellas, una búsqueda por la dirección.
List<Uri> enlacesDeMapa(String direccion, {double? latitud, double? longitud}) {
  final consulta = latitud != null && longitud != null
      ? '$latitud,$longitud($direccion)'
      : direccion;
  final punto = latitud != null && longitud != null
      ? '$latitud,$longitud'
      : '0,0';
  return [
    Uri.parse('geo:$punto?q=${Uri.encodeComponent(consulta)}'),
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': latitud != null && longitud != null
          ? '$latitud,$longitud'
          : direccion,
    }),
  ];
}

final abridorDeMapasProvider = Provider<AbridorDeMapas>(
  (ref) => const AbridorDeMapas(),
);

// Solo tiene sentido ir a un lugar físico.
bool admiteComoLlegar(String modalidad) =>
    modalidad == 'Presencial' || modalidad == 'Híbrida';
