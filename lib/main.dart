import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/inicio_screen.dart';
import 'tema.dart';

// El Inicio y sus tarjetas viven en sus propios archivos. Se reexportan
// porque son parte de la interfaz pública de la app que usan las pruebas.
export 'screens/inicio_screen.dart' show HomeScreen;
export 'widgets/tarjeta_competencia.dart'
    show CompetitionCard, TarjetaDestacada;

void main() {
  // ProviderScope guarda los providers de toda la app. Las pruebas montan su
  // propio ProviderScope con un repositorio falso (override).
  runApp(const ProviderScope(child: CompetihubApp()));
}

class CompetihubApp extends StatelessWidget {
  const CompetihubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompetiHub',
      theme: temaCompetihub(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
