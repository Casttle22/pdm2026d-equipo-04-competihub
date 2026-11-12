import 'package:flutter/material.dart';

// Mensaje centrado para pantallas sin contenido: ícono, título, explicación
// y, si se da, una acción. Se puede desplazar por si el texto es grande.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accion = this.accion;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            if (accion != null) ...[const SizedBox(height: 16), accion],
          ],
        ),
      ),
    );
  }
}
