import 'package:flutter/material.dart';

import 'data/competencia.dart';
import 'data/mock_competencias.dart';

void main() {
  runApp(const CompetihubApp());
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
      home: HomeScreen(competitions: competenciasMock),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.competitions});

  final List<Competencia> competitions;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? categoriaSeleccionada;

  @override
  Widget build(BuildContext context) {
    final competitions = categoriaSeleccionada == null
        ? widget.competitions
        : widget.competitions
              .where(
                (competencia) => competencia.categoria == categoriaSeleccionada,
              )
              .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('CompetiHub'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: ListView.builder(
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
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                        ...widget.competitions
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
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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
            );
          },
        ),
      ),
    );
  }
}

class CompetitionCard extends StatelessWidget {
  const CompetitionCard({super.key, required this.competition});

  final Competencia competition;

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
                  avatar: Icon(category.icon, size: 17, color: category.color),
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
