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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(competitions: competenciasMock),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.competitions});

  final List<Competencia> competitions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CompetiHub'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
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
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Competencias ficticias para desarrollo y pruebas. No son eventos reales.',
                    ),
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
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              competition.titulo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(competition.categoria)),
                Chip(label: Text(competition.modalidad)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Inicio: ${_formatDate(competition.fechaInicio)}'),
            const SizedBox(height: 4),
            Text('Ubicación: ${competition.ubicacion}'),
          ],
        ),
      ),
    );
  }
}
