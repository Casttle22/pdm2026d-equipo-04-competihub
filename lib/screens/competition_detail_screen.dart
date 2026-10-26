import 'package:flutter/material.dart';

import '../data/competencia.dart';

class CompetitionDetailScreen extends StatelessWidget {
  const CompetitionDetailScreen({
    super.key,
    required this.competitionId,
    required this.competitions,
  });

  final String competitionId;
  final List<Competencia> competitions;

  String _twoDigits(int number) => number.toString().padLeft(2, '0');

  String _formatDate(DateTime date) =>
      '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';

  String _formatTime(DateTime date) =>
      '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

  @override
  Widget build(BuildContext context) {
    Competencia? selectedCompetition;
    for (final competition in competitions) {
      if (competition.id == competitionId) {
        selectedCompetition = competition;
        break;
      }
    }

    if (selectedCompetition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de competencia')),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se encontró la competencia seleccionada.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final competition = selectedCompetition;
    final scheme = Theme.of(context).colorScheme;
    final (accentColor, categoryIcon) = switch (competition.categoria) {
      'Esports' => (scheme.primary, Icons.sports_esports_outlined),
      'Académica' => (Colors.blue.shade700, Icons.school_outlined),
      'Deportiva' => (Colors.green.shade700, Icons.sports_soccer_outlined),
      _ => (Colors.orange.shade800, Icons.emoji_events_outlined),
    };

    final formattedDate = _formatDate(competition.fechaInicio);
    final formattedTime = _formatTime(competition.fechaInicio);
    final endDate = competition.fechaFin;
    final formattedEnd = endDate == null
        ? null
        : '${_formatDate(endDate)} a las ${_formatTime(endDate)}';
    final inscriptionUrl = competition.inscripcionUrl?.trim();
    final contact = competition.contacto?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de competencia'),
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Cabecera visual: misma pantalla para todas las competencias.
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor,
                    Color.lerp(accentColor, Colors.black, 0.48)!,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  competition.categoria,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.white,
                        size: 38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    competition.titulo,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Competencia ficticia de prueba',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.28)),
                  const SizedBox(height: 8),
                  Text(
                    'Identificador: ${competition.id}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Información general',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DetailInfoCard(
                      icon: Icons.calendar_month_outlined,
                      label: 'Fecha',
                      value: formattedDate,
                      accentColor: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailInfoCard(
                      icon: Icons.schedule_outlined,
                      label: 'Hora',
                      value: formattedTime,
                      accentColor: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            if (formattedEnd != null) ...[
              const SizedBox(height: 12),
              _DetailInfoCard(
                icon: Icons.event_outlined,
                label: 'Finaliza',
                value: formattedEnd,
                accentColor: accentColor,
              ),
            ],
            const SizedBox(height: 12),
            _DetailInfoCard(
              icon: Icons.devices_outlined,
              label: 'Modalidad',
              value: competition.modalidad,
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _DetailInfoCard(
              icon: Icons.location_on_outlined,
              label: 'Ubicación o acceso',
              value: competition.ubicacion,
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _DetailInfoCard(
              icon: Icons.description_outlined,
              label: 'Descripción',
              value: competition.descripcion,
              accentColor: accentColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Información para participar',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _DetailInfoCard(
              icon: Icons.rule_outlined,
              label: 'Requisitos y reglas',
              value: competition.reglas,
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _DetailInfoCard(
              icon: Icons.payments_outlined,
              label: 'Costo',
              value: competition.costo,
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _DetailInfoCard(
              icon: Icons.how_to_reg_outlined,
              label: 'Cómo participar',
              value: competition.instruccionesParticipacion,
              accentColor: accentColor,
            ),
            if (inscriptionUrl != null && inscriptionUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailInfoCard(
                icon: Icons.link_outlined,
                label: 'Enlace de referencia',
                value: inscriptionUrl,
                accentColor: accentColor,
              ),
            ],
            if (contact != null && contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailInfoCard(
                icon: Icons.alternate_email_outlined,
                label: 'Contacto',
                value: contact,
                accentColor: accentColor,
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Estos datos y los medios de contacto o inscripción son '
                      'ficticios. Se usan solo para desarrollo y no permiten '
                      'participar en eventos reales.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 25),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
