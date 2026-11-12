import 'package:flutter/material.dart';

import 'categoria_estilo.dart';

// Imagen de una competencia para Destacados y el Detalle.
// - Con imagenUrl: muestra la imagen. Mientras carga, o si falla, deja el
//   fondo de la categoría como marcador de posición.
// - Sin imagenUrl: fondo con el color y el ícono de la categoría.
// Es decorativa: el título y los datos ya están en texto junto a ella.
class ImagenCompetencia extends StatelessWidget {
  const ImagenCompetencia({
    super.key,
    required this.imagenUrl,
    required this.categoria,
    this.alto = 120,
  });

  final String? imagenUrl;
  final String categoria;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final url = imagenUrl?.trim();
    if (url == null || url.isEmpty) {
      return FondoDeCategoria(categoria: categoria, alto: alto);
    }
    return SizedBox(
      height: alto,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        loadingBuilder: (context, child, progreso) => progreso == null
            ? child
            : FondoDeCategoria(categoria: categoria, alto: alto),
        errorBuilder: (context, error, stackTrace) => FondoDeCategoria(
          key: const ValueKey('imagen-no-disponible'),
          categoria: categoria,
          alto: alto,
          imagenFallida: true,
        ),
      ),
    );
  }
}

class FondoDeCategoria extends StatelessWidget {
  const FondoDeCategoria({
    super.key,
    required this.categoria,
    required this.alto,
    this.imagenFallida = false,
  });

  final String categoria;
  final double alto;

  // true cuando había una imagen y no se pudo cargar: se indica con un
  // ícono pequeño, sin tapar el marcador.
  final bool imagenFallida;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloDeCategoria(categoria, Theme.of(context).colorScheme);
    return ExcludeSemantics(
      child: Container(
        height: alto,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              estilo.color,
              Color.lerp(estilo.color, Colors.black, 0.4)!,
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                estilo.icono,
                size: alto * 0.45,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            if (imagenFallida)
              const Positioned(
                right: 8,
                bottom: 8,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
