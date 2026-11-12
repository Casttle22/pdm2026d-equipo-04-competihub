import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../servicios/abridor_de_mapas.dart';

// «Cómo llegar»: abre la app de mapas con la ubicación de la competencia.
// Si no se puede abrir, lo dice y ofrece copiar la dirección. En los datos
// de ejemplo, avisa antes que la ubicación es ficticia.
class BotonComoLlegar extends ConsumerWidget {
  const BotonComoLlegar({super.key, required this.competencia});

  final Competencia competencia;

  Future<void> _abrir(BuildContext context, WidgetRef ref) async {
    final abridor = ref.read(abridorDeMapasProvider);
    final messenger = ScaffoldMessenger.of(context);
    final direccion = competencia.ubicacion.trim();

    if (competencia.esDeEjemplo) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          icon: const Icon(Icons.info_outline),
          title: const Text('Ubicación ficticia'),
          content: const Text(
            'Esta competencia es de ejemplo: su ubicación no existe y el '
            'mapa no mostrará un lugar real.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('como-llegar-abrir-igual'),
              onPressed: () => Navigator.of(contexto).pop(true),
              child: const Text('Abrir de todos modos'),
            ),
          ],
        ),
      );
      if (seguir != true) {
        return;
      }
    }

    final abierto = await abridor.abrir(
      direccion,
      latitud: competencia.latitud,
      longitud: competencia.longitud,
    );
    if (abierto) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('No se pudo abrir una app de mapas.'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Copiar dirección',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: direccion));
              messenger.showSnackBar(
                const SnackBar(content: Text('Dirección copiada.')),
              );
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      key: const ValueKey('detalle-como-llegar'),
      onPressed: () => _abrir(context, ref),
      icon: const Icon(Icons.directions_outlined),
      label: const Text('Cómo llegar'),
    );
  }
}
