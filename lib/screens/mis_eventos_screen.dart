import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../providers/competencias_providers.dart';
import '../providers/reloj_provider.dart';
import '../utils/fechas.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/tarjeta_competencia.dart';
import 'competition_detail_screen.dart';

// Pestaña «Mis eventos»: las competencias guardadas, próximas primero y las
// finalizadas al final. Combina la lista de competencias con los ids
// guardados; si una competencia guardada se borra, la base también borra el
// guardado y deja de aparecer.
class MisEventosScreen extends ConsumerWidget {
  const MisEventosScreen({super.key, this.onExplorar});

  // Lleva a la pestaña Inicio desde el estado vacío.
  final VoidCallback? onExplorar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competenciasAsync = ref.watch(competenciasProvider);
    final guardadosAsync = ref.watch(guardadosProvider);
    final ahora = ref.watch(relojProvider)();

    Widget cuerpo;
    if (competenciasAsync.hasError || guardadosAsync.hasError) {
      cuerpo = EstadoVacio(
        icono: Icons.error_outline,
        titulo: 'No pudimos cargar tus eventos.',
        mensaje: 'Intenta de nuevo en un momento.',
        accion: FilledButton.icon(
          onPressed: () {
            ref.invalidate(competenciasProvider);
            ref.invalidate(guardadosProvider);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    } else if (!competenciasAsync.hasValue || !guardadosAsync.hasValue) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else {
      final ids = guardadosAsync.requireValue;
      final guardadas = ordenarPorCercania(
        competenciasAsync.requireValue.where((c) => ids.contains(c.id)),
        ahora,
      );
      cuerpo = guardadas.isEmpty
          ? EstadoVacio(
              key: const ValueKey('mis-eventos-vacio'),
              icono: Icons.bookmark_border,
              titulo: 'Todavía no guardas competencias',
              mensaje:
                  'Toca el ícono de marcador en una competencia del Inicio, '
                  'o «Guardar» en su detalle, y aparecerá aquí para tenerla '
                  'a mano.',
              accion: onExplorar == null
                  ? null
                  : FilledButton.icon(
                      onPressed: onExplorar,
                      icon: const Icon(Icons.search),
                      label: const Text('Explorar competencias'),
                    ),
            )
          : _ListaGuardadas(competencias: guardadas, ahora: ahora);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis eventos'), centerTitle: true),
      body: SafeArea(child: cuerpo),
    );
  }
}

class _ListaGuardadas extends StatelessWidget {
  const _ListaGuardadas({required this.competencias, required this.ahora});

  final List<Competencia> competencias;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      key: const ValueKey('mis-eventos-lista'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: competencias.length,
      itemBuilder: (context, index) {
        final competencia = competencias[index];
        final finalizada = estaFinalizada(competencia, ahora);
        final iniciaTramo =
            index == 0 ||
            estaFinalizada(competencias[index - 1], ahora) != finalizada;
        final tarjeta = CompetitionCard(
          key: ValueKey('guardada-${competencia.id}'),
          competition: competencia,
          ahora: ahora,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  CompetitionDetailScreen(competitionId: competencia.id),
            ),
          ),
        );
        if (!iniciaTramo) {
          return tarjeta;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Semantics(
                header: true,
                child: Text(
                  finalizada ? 'Finalizadas' : 'Próximas',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            tarjeta,
          ],
        );
      },
    );
  }
}
