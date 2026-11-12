import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../providers/competencias_providers.dart';
import '../providers/reloj_provider.dart';
import '../utils/busqueda.dart';
import '../utils/fechas.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/tarjeta_competencia.dart';
import 'competition_detail_screen.dart';
import 'competition_form_screen.dart';

// Cuántas competencias próximas se muestran en Destacados.
const int cantidadDestacados = 3;

// Inicio: búsqueda, filtros por categoría, Destacados y la lista de
// competencias. Los datos llegan de competenciasProvider (asíncrono); la
// búsqueda y la categoría son estado local de la pantalla, para que se
// conserven al volver del Detalle.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _busquedaController = TextEditingController();
  String? categoriaSeleccionada;
  String _consulta = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // Invalidar el provider descarta el resultado anterior y vuelve a llamar
  // al repositorio. Lo usan Reintentar y Volver a cargar.
  void _volverACargar() {
    ref.invalidate(competenciasProvider);
  }

  void _borrarBusqueda() {
    _busquedaController.clear();
    setState(() => _consulta = '');
  }

  // Abre el formulario de creación y confirma con un mensaje si se guardó.
  Future<void> _crearCompetencia() async {
    final actions = ref.read(competenciasActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    var guardada = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CompetitionFormScreen(
          onSave: (draft) async {
            await actions.crear(draft);
            guardada = true;
          },
        ),
      ),
    );
    if (guardada) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Competencia creada.')),
      );
    }
  }

  void _abrirDetalle(Competencia competition) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // El Detalle consulta por id con competenciaPorIdProvider.
        builder: (_) => CompetitionDetailScreen(competitionId: competition.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competenciasAsync = ref.watch(competenciasProvider);
    // Se lee en cada construcción: las etiquetas de tiempo dependen de hoy.
    final ahora = ref.watch(relojProvider)();
    return Scaffold(
      appBar: AppBar(
        title: const Text('CompetiHub'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            tooltip: 'Nueva competencia',
            icon: const Icon(Icons.add),
            onPressed: _crearCompetencia,
          ),
        ],
      ),
      body: SafeArea(
        // skipLoadingOnRefresh: false hace que, al reintentar, se vea otra vez
        // el indicador de carga en lugar del error anterior.
        child: competenciasAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => const _FeedCargando(),
          error: (error, stackTrace) =>
              _FeedError(onReintentar: _volverACargar),
          data: (competencias) => _buildFeed(context, competencias, ahora),
        ),
      ),
    );
  }

  Widget _buildFeed(
    BuildContext context,
    List<Competencia> todas,
    DateTime ahora,
  ) {
    final consulta = _consulta.trim();
    // La lista conserva el orden que entrega el repositorio (la base de
    // datos ya pone las próximas primero y las finalizadas al final).
    final competitions = todas
        .where(
          (competencia) =>
              (categoriaSeleccionada == null ||
                  competencia.categoria == categoriaSeleccionada) &&
              coincideConBusqueda(competencia, consulta),
        )
        .toList();
    // Destacados solo aparece al explorar. Con una búsqueda o un filtro, la
    // persona ya pidió algo concreto y se le muestra la lista completa.
    final explorando = categoriaSeleccionada == null && consulta.isEmpty;
    final destacadas = explorando
        ? ordenarPorCercania(competitions, ahora)
              .where((competencia) => !estaFinalizada(competencia, ahora))
              .take(cantidadDestacados)
              .toList()
        : const <Competencia>[];
    final resto = [
      for (final competencia in competitions)
        if (!destacadas.contains(competencia)) competencia,
    ];

    return ListView.builder(
      key: const ValueKey('inicio-lista'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: resto.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _encabezado(
            context,
            todas: todas,
            competitions: competitions,
            destacadas: destacadas,
            consulta: consulta,
            ahora: ahora,
          );
        }

        final competition = resto[index - 1];
        final card = CompetitionCard(
          key: ValueKey(competition.id),
          competition: competition,
          ahora: ahora,
          onTap: () => _abrirDetalle(competition),
        );
        // Rótulo antes de la primera competencia de cada tramo. Va dentro
        // del mismo elemento de la lista para no alterar la cantidad de
        // elementos.
        final finalizada = estaFinalizada(competition, ahora);
        final iniciaTramo =
            index == 1 || estaFinalizada(resto[index - 2], ahora) != finalizada;
        if (!iniciaTramo) {
          return card;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TituloDeSeccion(texto: finalizada ? 'Finalizadas' : 'Próximos'),
            card,
          ],
        );
      },
    );
  }

  Widget _encabezado(
    BuildContext context, {
    required List<Competencia> todas,
    required List<Competencia> competitions,
    required List<Competencia> destacadas,
    required String consulta,
    required DateTime ahora,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final finalizadas = competitions
        .where((competencia) => estaFinalizada(competencia, ahora))
        .length;
    final porVenir = competitions.length - finalizadas;
    // El aviso de datos ficticios solo aplica a las competencias de ejemplo.
    final hayEjemplos = todas.any((competencia) => competencia.esDeEjemplo);
    final soloEjemplos = todas.every((competencia) => competencia.esDeEjemplo);
    final categorias = todas
        .map((competencia) => competencia.categoria)
        .toSet();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explora competencias',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('inicio-busqueda'),
            controller: _busquedaController,
            textInputAction: TextInputAction.search,
            onChanged: (valor) => setState(() => _consulta = valor),
            decoration: InputDecoration(
              labelText: 'Buscar competencias',
              hintText: 'Título, lugar o descripción',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _consulta.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.clear),
                      onPressed: _borrarBusqueda,
                    ),
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Filtrar por categoría',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.apps_outlined, size: 18),
                label: const Text('Todas'),
                selected: categoriaSeleccionada == null,
                onSelected: (_) {
                  setState(() {
                    categoriaSeleccionada = null;
                  });
                },
              ),
              for (final categoria in categorias)
                ChoiceChip(
                  avatar: Icon(
                    estiloDeCategoria(categoria, scheme).icono,
                    size: 18,
                  ),
                  label: Text(categoria),
                  selected: categoriaSeleccionada == categoria,
                  onSelected: (_) {
                    setState(() {
                      categoriaSeleccionada = categoria;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competitions.length == 1
                          ? '1 competencia disponible'
                          : '${competitions.length} competencias disponibles',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Aclara cuántas de las listadas ya pasaron.
                    if (finalizadas > 0)
                      Text(
                        porVenir == 0
                            ? 'Todas ya finalizaron'
                            : '$porVenir por venir · $finalizadas ya '
                                  '${finalizadas == 1 ? 'finalizó' : 'finalizaron'}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (hayEjemplos) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      soloEjemplos
                          ? 'Competencias ficticias para desarrollo y pruebas. No son eventos reales.'
                          : 'Las competencias de ejemplo son ficticias. No son eventos reales.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (destacadas.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _TituloDeSeccion(texto: 'Destacados'),
            _Destacados(
              competencias: destacadas,
              ahora: ahora,
              onAbrir: _abrirDetalle,
            ),
          ],
          if (competitions.isEmpty) ...[
            const SizedBox(height: 24),
            _estadoVacio(context, consulta),
          ],
        ],
      ),
    );
  }

  // Tres motivos para no tener resultados, cada uno con su salida:
  // - la búsqueda no encontró nada: borrarla;
  // - el filtro dejó la lista vacía: volver a Todas;
  // - no hay datos: volver a consultar.
  Widget _estadoVacio(BuildContext context, String consulta) {
    final scheme = Theme.of(context).colorScheme;
    final porBusqueda = consulta.isNotEmpty;
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            porBusqueda
                ? 'Sin resultados para «$consulta»'
                : 'No se encontraron competencias',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            porBusqueda
                ? (categoriaSeleccionada == null
                      ? 'Revisa la ortografía o prueba con otras palabras.'
                      : 'Prueba con otras palabras o quita el filtro de '
                            '$categoriaSeleccionada.')
                : categoriaSeleccionada == null
                ? 'Todavía no hay competencias disponibles.'
                : 'Prueba otra categoría o selecciona Todas.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (porBusqueda)
            FilledButton.icon(
              key: const ValueKey('inicio-borrar-busqueda'),
              onPressed: _borrarBusqueda,
              icon: const Icon(Icons.clear),
              label: const Text('Borrar búsqueda'),
            )
          else if (categoriaSeleccionada == null)
            FilledButton.icon(
              onPressed: _volverACargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a cargar'),
            )
          else
            OutlinedButton(
              onPressed: () {
                setState(() {
                  categoriaSeleccionada = null;
                });
              },
              child: const Text('Ver todas'),
            ),
        ],
      ),
    );
  }
}

class _TituloDeSeccion extends StatelessWidget {
  const _TituloDeSeccion({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Fila horizontal con las competencias próximas más cercanas. Son pocas
// (hasta tres), así que se construyen todas: no hace falta una lista
// perezosa y las tarjetas pueden tener la misma altura.
class _Destacados extends StatelessWidget {
  const _Destacados({
    required this.competencias,
    required this.ahora,
    required this.onAbrir,
  });

  final List<Competencia> competencias;
  final DateTime ahora;
  final void Function(Competencia) onAbrir;

  @override
  Widget build(BuildContext context) {
    // La tarjeta deja ver el borde de la siguiente para indicar que la fila
    // se desliza.
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    final ancho = math.max(220.0, math.min(300.0, anchoPantalla - 72));
    return SingleChildScrollView(
      key: const ValueKey('inicio-destacados'),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (indice, competencia) in competencias.indexed)
              Padding(
                padding: EdgeInsets.only(
                  right: indice == competencias.length - 1 ? 0 : 12,
                ),
                child: SizedBox(
                  width: ancho,
                  child: TarjetaDestacada(
                    key: ValueKey(competencia.id),
                    competition: competencia,
                    ahora: ahora,
                    onTap: () => onAbrir(competencia),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedCargando extends StatelessWidget {
  const _FeedCargando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando competencias...'),
        ],
      ),
    );
  }
}

// Mensaje para personas, sin detalles técnicos de la excepción.
class _FeedError extends StatelessWidget {
  const _FeedError({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar las competencias.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta de nuevo en un momento.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
