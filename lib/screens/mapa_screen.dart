import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';

// Pestaña Mapa. Por ahora solo explica qué mostrará; el mapa interactivo se
// agrega en el módulo 10.
class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa'), centerTitle: true),
      body: const SafeArea(
        child: EstadoVacio(
          icono: Icons.map_outlined,
          titulo: 'Mapa de competencias',
          mensaje:
              'Aquí verás en un mapa las competencias presenciales que '
              'tengan ubicación.',
        ),
      ),
    );
  }
}
