import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/competencia.dart';
import 'providers/competencias_providers.dart';
import 'screens/competition_detail_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
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

  @override
  Widget build(BuildContext context) {
    final competenciasAsync = ref.watch(competenciasProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CompetiHub'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        // skipLoadingOnRefresh: false hace que, al reintentar, se vea otra vez
        // el indicador de carga en lugar del error anterior.
        child: competenciasAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => const _FeedCargando(),
          error: (error, stackTrace) =>
              _FeedError(onReintentar: _volverACargar),
          data: (competencias) => _buildFeed(context, competencias),
        ),
      ),
    );
  }

  Widget _buildFeed(BuildContext context, List<Competencia> todas) {
    final competitions = categoriaSeleccionada == null
        ? todas
        : todas
              .where(
                (competencia) => competencia.categoria == categoriaSeleccionada,
              )
              .toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: competitions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explora competencias',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Encuentra tu próximo reto y descubre nuevas formas de competir.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filtrar por categoría',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        competitions.length == 1
                            ? '1 competencia disponible'
                            : '${competitions.length} competencias disponibles',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Competencias ficticias para desarrollo y pruebas. No son eventos reales.',
                        ),
                      ),
                    ],
                  ),
                ),
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
        return CompetitionCard(
          key: ValueKey(competition.id),
          competition: competition,
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
    required this.onTap,
  });

  final Competencia competition;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  ({Color color, IconData icon}) _categoryStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (competition.categoria) {
      'Esports' => (color: scheme.primary, icon: Icons.sports_esports_outlined),
      'Académica' => (color: Colors.blue.shade700, icon: Icons.school_outlined),
      'Deportiva' => (
        color: Colors.green.shade700,
        icon: Icons.sports_soccer_outlined,
      ),
      _ => (color: Colors.orange.shade800, icon: Icons.emoji_events_outlined),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = _categoryStyle(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      competition.titulo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(category.icon, color: category.color, size: 26),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: Icon(
                      category.icon,
                      size: 17,
                      color: category.color,
                    ),
                    label: Text(competition.categoria),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: category.color.withValues(alpha: 0.12),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: category.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Chip(
                    label: Text(competition.modalidad),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.surfaceContainerHighest,
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: 'Inicio: ${_formatDate(competition.fechaInicio)}',
              ),
              const SizedBox(height: 7),
              _InfoRow(
                icon: Icons.schedule_outlined,
                text: _formatTime(competition.fechaInicio),
              ),
              const SizedBox(height: 7),
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: 'Ubicación: ${competition.ubicacion}',
              ),
            ],
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
