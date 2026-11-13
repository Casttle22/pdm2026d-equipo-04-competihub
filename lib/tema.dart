import 'package:flutter/material.dart';

// Tema de CompetiHub: azul, en la línea de start.gg y Unstop, en modo claro y
// oscuro con la misma identidad.
//
// Claro: el esquema parte del azul de marca y fija ese azul exacto como color
// principal (con texto blanco encima da 5,7:1; WCAG AA pide 4,5:1).
// Oscuro: mismo color semilla; el principal es el azul claro que genera
// Material para fondo oscuro, porque el azul de marca no tiene contraste
// suficiente sobre gris oscuro. test/tema_test.dart comprueba los pares de
// color de los dos modos.
const Color azulCompetihub = Color(0xFF1565C0);

// Fondo de las pantallas en modo claro: gris azulado muy claro, para que las
// tarjetas blancas se distingan sin bordes.
const Color fondoApp = Color(0xFFF3F6FB);

// Radio de las tarjetas y de los campos.
const double radioTarjeta = 16;
const double radioCampo = 12;

// Sombra suave de las tarjetas en modo claro. En oscuro las tarjetas se
// distinguen por su tono, y la sombra casi no se ve.
const List<BoxShadow> sombraSuave = [
  BoxShadow(color: Color(0x14102A43), blurRadius: 12, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x0A102A43), blurRadius: 2, offset: Offset(0, 1)),
];
const List<BoxShadow> _sombraOscura = [
  BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
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

final ColorScheme esquemaOscuro = ColorScheme.fromSeed(
  seedColor: azulCompetihub,
  brightness: Brightness.dark,
);

// Ancho a partir del cual el Detalle pasa a dos columnas (tabletas y
// teléfonos en horizontal).
const double anchoDosColumnas = 600;

bool esOscuro(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

// Color de las tarjetas, los campos, la píldora y las barras: blanco en claro
// y un gris un poco más claro que el fondo en oscuro. Se calcula aquí y no
// solo con el tema para que las pantallas se vean igual en pruebas que las
// montan sin el tema de la app.
Color colorDeTarjeta(BuildContext context) => esOscuro(context)
    ? Theme.of(context).colorScheme.surfaceContainerHigh
    : Colors.white;

// Fondo de las pantallas.
Color colorDeFondo(BuildContext context) =>
    esOscuro(context) ? Theme.of(context).colorScheme.surface : fondoApp;

List<BoxShadow> sombraDeTarjeta(BuildContext context) =>
    esOscuro(context) ? _sombraOscura : sombraSuave;

ThemeData temaCompetihub() => _construirTema(
  scheme: esquemaDeColor,
  fondo: fondoApp,
  tarjeta: Colors.white,
);

ThemeData temaCompetihubOscuro() => _construirTema(
  scheme: esquemaOscuro,
  fondo: esquemaOscuro.surface,
  tarjeta: esquemaOscuro.surfaceContainerHigh,
);

ThemeData _construirTema({
  required ColorScheme scheme,
  required Color fondo,
  required Color tarjeta,
}) {
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
    scaffoldBackgroundColor: fondo,
    textTheme: texto,
    appBarTheme: AppBarTheme(
      backgroundColor: fondo,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
      titleTextStyle: texto.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: tarjeta,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: const Color(0x33102A43),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioTarjeta),
      ),
    ),
    // Campos con borde redondeado. Los mensajes de error y de ayuda pueden
    // ocupar varias líneas.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tarjeta,
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
        backgroundColor: tarjeta,
        textStyle: texto.labelLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tarjeta,
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

// Tarjeta con radio de 16 y sombra suave: blanca en claro y gris en oscuro.
// Se dibuja igual con o sin el tema de la app (algunas pruebas montan
// pantallas sueltas).
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
        color: colorDeTarjeta(context),
        borderRadius: BorderRadius.circular(radioTarjeta),
        boxShadow: sombraDeTarjeta(context),
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
