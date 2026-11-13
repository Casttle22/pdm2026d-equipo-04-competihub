import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competencia.dart';
import '../data/creditos_imagenes.dart';
import '../data/media_competencia.dart';
import '../servicios/abridor_de_enlaces.dart';
import '../tema.dart';
import 'imagen_competencia.dart';

// Sección «Fotos y videos» del Detalle: una fila horizontal de miniaturas.
// - Imagen: al tocarla se abre en grande, con un botón para cerrar.
// - Video: miniatura con un ícono de play; al tocarla se abre el enlace en
//   otra app (no hay reproductor dentro de la app).
// Quien la usa decide no mostrarla si la competencia no tiene galería.
class GaleriaCompetencia extends StatelessWidget {
  const GaleriaCompetencia({super.key, required this.competencia});

  final Competencia competencia;

  static const double _ancho = 168;
  static const double _altoImagen = 112;

  @override
  Widget build(BuildContext context) {
    final galeria = competencia.galeria;
    // Debajo de la imagen van hasta dos líneas de título, que crecen con el
    // texto del sistema.
    final altoTitulo = MediaQuery.textScalerOf(context).scale(44);
    return SizedBox(
      key: const ValueKey('detalle-galeria'),
      height: _altoImagen + 8 + altoTitulo,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: galeria.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, indice) => SizedBox(
          width: _ancho,
          child: _Miniatura(
            key: ValueKey('galeria-$indice'),
            media: galeria[indice],
            competencia: competencia,
          ),
        ),
      ),
    );
  }
}

class _Miniatura extends ConsumerWidget {
  const _Miniatura({super.key, required this.media, required this.competencia});

  final MediaCompetencia media;
  final Competencia competencia;

  Future<void> _abrirVideo(BuildContext context, WidgetRef ref) async {
    final abridor = ref.read(abridorDeEnlacesProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (competencia.esDeEjemplo) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          icon: const Icon(Icons.info_outline),
          title: const Text('Video ficticio'),
          content: const Text(
            'Esta competencia es de ejemplo: el enlace no lleva a un video '
            'real.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('video-abrir-igual'),
              onPressed: () => Navigator.of(contexto).pop(true),
              child: const Text('Abrir de todos modos'),
            ),
          ],
        ),
      );
      if (seguir != true) {
        return;
      }
    }
    if (!await abridor.abrir(media.fuente)) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el video.')),
        );
    }
  }

  void _verImagen(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ImagenAmpliada(media: media, competencia: competencia),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final esVideo = media.esVideo;
    return Semantics(
      button: true,
      label: esVideo
          ? 'Video: ${media.titulo}. Se abre en otra app.'
          : 'Foto: ${media.titulo}. Toca para verla en grande.',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(radioCampo),
        onTap: esVideo
            ? () => _abrirVideo(context, ref)
            : () => _verImagen(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radioCampo),
              child: SizedBox(
                height: GaleriaCompetencia._altoImagen,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImagenCompetencia(
                      imagenUrl: media.imagenDeMiniatura,
                      categoria: competencia.categoria,
                      alto: GaleriaCompetencia._altoImagen,
                    ),
                    if (esVideo) ...[
                      // Velo para que el ícono de play se vea sobre
                      // cualquier imagen.
                      const ColoredBox(color: Color(0x59000000)),
                      const Center(
                        child: DecoratedBox(
                          key: ValueKey('galeria-play'),
                          decoration: BoxDecoration(
                            color: Color(0xCC000000),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              media.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// Imagen en grande sobre fondo oscuro, con título, crédito y botón para
// cerrar. Se puede ampliar con dos dedos.
class _ImagenAmpliada extends StatelessWidget {
  const _ImagenAmpliada({required this.media, required this.competencia});

  final MediaCompetencia media;
  final Competencia competencia;

  @override
  Widget build(BuildContext context) {
    final credito = creditoDeImagen(media.fuente);
    // Sobre el fondo oscuro del diálogo el texto va en blanco, en claro y en
    // oscuro.
    const blanco = Colors.white;
    return Dialog.fullscreen(
      key: const ValueKey('galeria-imagen-ampliada'),
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Cerrar',
                color: blanco,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: ImagenCompetencia(
                    imagenUrl: media.fuente,
                    categoria: competencia.categoria,
                    alto: double.infinity,
                    ajuste: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.titulo,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: blanco),
                  ),
                  if (credito != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      credito,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: blanco.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
