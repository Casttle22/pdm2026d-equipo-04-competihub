import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../providers/competencias_providers.dart';

// Botón para guardar o quitar una competencia de «Mis eventos». Lo usan las
// tarjetas y el Detalle.
//
// Para el lector de pantalla: el nombre del botón dice qué hará y con qué
// competencia («Guardar «Copa…» en Mis eventos»), y el estado se anuncia
// como seleccionado o no.
class BotonGuardar extends ConsumerStatefulWidget {
  const BotonGuardar({
    super.key,
    required this.competencia,
    this.sobreImagen = false,
    this.conTexto = false,
  });

  final Competencia competencia;

  // Sobre una imagen o un fondo de color, el botón lleva un círculo claro
  // detrás para que el ícono se distinga.
  final bool sobreImagen;

  // En el Detalle: botón con texto («Guardar» o «Guardada») en lugar de solo
  // el ícono.
  final bool conTexto;

  @override
  ConsumerState<BotonGuardar> createState() => _BotonGuardarState();
}

class _BotonGuardarState extends ConsumerState<BotonGuardar> {
  bool _trabajando = false;

  Future<void> _alternar(bool guardada) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(competenciasActionsProvider);
    setState(() => _trabajando = true);
    try {
      final quedoGuardada = await actions.alternarGuardado(
        widget.competencia.id,
        guardada: guardada,
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              quedoGuardada
                  ? 'Guardada en Mis eventos.'
                  : 'Quitada de Mis eventos.',
            ),
          ),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar Mis eventos.')),
        );
    } finally {
      if (mounted) {
        setState(() => _trabajando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardadosAsync = ref.watch(guardadosProvider);
    final guardados = guardadosAsync.asData?.value;
    final guardada = guardados?.contains(widget.competencia.id) ?? false;
    final titulo = widget.competencia.titulo;
    final scheme = Theme.of(context).colorScheme;

    final descripcion = guardada
        ? 'Quitar «$titulo» de Mis eventos'
        : 'Guardar «$titulo» en Mis eventos';
    final alTocar = guardados == null || _trabajando
        ? null
        : () => _alternar(guardada);
    if (widget.conTexto) {
      return Semantics(
        button: true,
        selected: guardada,
        enabled: alTocar != null,
        label: descripcion,
        onTap: alTocar,
        excludeSemantics: true,
        child: FilledButton.tonalIcon(
          key: ValueKey('guardar-${widget.competencia.id}'),
          onPressed: alTocar,
          icon: Icon(guardada ? Icons.bookmark : Icons.bookmark_border),
          label: Text(guardada ? 'Guardada' : 'Guardar'),
        ),
      );
    }

    final boton = IconButton(
      key: ValueKey('guardar-${widget.competencia.id}'),
      isSelected: guardada,
      tooltip: descripcion,
      icon: const Icon(Icons.bookmark_border),
      selectedIcon: Icon(Icons.bookmark, color: scheme.primary),
      // Mientras no se sabe si está guardada, o se está guardando, el botón
      // espera para no mandar dos cambios seguidos.
      onPressed: alTocar,
    );
    if (!widget.sobreImagen) {
      return boton;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: boton,
    );
  }
}
