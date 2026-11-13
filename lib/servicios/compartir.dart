import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/competencia.dart';
import '../utils/fechas.dart';

// Texto que se comparte de una competencia: lo necesario para decidir si ir
// y cómo participar, sin depender de la app. En los datos de ejemplo, lo
// primero que se lee es que la competencia es ficticia, para que no circule
// como si fuera real.
String textoParaCompartir(Competencia competencia) {
  final lineas = <String>[
    if (competencia.esDeEjemplo)
      'Competencia FICTICIA de ejemplo (no es un evento real).',
    competencia.titulo,
    '',
    'Fecha: ${formatearFechaHoraLegible(competencia.fechaInicio)}',
    'Lugar: ${competencia.ubicacion} (${competencia.modalidad})',
    'Costo: ${competencia.costo}',
    '',
    'Cómo participar: ${competencia.instruccionesParticipacion}',
  ];
  final enlace = competencia.inscripcionUrl?.trim();
  if (enlace != null && enlace.isNotEmpty) {
    lineas.add('Enlace: $enlace');
  }
  lineas
    ..add('')
    ..add('Compartido desde CompetiHub.');
  return lineas.join('\n');
}

// Abre la hoja de compartir del sistema. Va detrás de un provider para que
// las pruebas puedan ver qué se compartió sin abrir nada.
class Compartidor {
  const Compartidor();

  Future<void> compartir(String texto, {String? asunto}) async {
    await SharePlus.instance.share(ShareParams(text: texto, subject: asunto));
  }
}

final compartidorProvider = Provider<Compartidor>((ref) => const Compartidor());
