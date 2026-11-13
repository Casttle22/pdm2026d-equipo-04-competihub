import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Ayudas para probar en un teléfono angosto (360 dp de ancho) y con el texto
// del sistema al doble de tamaño, que es el caso más exigente que soportamos.

void usarTelefono360(WidgetTester tester, {double alto = 780}) {
  tester.view.physicalSize = Size(360, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Para usar en `MaterialApp(builder: textoGrande)`.
Widget textoGrande(BuildContext context, Widget? child) {
  return MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  );
}
