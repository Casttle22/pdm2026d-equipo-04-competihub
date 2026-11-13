import 'package:flutter/material.dart';

// Píldora de filtro (categoría, modalidad, formato…): blanca con borde, o
// azul rellena con texto blanco si está seleccionada.
class PildoraFiltro extends StatelessWidget {
  const PildoraFiltro({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  final IconData icono;
  final String etiqueta;
  final bool seleccionada;
  final VoidCallback onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colorContenido = seleccionada ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icono, size: 18, color: colorContenido),
        label: Text(etiqueta),
        selected: seleccionada,
        showCheckmark: false,
        onSelected: (_) => onSeleccionar(),
        selectedColor: scheme.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: colorContenido,
          fontWeight: FontWeight.w700,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: seleccionada ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
    );
  }
}
