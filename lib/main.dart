import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/tema_provider.dart';
import 'screens/pantalla_principal.dart';
import 'tema.dart';

// La pantalla principal, el Inicio y sus tarjetas viven en sus propios
// archivos. Se reexportan porque son parte de la interfaz pública de la app
// que usan las pruebas.
export 'screens/inicio_screen.dart' show HomeScreen;
export 'screens/pantalla_principal.dart' show PantallaPrincipal, Seccion;
export 'widgets/tarjeta_competencia.dart'
    show CompetitionCard, TarjetaDestacada;

void main() {
  // En escritorio, sqflite necesita su variante FFI. En Android e iOS se usa el
  // plugin nativo y este bloque no hace nada.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // ProviderScope guarda los providers de toda la app. Las pruebas montan su
  // propio ProviderScope con un repositorio falso (override).
  runApp(const ProviderScope(child: CompetihubApp()));
}

// Tema claro y oscuro con la misma identidad. Por defecto sigue la
// configuración del sistema; el selector del Inicio permite fijar uno.
class CompetihubApp extends ConsumerWidget {
  const CompetihubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CompetiHub',
      theme: temaCompetihub(),
      darkTheme: temaCompetihubOscuro(),
      themeMode: ref.watch(modoTemaProvider),
      home: const PantallaPrincipal(),
      debugShowCheckedModeBanner: false,
    );
  }
}
