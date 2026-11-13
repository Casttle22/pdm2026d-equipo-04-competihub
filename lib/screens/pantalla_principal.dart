import 'package:flutter/material.dart';

import 'explorar_screen.dart';
import 'inicio_screen.dart';
import 'mapa_screen.dart';
import 'mis_eventos_screen.dart';

// Pestañas de la barra inferior, en orden. No hay «Perfil»: la app no
// tiene cuentas.
enum Seccion { inicio, explorar, mapa, misEventos }

// Pantalla principal con la barra inferior. Las cuatro secciones viven en un
// IndexedStack: al cambiar de pestaña no se destruyen, así que cada una
// conserva su estado (búsqueda, filtros, posición de la lista, mapa).
//
// El Detalle y el formulario se abren encima de toda la pantalla (sobre la
// barra), con el navegador principal; así el botón Atrás del sistema se
// comporta como siempre.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, this.seccionInicial = Seccion.inicio});

  final Seccion seccionInicial;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late Seccion _seccion = widget.seccionInicial;

  void _ir(Seccion seccion) => setState(() => _seccion = seccion);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _seccion.index,
        children: [
          HomeScreen(onVerTodos: () => _ir(Seccion.explorar)),
          const ExplorarScreen(),
          const MapaScreen(),
          MisEventosScreen(onExplorar: () => _ir(Seccion.explorar)),
        ],
      ),
      // Con texto muy grande, los rótulos de la barra se limitan a 1,1×:
      // con cuatro pestañas a 360 dp, «Mis eventos» se partía en dos líneas.
      // Los íconos y el resto de la app siguen la escala del sistema.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: NavigationBar(
          key: const ValueKey('barra-inferior'),
          selectedIndex: _seccion.index,
          onDestinationSelected: (indice) {
            setState(() => _seccion = Seccion.values[indice]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.saved_search),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Mis eventos',
            ),
          ],
        ),
      ),
    );
  }
}
