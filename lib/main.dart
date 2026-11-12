import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/competencia.dart';
import 'providers/competencias_providers.dart';
import 'providers/reloj_provider.dart';
import 'screens/competition_detail_screen.dart';
import 'screens/competition_form_screen.dart';
import 'tema.dart';
import 'utils/fechas.dart';
import 'widgets/categoria_estilo.dart';
import 'widgets/etiqueta.dart';

void main() {
  // ProviderScope guarda los providers de toda la app. Las pruebas montan su
  // propio ProviderScope con un repositorio falso (override).
  runApp(const ProviderScope(child: CompetihubApp()));
}

class CompetihubApp extends StatelessWidget {
  const CompetihubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompetiHub',
      theme: temaCompetihub(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Feed de competencias. Los datos llegan de competenciasProvider (asíncrono);
// la categoría seleccionada sigue siendo estado local de esta pantalla, como
// en M1, para que el filtro se conserve al volver del detalle.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? categoriaSeleccionada;

  // Invalidar el provider descarta el resultado anterior y vuelve a llamar
  // al repositorio. Lo usan Reintentar y Volver a cargar.
  void _volverACargar() {
    ref.invalidate(competenciasProvider);
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
    final competitions = categoriaSeleccionada == null
        ? todas
        : todas
              .where(
                (competencia) => competencia.categoria == categoriaSeleccionada,
              )
              .toList();
    final finalizadas = competitions
        .where((competencia) => estaFinalizada(competencia, ahora))
        .length;
    final porVenir = competitions.length - finalizadas;
    // El aviso de datos ficticios solo aplica a las competencias de ejemplo.
    final hayEjemplos = todas.any((competencia) => competencia.esDeEjemplo);
    final soloEjemplos = todas.every((competencia) => competencia.esDeEjemplo);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: competitions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explora competencias',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Filtrar por categoría',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: categoriaSeleccionada == null,
                      onSelected: (_) {
                        setState(() {
                          categoriaSeleccionada = null;
                        });
                      },
                    ),
                    ...todas
                        .map((competencia) => competencia.categoria)
                        .toSet()
                        .map(
                          (categoria) => ChoiceChip(
                            label: Text(categoria),
                            selected: categoriaSeleccionada == categoria,
                            onSelected: (_) {
                              setState(() {
                                categoriaSeleccionada = categoria;
                              });
                            },
                          ),
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
                      color: Theme.of(context).colorScheme.primary,
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
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          // Aclara cuántas de las listadas ya pasaron.
                          if (finalizadas > 0)
                            Text(
                              porVenir == 0
                                  ? 'Todas ya finalizaron'
                                  : '$porVenir por venir · $finalizadas ya '
                                        '${finalizadas == 1 ? 'finalizó' : 'finalizaron'}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            soloEjemplos
                                ? 'Competencias ficticias para desarrollo y pruebas. No son eventos reales.'
                                : 'Las competencias de ejemplo son ficticias. No son eventos reales.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (competitions.isEmpty) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No se encontraron competencias',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          categoriaSeleccionada == null
                              ? 'Todavía no hay competencias disponibles.'
                              : 'Prueba otra categoría o selecciona Todas.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Vacío por falta de datos: volver a consultar.
                        // Vacío por el filtro: regresar a Todas.
                        if (categoriaSeleccionada == null)
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
                  ),
                ],
              ],
            ),
          );
        }

        final competition = competitions[index - 1];
        final card = CompetitionCard(
          key: ValueKey(competition.id),
          competition: competition,
          ahora: ahora,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                // El Detalle consulta por id con competenciaPorIdProvider.
                builder: (_) =>
                    CompetitionDetailScreen(competitionId: competition.id),
              ),
            );
          },
        );
        // Rótulo antes de la primera finalizada de cada tramo. Va dentro del
        // mismo elemento de la lista para no alterar la cantidad de elementos.
        final iniciaFinalizadas =
            estaFinalizada(competition, ahora) &&
            (index == 1 || !estaFinalizada(competitions[index - 2], ahora));
        if (!iniciaFinalizadas) {
          return card;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text(
                'Finalizadas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            card,
          ],
        );
      },
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

class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    required this.ahora,
    required this.onTap,
  });

  final Competencia competition;
  final DateTime ahora;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = estiloDeCategoria(competition.categoria, scheme);
    final estado = estadoTemporal(competition, ahora);
    final etiquetaEstado = etiquetaTemporal(competition, ahora);
    final fechaHora = formatearFechaHoraLegible(competition.fechaInicio);
    // Las finalizadas usan un tono neutro; lo que aún se puede aprovechar
    // resalta con el color del tema.
    final finalizada = estado == EstadoTemporal.finalizada;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      // Un lector de pantalla anuncia la tarjeta como un solo botón con sus
      // datos clave, en lugar de leer cada etiqueta por separado.
      child: Semantics(
        container: true,
        button: true,
        excludeSemantics: true,
        onTap: onTap,
        label:
            '${competition.titulo}. $etiquetaEstado. '
            '${competition.categoria}, ${competition.modalidad}. '
            '$fechaHora. Ubicación: ${competition.ubicacion}. '
            'Costo: ${competition.costo}.',
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competition.titulo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Etiqueta(
                      texto: etiquetaEstado,
                      icono: finalizada
                          ? Icons.event_busy_outlined
                          : Icons.schedule_outlined,
                      colorTexto: finalizada
                          ? scheme.onSurfaceVariant
                          : scheme.onPrimaryContainer,
                      colorFondo: finalizada
                          ? scheme.surfaceContainerHighest
                          : scheme.primaryContainer,
                    ),
                    Etiqueta(
                      texto: competition.categoria,
                      icono: category.icono,
                      colorTexto: category.color,
                      colorFondo: fondoSuave(category.color, scheme.surface),
                    ),
                    Etiqueta(
                      texto: competition.modalidad,
                      colorTexto: scheme.onSurfaceVariant,
                      colorFondo: scheme.surfaceContainerHighest,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.calendar_today_outlined, text: fechaHora),
                const SizedBox(height: 7),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: 'Ubicación: ${competition.ubicacion}',
                ),
                const SizedBox(height: 7),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  text: 'Costo: ${competition.costo}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    );
  }
}
