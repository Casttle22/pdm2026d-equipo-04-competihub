import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modo de color elegido: Sistema (por defecto), Claro u Oscuro.
//
// Por ahora vive solo en memoria: al cerrar la app vuelve a «Sistema».
// Recordarlo requiere guardarlo en el teléfono; queda pendiente de decidir
// cómo (ver docs/bitacora-ia.md).
class ModoTemaNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void cambiar(ThemeMode modo) => state = modo;
}

final modoTemaProvider = NotifierProvider<ModoTemaNotifier, ThemeMode>(
  ModoTemaNotifier.new,
);

extension EtiquetaModoTema on ThemeMode {
  String get etiqueta => switch (this) {
    ThemeMode.system => 'Sistema',
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Oscuro',
  };

  IconData get icono => switch (this) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}
