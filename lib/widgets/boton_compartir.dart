import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../servicios/compartir.dart';

// «Compartir»: abre la hoja de compartir del sistema con el resumen de la
// competencia (ver textoParaCompartir).
class BotonCompartir extends ConsumerWidget {
  const BotonCompartir({super.key, required this.competencia});

  final Competencia competencia;

  Future<void> _compartir(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(compartidorProvider)
          .compartir(
            textoParaCompartir(competencia),
            asunto: competencia.titulo,
          );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No se pudo compartir.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      key: const ValueKey('detalle-compartir'),
      onPressed: () => _compartir(context, ref),
      icon: const Icon(Icons.share_outlined),
      label: const Text('Compartir'),
    );
  }
}
