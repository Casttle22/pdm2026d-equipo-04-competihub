import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../providers/competencias_providers.dart';
import '../providers/reloj_provider.dart';
import '../tema.dart';
import '../utils/busqueda.dart';
import '../utils/fechas.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/tarjeta_competencia.dart';
import 'competition_detail_screen.dart';
import 'competition_form_screen.dart';

// Cuántas competencias próximas se muestran en Destacados.
const int cantidadDestacados = 3;

// Inicio: encabezado con la marca y la píldora de ubicación, buscador,
// filtros por categoría, «Eventos destacados» (carrusel) y «Próximos
// eventos». Los datos llegan de competenciasProvider (asíncrono); la
// búsqueda, la categoría y la ubicación son estado local de la pantalla,
// para que se conserven al volver del Detalle.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onVerTodos});

  // «Ver todos >»: lleva a la pestaña Explorar. Sin él, el enlace no se
  // muestra.
  final VoidCallback? onVerTodos;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _busquedaController = TextEditingController();
  String? categoriaSeleccionada;
  FiltroUbicacion _ubicacion = FiltroUbicacion.todas;
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
              coincideConUbicacion(competencia, _ubicacion) &&
              coincideConBusqueda(competencia, consulta),
        )
        .toList();
    // Destacados solo aparece al explorar. Con una búsqueda o un filtro, la
    // persona ya pidió algo concreto y se le muestra la lista completa.
    final explorando =
        categoriaSeleccionada == null &&
        _ubicacion == FiltroUbicacion.todas &&
        consulta.isEmpty;
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TituloDeSeccion(
              texto: finalizada ? 'Finalizadas' : 'Próximos eventos',
              onVerTodos: finalizada ? null : widget.onVerTodos,
            ),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marca a la izquierda y ubicación a la derecha. En un Wrap: con
          // texto grande, la píldora baja a otra línea en vez de desbordarse.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Semantics(
                header: true,
                // Con texto muy grande, la marca se reduce para caber en una
                // línea en vez de desbordarse.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - 32,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: scheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CompetiHub',
                          style: textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PildoraUbicacion(
                    valor: _ubicacion,
                    onCambio: (valor) => setState(() => _ubicacion = valor),
                  ),
                  const SizedBox(width: 8),
                  // En el encabezado y no como botón flotante: así no tapa
                  // el botón «Detalles» de las filas.
                  IconButton.filled(
                    tooltip: 'Nueva competencia',
                    onPressed: _crearCompetencia,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: sombraSuave,
            ),
            child: TextField(
              key: const ValueKey('inicio-busqueda'),
              controller: _busquedaController,
              textInputAction: TextInputAction.search,
              onChanged: (valor) => setState(() => _consulta = valor),
              decoration: InputDecoration(
                hintText: 'Buscar torneos, hackathons, organizadores…',
                prefixIcon: Icon(Icons.search, color: scheme.primary),
                suffixIcon: _consulta.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar búsqueda',
                        icon: const Icon(Icons.clear),
                        onPressed: _borrarBusqueda,
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtros en una sola fila que se desliza de lado.
          SingleChildScrollView(
            key: const ValueKey('inicio-filtros'),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _PildoraFiltro(
                  icono: Icons.apps_outlined,
                  etiqueta: 'Todas',
                  seleccionada: categoriaSeleccionada == null,
                  onSeleccionar: () =>
                      setState(() => categoriaSeleccionada = null),
                ),
                for (final categoria in categorias)
                  _PildoraFiltro(
                    icono: estiloDeCategoria(categoria, scheme).icono,
                    etiqueta: categoria,
                    seleccionada: categoriaSeleccionada == categoria,
                    onSeleccionar: () =>
                        setState(() => categoriaSeleccionada = categoria),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Cuántas hay y cuántas ya pasaron.
          Text(
            competitions.length == 1
                ? '1 competencia disponible'
                : '${competitions.length} competencias disponibles',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
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
          if (hayEjemplos) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(radioCampo),
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
            _TituloDeSeccion(
              texto: 'Eventos destacados',
              onVerTodos: widget.onVerTodos,
            ),
            CarruselDestacados(
              competencias: destacadas,
              ahora: ahora,
              onAbrir: _abrirDetalle,
            ),
          ],
          if (competitions.isEmpty) ...[
            const SizedBox(height: 24),
            _estadoVacio(context, consulta),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Motivos para no tener resultados, cada uno con su salida:
  // - la búsqueda no encontró nada: borrarla;
  // - un filtro dejó la lista vacía: volver a Todas;
  // - no hay datos: volver a consultar.
  Widget _estadoVacio(BuildContext context, String consulta) {
    final scheme = Theme.of(context).colorScheme;
    final porBusqueda = consulta.isNotEmpty;
    final conFiltro =
        categoriaSeleccionada != null || _ubicacion != FiltroUbicacion.todas;
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
                ? (conFiltro
                      ? 'Prueba con otras palabras o quita los filtros.'
                      : 'Revisa la ortografía o prueba con otras palabras.')
                : conFiltro
                ? 'Prueba otra categoría o selecciona Todas.'
                : 'Todavía no hay competencias disponibles.',
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
          else if (!conFiltro)
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
                  _ubicacion = FiltroUbicacion.todas;
                });
              },
              child: const Text('Ver todas'),
            ),
        ],
      ),
    );
  }
}

// Píldora «Quetzaltenango / Online» del encabezado. Abre un menú con las
// tres opciones; las híbridas aparecen en las dos.
class _PildoraUbicacion extends StatelessWidget {
  const _PildoraUbicacion({required this.valor, required this.onCambio});

  final FiltroUbicacion valor;
  final ValueChanged<FiltroUbicacion> onCambio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<FiltroUbicacion>(
      key: const ValueKey('inicio-ubicacion'),
      tooltip: 'Ubicación: ${valor.descripcion}',
      initialValue: valor,
      onSelected: onCambio,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioCampo),
      ),
      itemBuilder: (context) => [
        for (final opcion in FiltroUbicacion.values)
          PopupMenuItem(
            value: opcion,
            child: Row(
              children: [
                Icon(
                  opcion == valor ? Icons.check : _iconoDe(opcion),
                  size: 20,
                  color: opcion == valor ? scheme.primary : null,
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(opcion.descripcion)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: sombraSuave,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconoDe(valor), size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              valor.etiqueta,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static IconData _iconoDe(FiltroUbicacion filtro) => switch (filtro) {
    FiltroUbicacion.todas => Icons.public,
    FiltroUbicacion.quetzaltenango => Icons.place_outlined,
    FiltroUbicacion.online => Icons.wifi,
  };
}

// Píldora de filtro de categoría: blanca con borde, o azul rellena con texto
// blanco si está seleccionada.
class _PildoraFiltro extends StatelessWidget {
  const _PildoraFiltro({
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

class _TituloDeSeccion extends StatelessWidget {
  const _TituloDeSeccion({required this.texto, this.onVerTodos});

  final String texto;
  final VoidCallback? onVerTodos;

  @override
  Widget build(BuildContext context) {
    final onVerTodos = this.onVerTodos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 0, 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (onVerTodos != null)
            TextButton(
              onPressed: onVerTodos,
              child: Semantics(
                label: 'Ver todos: $texto',
                excludeSemantics: true,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Ver todos'), Icon(Icons.chevron_right)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Carrusel de «Eventos destacados»: tarjetas grandes que se deslizan de lado
// con puntos indicadores de página debajo. Las competencias se exponen para
// que las pruebas puedan verificar cuáles son, aunque el carrusel solo
// construya las páginas visibles.
class CarruselDestacados extends StatefulWidget {
  const CarruselDestacados({
    super.key,
    required this.competencias,
    required this.ahora,
    required this.onAbrir,
  });

  final List<Competencia> competencias;
  final DateTime ahora;
  final void Function(Competencia) onAbrir;

  @override
  State<CarruselDestacados> createState() => _CarruselDestacadosState();
}

class _CarruselDestacadosState extends State<CarruselDestacados> {
  // La tarjeta deja ver el borde de la siguiente para indicar que se
  // desliza.
  final _controller = PageController(viewportFraction: 0.92);
  int _pagina = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Unos 240 dp con texto normal; crece con el texto del sistema para que
    // el título y los datos sigan cabiendo.
    final alto = MediaQuery.textScalerOf(context).scale(240).clamp(220, 480);
    final total = widget.competencias.length;
    return Column(
      children: [
        SizedBox(
          height: alto.toDouble(),
          child: PageView.builder(
            key: const ValueKey('inicio-destacados'),
            controller: _controller,
            padEnds: false,
            itemCount: total,
            onPageChanged: (pagina) => setState(() => _pagina = pagina),
            itemBuilder: (context, indice) {
              final competencia = widget.competencias[indice];
              return Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 6),
                child: TarjetaDestacada(
                  key: ValueKey(competencia.id),
                  competition: competencia,
                  ahora: widget.ahora,
                  posicion: '${indice + 1} de $total',
                  onTap: () => widget.onAbrir(competencia),
                ),
              );
            },
          ),
        ),
        if (total > 1) ...[
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Row(
              key: const ValueKey('inicio-destacados-puntos'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < total; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _pagina ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _pagina
                          ? scheme.primary
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
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
