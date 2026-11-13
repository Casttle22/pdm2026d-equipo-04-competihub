import 'package:flutter/material.dart';

import '../data/competencia.dart';
import '../tema.dart';
import '../utils/fechas.dart';
import 'boton_guardar.dart';
import 'categoria_estilo.dart';
import 'etiqueta.dart';
import 'etiquetas_ficha.dart';
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

// «14 de nov, 2026 · Galería virtual…»: la línea de fecha y lugar de las
// tarjetas.
String fechaYLugar(Competencia competition) =>
    '${formatearRangoCorto(competition.fechaInicio, competition.fechaFin)} · '
    '${competition.ubicacion}';

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

// Cuadro de 64 dp: la portada de la competencia si tiene, o el ícono de la
// categoría sobre su color suave.
class CuadroDeCategoria extends StatelessWidget {
  const CuadroDeCategoria({super.key, required this.categoria, this.imagen});

  final String categoria;
  final String? imagen;

  @override
  Widget build(BuildContext context) {
    final imagen = this.imagen?.trim();
    if (imagen != null && imagen.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radioCampo),
        child: SizedBox(
          width: 64,
          height: 64,
          child: ImagenCompetencia(
            imagenUrl: imagen,
            categoria: categoria,
            alto: 64,
          ),
        ),
      );
    }
    final estilo = estiloDeCategoria(categoria, Theme.of(context).colorScheme);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: fondoSuave(estilo.color, Colors.white),
        borderRadius: BorderRadius.circular(radioCampo),
      ),
      child: Icon(estilo.icono, color: estilo.color, size: 32),
    );
  }
}

// Fila de «Próximos eventos» (y de Explorar y Mis eventos): tarjeta blanca
// con el cuadro de la categoría, título, fecha y lugar, costo, etiquetas y
// el botón «Detalles».
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
    final textTheme = Theme.of(context).textTheme;
    final formato = competition.formato;
    final categoria = estiloDeCategoria(competition.categoria, scheme);
    final secundario = textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaBlanca(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Un lector de pantalla anuncia esta parte como un solo botón
            // con los datos clave, en lugar de leer cada etiqueta.
            Semantics(
              container: true,
              button: true,
              excludeSemantics: true,
              onTap: onTap,
              label: resumenAccesible(competition, ahora),
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CuadroDeCategoria(
                            categoria: competition.categoria,
                            imagen: competition.imagenUrl,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // El nombre de la categoría acompaña al
                                // ícono del cuadro: el ícono solo es ambiguo.
                                Text(
                                  competition.categoria,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: categoria.color,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  competition.titulo,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fechaYLugar(competition),
                                  style: secundario,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Costo: ${competition.costo}',
                                  style: secundario,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
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
                          if (formato != null)
                            EtiquetaDeFormato(formato: formato),
                          EtiquetaDeModalidad(modalidad: competition.modalidad),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Guardar y Detalles quedan fuera del resumen agrupado para que
            // el lector de pantalla los ofrezca como controles aparte.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
              // Con texto grande, «Detalles» baja a otra línea si no cabe.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  BotonGuardar(competencia: competition),
                  Semantics(
                    label: 'Ver detalles de «${competition.titulo}»',
                    button: true,
                    excludeSemantics: true,
                    onTap: onTap,
                    child: FilledButton(
                      key: ValueKey('detalles-${competition.id}'),
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radioCampo),
                        ),
                      ),
                      child: const Text('Detalles'),
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

// Tarjeta grande del carrusel «Eventos destacados»: imagen de fondo (o el
// degradado de la categoría con su ícono) y, encima, sobre un velo oscuro,
// el título, el subtítulo, el organizador, la fecha y la modalidad con el
// lugar, en blanco.
class TarjetaDestacada extends StatelessWidget {
  const TarjetaDestacada({
    super.key,
    required this.competition,
    required this.ahora,
    required this.onTap,
    this.posicion,
  });

  final Competencia competition;
  final DateTime ahora;
  final VoidCallback onTap;

  // «1 de 3», para el lector de pantalla.
  final String? posicion;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final organizador = competition.organizador?.trim();
    final inscripcion = etiquetaInscripcion(competition, ahora);
    // Subtítulo: la primera línea de la descripción (no hay un campo propio).
    final subtitulo = competition.descripcion.trim().split('\n').first;
    const blanco = Colors.white;
    final secundario = Colors.white.withValues(alpha: 0.92);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radioTarjeta),
        boxShadow: sombraSuave,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radioTarjeta),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImagenCompetencia(
              imagenUrl: competition.imagenUrl,
              categoria: competition.categoria,
              alto: double.infinity,
              alineacionIcono: const Alignment(0.85, -0.2),
            ),
            // Velo: oscurece la mitad de abajo para que el texto blanco se
            // lea sobre cualquier imagen.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Oscuro desde antes de la mitad: el título va ahí y debe
                  // leerse también sobre fotos claras.
                  colors: [
                    Color(0x14000000),
                    Color(0xA6000000),
                    Color(0xE6000000),
                  ],
                  stops: [0.0, 0.4, 0.75],
                ),
              ),
            ),
            Semantics(
              container: true,
              button: true,
              excludeSemantics: true,
              onTap: onTap,
              label:
                  'Destacada${posicion == null ? '' : ' $posicion'}. '
                  '${resumenAccesible(competition, ahora)}',
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // El bloque de texto va abajo. Si algún dato es tan
                        // largo que no cabe, se recorta por abajo: el título
                        // siempre queda visible.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, restricciones) => ClipRect(
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: restricciones.maxHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        competition.titulo,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleLarge?.copyWith(
                                          color: blanco,
                                          fontWeight: FontWeight.w800,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitulo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: secundario,
                                        ),
                                      ),
                                      if (organizador != null &&
                                          organizador.isNotEmpty)
                                        _LineaBlanca(
                                          icono: Icons.apartment_outlined,
                                          texto: organizador,
                                        ),
                                      // Fecha y tiempo restante en una
                                      // línea; la inscripción, si la hay,
                                      // en la siguiente.
                                      _LineaBlanca(
                                        icono: Icons.event_outlined,
                                        texto:
                                            '${formatearRangoCorto(competition.fechaInicio, competition.fechaFin)}'
                                            ' · ${etiquetaTemporal(competition, ahora)}',
                                      ),
                                      if (inscripcion != null)
                                        _LineaBlanca(
                                          icono: Icons.how_to_reg_outlined,
                                          texto: inscripcion,
                                        ),
                                      _LineaBlanca(
                                        icono: coloresDeModalidad(
                                          competition.modalidad,
                                        ).icono,
                                        texto:
                                            '${competition.modalidad} · '
                                            '${competition.ubicacion}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: BotonGuardar(competencia: competition, sobreImagen: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaBlanca extends StatelessWidget {
  const _LineaBlanca({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
