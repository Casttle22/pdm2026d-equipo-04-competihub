import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/competencia.dart';
import '../data/mock_competencias.dart';
import '../providers/competencias_providers.dart';
import '../providers/reloj_provider.dart';
import '../servicios/abridor_de_mapas.dart';
import '../utils/fechas.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/mapa_base.dart';
import '../widgets/tarjeta_competencia.dart';
import 'competition_detail_screen.dart';

// Las competencias que se ubican en el mapa: las que tienen un lugar físico
// (presenciales e híbridas) y coordenadas.
List<Competencia> competenciasEnMapa(Iterable<Competencia> competencias) => [
  for (final competencia in competencias)
    if (competencia.tieneCoordenadas && admiteComoLlegar(competencia.modalidad))
      competencia,
];

// Pestaña Mapa: un marcador por competencia; al tocarlo aparece una tarjeta
// breve que lleva al Detalle.
class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  String? _seleccionada;

  @override
  Widget build(BuildContext context) {
    final competenciasAsync = ref.watch(competenciasProvider);
    final ahora = ref.watch(relojProvider)();
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa'), centerTitle: true),
      body: SafeArea(
        child: competenciasAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EstadoVacio(
            icono: Icons.error_outline,
            titulo: 'No pudimos cargar las competencias.',
            mensaje: 'Intenta de nuevo en un momento.',
            accion: FilledButton.icon(
              onPressed: () => ref.invalidate(competenciasProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
          data: (competencias) =>
              _mapa(context, competenciasEnMapa(competencias), ahora),
        ),
      ),
    );
  }

  Widget _mapa(BuildContext context, List<Competencia> enMapa, DateTime ahora) {
    if (enMapa.isEmpty) {
      return const EstadoVacio(
        key: ValueKey('mapa-vacio'),
        icono: Icons.location_off_outlined,
        titulo: 'No hay competencias en el mapa',
        mensaje:
            'Aparecen aquí las competencias presenciales o híbridas que '
            'tienen un punto en el mapa. Puedes elegirlo al crear o editar '
            'una competencia.',
      );
    }
    final scheme = Theme.of(context).colorScheme;
    Competencia? seleccionada;
    for (final competencia in enMapa) {
      if (competencia.id == _seleccionada) {
        seleccionada = competencia;
      }
    }
    final hayEjemplos = enMapa.any((c) => c.esDeEjemplo);
    final puntos = [for (final c in enMapa) LatLng(c.latitud!, c.longitud!)];

    return Stack(
      children: [
        MapaBase(
          key: const ValueKey('mapa-competencias'),
          centro: puntos.length == 1
              ? puntos.single
              : const LatLng(latitudCentroDeEjemplo, longitudCentroDeEjemplo),
          zoom: 14,
          ajustarA: puntos,
          avisoFicticio: hayEjemplos
              ? (enMapa.every((c) => c.esDeEjemplo)
                    ? 'Ubicaciones ficticias de ejemplo.'
                    : 'Las ubicaciones de los ejemplos son ficticias.')
              : null,
          onTap: (_) => setState(() => _seleccionada = null),
          marcadores: [
            for (final competencia in enMapa)
              Marker(
                point: LatLng(competencia.latitud!, competencia.longitud!),
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: IconButton(
                  key: ValueKey('marcador-${competencia.id}'),
                  tooltip: competencia.titulo,
                  padding: EdgeInsets.zero,
                  iconSize: 44,
                  isSelected: competencia.id == _seleccionada,
                  onPressed: () =>
                      setState(() => _seleccionada = competencia.id),
                  icon: Icon(
                    Icons.location_on,
                    color: estiloDeCategoria(
                      competencia.categoria,
                      scheme,
                    ).color,
                    shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
        if (seleccionada != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 28,
            child: _TarjetaBreve(
              competencia: seleccionada,
              ahora: ahora,
              onCerrar: () => setState(() => _seleccionada = null),
            ),
          ),
      ],
    );
  }
}

class _TarjetaBreve extends StatelessWidget {
  const _TarjetaBreve({
    required this.competencia,
    required this.ahora,
    required this.onCerrar,
  });

  final Competencia competencia;
  final DateTime ahora;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Con texto grande la tarjeta puede crecer: se limita a la mitad del
    // alto y se desplaza por dentro.
    final altoMaximo = MediaQuery.sizeOf(context).height * 0.5;
    return Card(
      key: const ValueKey('mapa-tarjeta-breve'),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: altoMaximo),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        competencia.titulo,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: onCerrar,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EtiquetaDeEstado(competition: competencia, ahora: ahora),
                    const SizedBox(height: 8),
                    Text(formatearFechaHoraLegible(competencia.fechaInicio)),
                    const SizedBox(height: 4),
                    Text(competencia.ubicacion),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('mapa-ver-detalle'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CompetitionDetailScreen(
                            competitionId: competencia.id,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ver detalle'),
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
