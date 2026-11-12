import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';

// Pestaña Mis eventos. Por ahora solo explica qué mostrará; guardar
// competencias se agrega en el módulo 8.
class MisEventosScreen extends StatelessWidget {
  const MisEventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis eventos'), centerTitle: true),
      body: const SafeArea(
        child: EstadoVacio(
          icono: Icons.bookmark_border,
          titulo: 'Tus competencias guardadas',
          mensaje: 'Aquí verás las competencias que guardes.',
        ),
      ),
    );
  }
}
