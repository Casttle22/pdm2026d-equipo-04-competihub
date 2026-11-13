import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tema_provider.dart';
import '../tema.dart';

// Botón del encabezado del Inicio para elegir el modo de color: Sistema,
// Claro u Oscuro. El ícono muestra el modo actual y el lector de pantalla
// anuncia «Tema: …».
class SelectorTema extends ConsumerWidget {
  const SelectorTema({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(modoTemaProvider);
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<ThemeMode>(
      key: const ValueKey('selector-tema'),
      tooltip: 'Tema: ${modo.etiqueta}',
      initialValue: modo,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioCampo),
      ),
      onSelected: ref.read(modoTemaProvider.notifier).cambiar,
      itemBuilder: (context) => [
        for (final opcion in ThemeMode.values)
          PopupMenuItem(
            key: ValueKey('tema-${opcion.name}'),
            value: opcion,
            child: Row(
              children: [
                Icon(
                  opcion == modo ? Icons.check : opcion.icono,
                  size: 20,
                  color: opcion == modo ? scheme.primary : null,
                ),
                const SizedBox(width: 12),
                Text(opcion.etiqueta),
              ],
            ),
          ),
      ],
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorDeTarjeta(context),
          shape: BoxShape.circle,
          boxShadow: sombraDeTarjeta(context),
        ),
        child: Icon(modo.icono, color: scheme.primary),
      ),
    );
  }
}
