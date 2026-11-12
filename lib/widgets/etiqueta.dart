import 'package:flutter/material.dart';

// Etiqueta compacta (píldora) para categoría, modalidad y estado. No es
// interactiva: por eso no usa Chip, que reserva un área táctil de 48 dp.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    required this.colorTexto,
    required this.colorFondo,
    this.icono,
  });

  final String texto;
  final Color colorTexto;
  final Color colorFondo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final icono = this.icono;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 16, color: colorTexto),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorTexto,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
