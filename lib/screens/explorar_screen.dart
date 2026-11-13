import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../providers/competencias_providers.dart';
import '../providers/reloj_provider.dart';
import '../tema.dart';
import '../utils/busqueda.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/etiquetas_ficha.dart';
import '../widgets/pildora_filtro.dart';
import '../widgets/tarjeta_competencia.dart';
import 'competition_detail_screen.dart';

const List<String> _modalidades = ['Presencial', 'Virtual', 'Híbrida'];

// Explorar: búsqueda con todos los filtros (categoría, modalidad, formato,
// inscripción abierta e incluir finalizadas) y la lista completa de
// resultados. Los filtros son estado de la pestaña: se conservan al cambiar
// de sección.
class ExplorarScreen extends ConsumerStatefulWidget {
  const ExplorarScreen({super.key});

  @override
  ConsumerState<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends ConsumerState<ExplorarScreen> {
  final _busqueda = TextEditingController();
  FiltrosExplorar _filtros = const FiltrosExplorar();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _cambiar(FiltrosExplorar filtros) => setState(() => _filtros = filtros);

  void _quitarFiltros() {
    _busqueda.clear();
    _cambiar(const FiltrosExplorar());
  }

  void _abrirDetalle(Competencia competencia) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompetitionDetailScreen(competitionId: competencia.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competenciasAsync = ref.watch(competenciasProvider);
    final ahora = ref.watch(relojProvider)();
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: SafeArea(
        child: competenciasAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EstadoVacio(
            icono: Icons.error_outline,
            titulo: 'No pudimos cargar las competencias.',
            mensaje: 'Intenta de nuevo en un momento.',
            accion: FilledButton.icon(
              onPressed: () => ref.invalidate(competenciasProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (todas) => _lista(context, todas, ahora),
        ),
      ),
    );
  }

  Widget _lista(BuildContext context, List<Competencia> todas, DateTime ahora) {
    final resultados = aplicarFiltros(todas, _filtros, ahora);
    final categorias = todas.map((c) => c.categoria).toSet();
    return ListView.builder(
      key: const ValueKey('explorar-lista'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: resultados.length + 1,
      itemBuilder: (context, indice) {
        if (indice == 0) {
          return _filtrosYConteo(context, categorias, resultados.length);
        }
        final competencia = resultados[indice - 1];
        return CompetitionCard(
          key: ValueKey('explorar-${competencia.id}'),
          competition: competencia,
          ahora: ahora,
          onTap: () => _abrirDetalle(competencia),
        );
      },
    );
  }

  Widget _filtrosYConteo(
    BuildContext context,
    Set<String> categorias,
    int cantidad,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final f = _filtros;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: sombraDeTarjeta(context),
          ),
          child: TextField(
            key: const ValueKey('explorar-busqueda'),
            controller: _busqueda,
            textInputAction: TextInputAction.search,
            onChanged: (valor) => _cambiar(f.copiar(consulta: valor)),
            decoration: InputDecoration(
              hintText: 'Buscar torneos, hackathons, organizadores…',
              prefixIcon: Icon(Icons.search, color: scheme.primary),
              suffixIcon: f.consulta.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _busqueda.clear();
                        _cambiar(f.copiar(consulta: ''));
                      },
                    ),
              filled: true,
              fillColor: colorDeTarjeta(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        _Grupo(
          titulo: 'Categoría',
          children: [
            PildoraFiltro(
              icono: Icons.apps_outlined,
              etiqueta: 'Todas',
              seleccionada: f.categoria == null,
              onSeleccionar: () => _cambiar(f.copiar(categoria: () => null)),
            ),
            for (final categoria in categorias)
              PildoraFiltro(
                icono: estiloDeCategoria(categoria, scheme).icono,
                etiqueta: categoria,
                seleccionada: f.categoria == categoria,
                onSeleccionar: () =>
                    _cambiar(f.copiar(categoria: () => categoria)),
              ),
          ],
        ),
        _Grupo(
          titulo: 'Modalidad',
          children: [
            PildoraFiltro(
              icono: Icons.public,
              etiqueta: 'Todas',
              seleccionada: f.modalidad == null,
              onSeleccionar: () => _cambiar(f.copiar(modalidad: () => null)),
            ),
            for (final modalidad in _modalidades)
              PildoraFiltro(
                icono: coloresDeModalidad(modalidad).icono,
                etiqueta: modalidad,
                seleccionada: f.modalidad == modalidad,
                onSeleccionar: () =>
                    _cambiar(f.copiar(modalidad: () => modalidad)),
              ),
          ],
        ),
        _Grupo(
          titulo: 'Formato',
          children: [
            PildoraFiltro(
              icono: Icons.all_inclusive,
              etiqueta: 'Todos',
              seleccionada: f.formato == null,
              onSeleccionar: () => _cambiar(f.copiar(formato: () => null)),
            ),
            for (final formato in FormatoCompetencia.values)
              PildoraFiltro(
                icono: coloresDeFormato(formato).icono,
                etiqueta: formato == FormatoCompetencia.equipos
                    ? 'Equipos'
                    : 'Individual',
                seleccionada: f.formato == formato,
                onSeleccionar: () => _cambiar(f.copiar(formato: () => formato)),
              ),
          ],
        ),
        _Grupo(
          titulo: 'Más filtros',
          children: [
            PildoraFiltro(
              key: const ValueKey('explorar-inscripcion-abierta'),
              icono: Icons.how_to_reg_outlined,
              etiqueta: 'Inscripción abierta',
              seleccionada: f.soloInscripcionAbierta,
              onSeleccionar: () => _cambiar(
                f.copiar(soloInscripcionAbierta: !f.soloInscripcionAbierta),
              ),
            ),
            PildoraFiltro(
              key: const ValueKey('explorar-incluir-finalizadas'),
              icono: Icons.history,
              etiqueta: 'Incluir finalizadas',
              seleccionada: f.incluirFinalizadas,
              onSeleccionar: () =>
                  _cambiar(f.copiar(incluirFinalizadas: !f.incluirFinalizadas)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              cantidad == 1 ? '1 resultado' : '$cantidad resultados',
              key: const ValueKey('explorar-conteo'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (f.hayFiltros || f.consulta.isNotEmpty)
              TextButton.icon(
                key: const ValueKey('explorar-quitar-filtros'),
                onPressed: _quitarFiltros,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Quitar filtros'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (cantidad == 0)
          EstadoVacio(
            key: const ValueKey('explorar-vacio'),
            icono: Icons.search_off_outlined,
            titulo: 'Sin resultados',
            mensaje: f.incluirFinalizadas
                ? 'Ninguna competencia cumple con la búsqueda y los filtros.'
                : 'Ninguna competencia próxima cumple con la búsqueda y los '
                      'filtros. Prueba a quitar alguno o a incluir las '
                      'finalizadas.',
            accion: f.hayFiltros || f.consulta.isNotEmpty
                ? FilledButton.icon(
                    key: const ValueKey('explorar-vacio-quitar'),
                    onPressed: _quitarFiltros,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Quitar filtros'),
                  )
                : null,
          ),
      ],
    );
  }
}

// Grupo de filtros con su subtítulo y una fila de píldoras que se desliza
// de lado.
class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(children: children),
          ),
        ],
      ),
    );
  }
}
