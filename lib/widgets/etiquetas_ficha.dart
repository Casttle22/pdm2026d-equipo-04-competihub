import 'package:flutter/material.dart';

import '../data/competencia.dart';
import 'etiqueta.dart';

// Colores de las etiquetas de formato y modalidad de las maquetas:
// Individual lila, Equipos azul, Presencial verde, Virtual rojo e Híbrida
// naranja. En modo oscuro cada una tiene su par: texto claro sobre un fondo
// oscuro del mismo tono. Cada texto alcanza contraste AA (4,5:1) sobre su
// fondo en los dos modos; lo comprueba test/tema_test.dart.
class ColoresEtiqueta {
  const ColoresEtiqueta({
    required this.texto,
    required this.fondo,
    required this.icono,
  });

  final Color texto;
  final Color fondo;
  final IconData icono;
}

const ColoresEtiqueta coloresIndividual = ColoresEtiqueta(
  texto: Color(0xFF6A1B9A),
  fondo: Color(0xFFF3E5F5),
  icono: Icons.person_outline,
);
const ColoresEtiqueta coloresEquipos = ColoresEtiqueta(
  texto: Color(0xFF0D47A1),
  fondo: Color(0xFFE3F2FD),
  icono: Icons.groups_outlined,
);
const ColoresEtiqueta coloresPresencial = ColoresEtiqueta(
  texto: Color(0xFF1B5E20),
  fondo: Color(0xFFE8F5E9),
  icono: Icons.place_outlined,
);
const ColoresEtiqueta coloresVirtual = ColoresEtiqueta(
  texto: Color(0xFFB71C1C),
  fondo: Color(0xFFFFEBEE),
  icono: Icons.wifi,
);
const ColoresEtiqueta coloresHibrida = ColoresEtiqueta(
  texto: Color(0xFF8A4B00),
  fondo: Color(0xFFFFF3E0),
  icono: Icons.sync_alt,
);

const ColoresEtiqueta coloresIndividualOscuro = ColoresEtiqueta(
  texto: Color(0xFFE1BEE7),
  fondo: Color(0xFF3B2148),
  icono: Icons.person_outline,
);
const ColoresEtiqueta coloresEquiposOscuro = ColoresEtiqueta(
  texto: Color(0xFFBBDEFB),
  fondo: Color(0xFF1A3557),
  icono: Icons.groups_outlined,
);
const ColoresEtiqueta coloresPresencialOscuro = ColoresEtiqueta(
  texto: Color(0xFFC8E6C9),
  fondo: Color(0xFF1E3B22),
  icono: Icons.place_outlined,
);
const ColoresEtiqueta coloresVirtualOscuro = ColoresEtiqueta(
  texto: Color(0xFFFFCDD2),
  fondo: Color(0xFF4A1F22),
  icono: Icons.wifi,
);
const ColoresEtiqueta coloresHibridaOscuro = ColoresEtiqueta(
  texto: Color(0xFFFFCC80),
  fondo: Color(0xFF45300F),
  icono: Icons.sync_alt,
);

ColoresEtiqueta coloresDeModalidad(String modalidad, {bool oscuro = false}) =>
    switch (modalidad) {
      'Presencial' => oscuro ? coloresPresencialOscuro : coloresPresencial,
      'Virtual' => oscuro ? coloresVirtualOscuro : coloresVirtual,
      _ => oscuro ? coloresHibridaOscuro : coloresHibrida,
    };

ColoresEtiqueta coloresDeFormato(
  FormatoCompetencia formato, {
  bool oscuro = false,
}) => switch (formato) {
  FormatoCompetencia.individual =>
    oscuro ? coloresIndividualOscuro : coloresIndividual,
  FormatoCompetencia.equipos => oscuro ? coloresEquiposOscuro : coloresEquipos,
};

bool _oscuro(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

// «Individual» o «Equipos» (sin dibujar nada si el formato no se conoce).
class EtiquetaDeFormato extends StatelessWidget {
  const EtiquetaDeFormato({super.key, required this.formato});

  final FormatoCompetencia formato;

  @override
  Widget build(BuildContext context) {
    final colores = coloresDeFormato(formato, oscuro: _oscuro(context));
    return Etiqueta(
      texto: formato == FormatoCompetencia.equipos ? 'Equipos' : 'Individual',
      icono: colores.icono,
      colorTexto: colores.texto,
      colorFondo: colores.fondo,
    );
  }
}

class EtiquetaDeModalidad extends StatelessWidget {
  const EtiquetaDeModalidad({super.key, required this.modalidad});

  final String modalidad;

  @override
  Widget build(BuildContext context) {
    final colores = coloresDeModalidad(modalidad, oscuro: _oscuro(context));
    return Etiqueta(
      texto: modalidad,
      icono: colores.icono,
      colorTexto: colores.texto,
      colorFondo: colores.fondo,
    );
  }
}
