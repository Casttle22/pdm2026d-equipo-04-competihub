import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// Abre un enlace en otra app (el navegador o la app de videos). Va detrás de
// un provider para que las pruebas puedan ver qué se abrió sin abrir nada.
class AbridorDeEnlaces {
  const AbridorDeEnlaces({Future<bool> Function(Uri uri)? lanzar})
    : _lanzar = lanzar ?? _lanzarExterno;

  final Future<bool> Function(Uri uri) _lanzar;

  static Future<bool> _lanzarExterno(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  // false si el texto no es un enlace http(s) o si no se pudo abrir.
  Future<bool> abrir(String enlace) async {
    final uri = Uri.tryParse(enlace.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }
    return _lanzar(uri);
  }
}

final abridorDeEnlacesProvider = Provider<AbridorDeEnlaces>(
  (ref) => const AbridorDeEnlaces(),
);
