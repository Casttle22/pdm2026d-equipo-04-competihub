import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_competencias.dart';
import '../widgets/mapa_base.dart';

// Pantalla para elegir el punto de una competencia tocando el mapa. Devuelve
// el punto elegido, o null si se sale sin elegir.
class SelectorUbicacionScreen extends StatefulWidget {
  const SelectorUbicacionScreen({super.key, this.inicial});

  final LatLng? inicial;

  @override
  State<SelectorUbicacionScreen> createState() =>
      _SelectorUbicacionScreenState();
}

class _SelectorUbicacionScreenState extends State<SelectorUbicacionScreen> {
  late LatLng? _punto = widget.inicial;

  @override
  Widget build(BuildContext context) {
    final punto = _punto;
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir ubicación')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                punto == null
                    ? 'Toca el mapa para marcar dónde será la competencia.'
                    : 'Punto marcado: ${describirPunto(punto)}. Toca otro '
                          'lugar para cambiarlo.',
                key: const ValueKey('selector-instrucciones'),
              ),
            ),
            Expanded(
              child: MapaBase(
                key: const ValueKey('selector-mapa'),
                centro:
                    widget.inicial ??
                    const LatLng(
                      latitudCentroDeEjemplo,
                      longitudCentroDeEjemplo,
                    ),
                zoom: 15,
                onTap: (nuevo) => setState(() => _punto = nuevo),
                marcadores: [
                  if (punto != null)
                    Marker(
                      point: punto,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                        semanticLabel: 'Punto elegido',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            key: const ValueKey('selector-usar-punto'),
            onPressed: punto == null
                ? null
                : () => Navigator.of(context).pop(punto),
            icon: const Icon(Icons.check),
            label: const Text('Usar este punto'),
          ),
        ),
      ),
    );
  }
}

// «14.84050, -91.52350»: cinco decimales son alrededor de un metro.
String describirPunto(LatLng punto) =>
    '${punto.latitude.toStringAsFixed(5)}, '
    '${punto.longitude.toStringAsFixed(5)}';
