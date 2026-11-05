import 'package:flutter/material.dart';

// Pide confirmación antes de borrar una competencia.
// Devuelve true solo si la persona toca «Eliminar». Cancelar, tocar fuera
// del diálogo o usar el botón Atrás devuelven false y no borran nada.
// Quien llama decide qué hacer con el resultado (el borrado real lo conecta
// el Detalle).
Future<bool> showCompetitionDeleteDialog(
  BuildContext context,
  String titulo,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => CompetitionDeleteDialog(titulo: titulo),
  );
  return confirmed ?? false;
}

class CompetitionDeleteDialog extends StatelessWidget {
  const CompetitionDeleteDialog({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: scheme.error),
      title: const Text('¿Eliminar competencia?'),
      content: Text(
        'Se eliminará «$titulo». Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('competition-delete-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('competition-delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
