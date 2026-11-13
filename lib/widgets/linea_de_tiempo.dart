import 'package:flutter/material.dart';

import '../data/etapa.dart';
import '../utils/fechas.dart';

// Cronograma vertical: un punto por etapa unido por una línea. La etapa
// actual se resalta con el color del tema, un punto relleno más grande y el
// rótulo «Etapa actual». Las completadas llevan una marca; las próximas, un
// punto vacío. El estado también se anuncia en texto al lector de pantalla,
// no solo con color.
class LineaDeTiempo extends StatelessWidget {
  const LineaDeTiempo({
    super.key,
    required this.etapas,
    required this.ahora,
    required this.competenciaFinalizada,
    required this.colorAcento,
  });

  final List<Etapa> etapas;
  final DateTime ahora;
  final bool competenciaFinalizada;
  final Color colorAcento;

  @override
  Widget build(BuildContext context) {
    final estados = estadosDeEtapas(
      etapas,
      ahora,
      competenciaFinalizada: competenciaFinalizada,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < etapas.length; i++)
          _FilaDeEtapa(
            key: ValueKey('etapa-$i'),
            etapa: etapas[i],
            estado: estados[i],
            esPrimera: i == 0,
            esUltima: i == etapas.length - 1,
            colorAcento: colorAcento,
          ),
      ],
    );
  }
}

class _FilaDeEtapa extends StatelessWidget {
  const _FilaDeEtapa({
    super.key,
    required this.etapa,
    required this.estado,
    required this.esPrimera,
    required this.esUltima,
    required this.colorAcento,
  });

  final Etapa etapa;
  final EstadoEtapa estado;
  final bool esPrimera;
  final bool esUltima;
  final Color colorAcento;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actual = estado == EstadoEtapa.actual;
    final completada = estado == EstadoEtapa.completada;
    final colorLinea = scheme.outlineVariant;
    final descripcion = etapa.descripcion?.trim();
    final fecha = formatearFechaHoraLegible(etapa.fechaHora);
    final textoEstado = switch (estado) {
      EstadoEtapa.completada => 'Completada',
      EstadoEtapa.actual => 'Etapa actual',
      EstadoEtapa.proxima => 'Próxima',
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${etapa.nombre}. $textoEstado. $fecha.'
          '${descripcion == null || descripcion.isEmpty ? '' : ' $descripcion'}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: 6,
                    color: esPrimera ? Colors.transparent : colorLinea,
                  ),
                  _Punto(
                    actual: actual,
                    completada: completada,
                    colorAcento: colorAcento,
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: esUltima ? Colors.transparent : colorLinea,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: esUltima ? 0 : 18),
                child: Container(
                  padding: actual ? const EdgeInsets.all(12) : EdgeInsets.zero,
                  decoration: actual
                      ? BoxDecoration(
                          color: Color.alphaBlend(
                            colorAcento.withValues(alpha: 0.10),
                            scheme.surface,
                          ),
                          border: Border.all(color: colorAcento, width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (actual) ...[
                        Text(
                          'Etapa actual',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorAcento,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        etapa.nombre,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: actual
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: completada ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fecha,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (descripcion != null && descripcion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(descripcion),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({
    required this.actual,
    required this.completada,
    required this.colorAcento,
  });

  final bool actual;
  final bool completada;
  final Color colorAcento;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lado = actual ? 22.0 : 18.0;
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: actual || completada ? colorAcento : scheme.surface,
        border: Border.all(
          color: actual || completada ? colorAcento : scheme.outline,
          width: 2,
        ),
      ),
      child: completada
          ? Icon(
              Icons.check,
              size: 12,
              color:
                  ThemeData.estimateBrightnessForColor(colorAcento) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black,
            )
          : null,
    );
  }
}
