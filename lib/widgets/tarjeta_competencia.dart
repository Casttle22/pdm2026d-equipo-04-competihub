import 'package:flutter/material.dart';

import '../data/competencia.dart';
import '../utils/fechas.dart';
import 'categoria_estilo.dart';
import 'etiqueta.dart';
import 'fila_info.dart';
import 'imagen_competencia.dart';

// Resumen que un lector de pantalla anuncia para una tarjeta: los mismos
// datos clave que se ven, en una sola frase.
String resumenAccesible(Competencia competition, DateTime ahora) {
  final inscripcion = etiquetaInscripcion(competition, ahora);
  return '${competition.titulo}. ${etiquetaTemporal(competition, ahora)}. '
      '${inscripcion == null ? '' : '$inscripcion. '}'
      '${competition.categoria}, ${competition.modalidad}. '
      '${formatearFechaHoraLegible(competition.fechaInicio)}. '
      'Ubicación: ${competition.ubicacion}. '
      'Costo: ${competition.costo}.';
}

// Etiqueta de tiempo («Faltan 3 días», «Finalizada»…). Las finalizadas usan
// un tono neutro; lo que aún se puede aprovechar resalta con el color del
// tema.
class EtiquetaDeEstado extends StatelessWidget {
  const EtiquetaDeEstado({
    super.key,
    required this.competition,
    required this.ahora,
  });

  final Competencia competition;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finalizada =
        estadoTemporal(competition, ahora) == EstadoTemporal.finalizada;
    return Etiqueta(
      texto: etiquetaTemporal(competition, ahora),
      icono: finalizada ? Icons.event_busy_outlined : Icons.schedule_outlined,
      colorTexto: finalizada
          ? scheme.onSurfaceVariant
          : scheme.onPrimaryContainer,
      colorFondo: finalizada
          ? scheme.surfaceContainerHighest
          : scheme.primaryContainer,
    );
  }
}

// Estado de la inscripción. No se dibuja si la competencia no tiene fecha
// límite. El color acompaña al texto, no lo reemplaza: cada estado tiene
// también su propio ícono.
class EtiquetaDeInscripcion extends StatelessWidget {
  const EtiquetaDeInscripcion({
    super.key,
    required this.competition,
    required this.ahora,
  });

  final Competencia competition;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final estado = estadoInscripcion(competition, ahora);
    if (estado == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final (icono, texto, fondo) = switch (estado) {
      EstadoInscripcion.abiertas => (
        Icons.how_to_reg_outlined,
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
      EstadoInscripcion.cierraPronto => (
        Icons.hourglass_bottom_outlined,
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
      ),
      EstadoInscripcion.cierraHoy => (
        Icons.alarm_outlined,
        scheme.onErrorContainer,
        scheme.errorContainer,
      ),
      EstadoInscripcion.cerradas => (
        Icons.lock_outline,
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
    };
    return Etiqueta(
      key: const ValueKey('etiqueta-inscripcion'),
      texto: etiquetaInscripcion(competition, ahora)!,
      icono: icono,
      colorTexto: texto,
      colorFondo: fondo,
    );
  }
}

// Tarjeta de la lista vertical del Inicio.
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
    final fechaHora = formatearFechaHoraLegible(competition.fechaInicio);

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
        label: resumenAccesible(competition, ahora),
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
                    EtiquetaDeEstado(competition: competition, ahora: ahora),
                    if (competition.fechaLimiteInscripcion != null)
                      EtiquetaDeInscripcion(
                        competition: competition,
                        ahora: ahora,
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
                FilaInfo(icon: Icons.calendar_today_outlined, text: fechaHora),
                const SizedBox(height: 7),
                FilaInfo(
                  icon: Icons.location_on_outlined,
                  text: 'Ubicación: ${competition.ubicacion}',
                ),
                const SizedBox(height: 7),
                FilaInfo(
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

// Tarjeta de la sección Destacados: más angosta, con imagen (o el fondo de
// la categoría) arriba. Muestra los mismos datos clave que la tarjeta de la
// lista.
class TarjetaDestacada extends StatelessWidget {
  const TarjetaDestacada({
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        button: true,
        excludeSemantics: true,
        onTap: onTap,
        label: 'Destacada. ${resumenAccesible(competition, ahora)}',
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ImagenCompetencia(
                imagenUrl: competition.imagenUrl,
                categoria: competition.categoria,
                alto: 96,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        EtiquetaDeEstado(
                          competition: competition,
                          ahora: ahora,
                        ),
                        if (competition.fechaLimiteInscripcion != null)
                          EtiquetaDeInscripcion(
                            competition: competition,
                            ahora: ahora,
                          ),
                        Etiqueta(
                          texto: competition.categoria,
                          icono: category.icono,
                          colorTexto: category.color,
                          colorFondo: fondoSuave(
                            category.color,
                            scheme.surface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      competition.titulo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilaInfo(
                      icon: Icons.calendar_today_outlined,
                      text: formatearFechaHoraLegible(competition.fechaInicio),
                    ),
                    const SizedBox(height: 6),
                    FilaInfo(
                      icon: Icons.location_on_outlined,
                      text: 'Ubicación: ${competition.ubicacion}',
                    ),
                    const SizedBox(height: 6),
                    FilaInfo(
                      icon: Icons.payments_outlined,
                      text: 'Costo: ${competition.costo}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
