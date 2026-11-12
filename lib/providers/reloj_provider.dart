import 'package:flutter_riverpod/flutter_riverpod.dart';

// Hora actual para la interfaz («Faltan N días», «Finalizada»). Las pruebas
// lo reemplazan con una fecha fija:
// `relojProvider.overrideWithValue(() => DateTime(2026, 11, 10))`.
final relojProvider = Provider<DateTime Function()>((ref) => DateTime.now);
