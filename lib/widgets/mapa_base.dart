import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// Mapa con teselas de OpenStreetMap que usan la pestaña Mapa, el Detalle y
// el selector de ubicación del formulario. Se encarga de tres cosas que
// todos necesitan:
// - Identificar la app ante el servidor de teselas (userAgentPackageName),
//   como pide la política de uso de OpenStreetMap.
// - Mostrar siempre la atribución «© OpenStreetMap contributors».
// - Sin conexión, mostrar un estado claro con Reintentar en lugar de un mapa
//   en blanco.

const String urlTeselasOsm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

// Identificador con el que la app se presenta ante OpenStreetMap. No puede
// empezar con «com.example»: OpenStreetMap bloquea esos identificadores
// (error 403 «Access blocked»). Si se cambia el applicationId de Android a un
// valor propio, conviene usar el mismo aquí.
const String idDeLaApp = 'gt.edu.umes.competihub';

// Origen de las teselas. null usa la red (OpenStreetMap); las pruebas lo
// reemplazan para no depender de internet.
final proveedorDeTeselasProvider = Provider<TileProvider?>((ref) => null);

// Cuántas teselas tienen que fallar para suponer que no hay conexión. Con
// una sola, un fallo aislado del servidor ocultaría todo el mapa.
const int erroresParaSinConexion = 3;

class MapaBase extends ConsumerStatefulWidget {
  const MapaBase({
    super.key,
    required this.centro,
    this.zoom = 14,
    this.ajustarA,
    this.marcadores = const [],
    this.onTap,
    this.interactivo = true,
    this.avisoFicticio,
  });

  final LatLng centro;
  final double zoom;

  // Si hay varios puntos, la cámara se ajusta para que se vean todos.
  final List<LatLng>? ajustarA;
  final List<Marker> marcadores;
  final void Function(LatLng punto)? onTap;

  // En el Detalle el mapa es solo una vista: no se mueve, para no pelear
  // con el desplazamiento de la pantalla.
  final bool interactivo;

  // Texto del aviso de ubicaciones ficticias, si corresponde.
  final String? avisoFicticio;

  @override
  ConsumerState<MapaBase> createState() => _MapaBaseState();
}

class _MapaBaseState extends ConsumerState<MapaBase> {
  int _errores = 0;
  bool _sinConexion = false;

  // Cambia con Reintentar para que la capa de teselas se cree de nuevo y
  // vuelva a pedirlas.
  int _intento = 0;

  void _alFallarTesela(TileImage tesela, Object error, StackTrace? pila) {
    _errores++;
    if (_errores < erroresParaSinConexion || _sinConexion) {
      return;
    }
    // El aviso llega mientras el mapa se dibuja: se espera al final del
    // cuadro para cambiar el estado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _sinConexion = true);
      }
    });
  }

  void _reintentar() {
    setState(() {
      _errores = 0;
      _sinConexion = false;
      _intento++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ajustarA = widget.ajustarA;
    final onTap = widget.onTap;
    final avisoFicticio = widget.avisoFicticio;
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: widget.centro,
            initialZoom: widget.zoom,
            initialCameraFit: ajustarA != null && ajustarA.length > 1
                ? CameraFit.coordinates(
                    coordinates: ajustarA,
                    padding: const EdgeInsets.all(56),
                    maxZoom: 16,
                  )
                : null,
            interactionOptions: InteractionOptions(
              flags: widget.interactivo
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
            onTap: onTap == null ? null : (_, punto) => onTap(punto),
          ),
          children: [
            TileLayer(
              key: ValueKey('teselas-$_intento'),
              urlTemplate: urlTeselasOsm,
              userAgentPackageName: idDeLaApp,
              tileProvider: ref.watch(proveedorDeTeselasProvider),
              errorTileCallback: _alFallarTesela,
            ),
            MarkerLayer(markers: widget.marcadores),
            const AtribucionOsm(),
          ],
        ),
        if (avisoFicticio != null)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Align(
              alignment: Alignment.topLeft,
              child: AvisoUbicacionFicticia(texto: avisoFicticio),
            ),
          ),
        if (_sinConexion)
          Positioned.fill(child: _SinConexion(onReintentar: _reintentar)),
      ],
    );
  }
}

// «© OpenStreetMap contributors», siempre visible en la esquina del mapa.
// Al tocarla abre la página de derechos de autor de OpenStreetMap.
class AtribucionOsm extends StatelessWidget {
  const AtribucionOsm({super.key});

  static final Uri paginaDeDerechos = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );

  Future<void> _abrir() async {
    try {
      await launchUrl(paginaDeDerechos, mode: LaunchMode.externalApplication);
    } on PlatformException {
      // Sin navegador no hay nada más que hacer; el texto sigue visible.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomRight,
      child: Semantics(
        link: true,
        child: Material(
          color: scheme.surface.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
          child: InkWell(
            key: const ValueKey('atribucion-osm'),
            onTap: _abrir,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AvisoUbicacionFicticia extends StatelessWidget {
  const AvisoUbicacionFicticia({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('aviso-ubicacion-ficticia'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinConexion extends StatelessWidget {
  const _SinConexion({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const ValueKey('mapa-sin-conexion'),
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, color: scheme.onSurfaceVariant),
              const SizedBox(height: 8),
              const Text(
                'No se pudo cargar el mapa. Revisa tu conexión a internet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
