import 'package:flutter/material.dart';

// Tema de CompetiHub: azul, en la línea de start.gg y Unstop.
//
// El esquema parte del azul de marca. `fromSeed` suaviza el color principal,
// así que se fija el azul exacto: con texto blanco encima da un contraste de
// 5,7:1 (WCAG AA pide 4,5:1). test/tema_test.dart comprueba los pares de
// color que usa la interfaz.
const Color azulCompetihub = Color(0xFF1565C0);

// Fondo de las pantallas: gris azulado muy claro, para que las tarjetas
// blancas se distingan sin bordes.
const Color fondoApp = Color(0xFFF3F6FB);

// Radio de las tarjetas y de los campos.
const double radioTarjeta = 16;
const double radioCampo = 12;

// Sombra suave de las tarjetas blancas.
const List<BoxShadow> sombraSuave = [
  BoxShadow(color: Color(0x14102A43), blurRadius: 12, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x0A102A43), blurRadius: 2, offset: Offset(0, 1)),
];

final ColorScheme esquemaDeColor =
    ColorScheme.fromSeed(
      seedColor: azulCompetihub,
      brightness: Brightness.light,
    ).copyWith(
      primary: azulCompetihub,
      onPrimary: Colors.white,
      surface: Colors.white,
    );

// Ancho a partir del cual el Detalle pasa a dos columnas (tabletas y
// teléfonos en horizontal).
const double anchoDosColumnas = 600;

ThemeData temaCompetihub() {
  final scheme = esquemaDeColor;
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  // Títulos y rótulos en negrita, como en las maquetas.
  final texto = base.textTheme.copyWith(
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleSmall: base.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    ),
  );
  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radioCampo),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );
  final formaBoton = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radioCampo),
  );
  return base.copyWith(
    scaffoldBackgroundColor: fondoApp,
    textTheme: texto,
    appBarTheme: AppBarTheme(
      backgroundColor: fondoApp,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
      titleTextStyle: texto.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: const Color(0x33102A43),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioTarjeta),
      ),
    ),
    // Campos con borde redondeado y fondo blanco. Los mensajes de error y de
    // ayuda pueden ocupar varias líneas.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorMaxLines: 6,
      helperMaxLines: 6,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: formaBoton,
        textStyle: texto.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: formaBoton,
        backgroundColor: Colors.white,
        textStyle: texto.labelLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => texto.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: estados.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

// Tarjeta blanca con radio de 16 y sombra suave. Se dibuja igual con o sin el
// tema de la app (algunas pruebas montan pantallas sueltas).
class TarjetaBlanca extends StatelessWidget {
  const TarjetaBlanca({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final contenido = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radioTarjeta),
        boxShadow: sombraSuave,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radioTarjeta),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? contenido
            : InkWell(onTap: onTap, child: contenido),
      ),
    );
  }
}
