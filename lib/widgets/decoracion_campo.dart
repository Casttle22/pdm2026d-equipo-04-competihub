import 'package:flutter/material.dart';

import '../tema.dart';

// Decoración de los campos del formulario: borde redondeado (radio 12),
// fondo blanco y mensajes de error y ayuda de varias líneas. Se define aquí
// y no solo en el tema para que el formulario se vea igual en pruebas que lo
// montan sin el tema de la app.
//
// La etiqueta del campo no va dentro del borde sino encima (ver
// CampoConEtiqueta): dentro, con texto grande, «Fecha y hora de inicio *» se
// cortaba con «…» y no se sabía qué campo era.
InputDecoration decoracionCampo(
  BuildContext context, {
  String? etiqueta,
  String? sugerencia,
  String? ayuda,
  String? error,
  Widget? sufijo,
  bool habilitado = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder borde(Color color, [double ancho = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radioCampo),
        borderSide: BorderSide(color: color, width: ancho),
      );
  return InputDecoration(
    labelText: etiqueta,
    hintText: sugerencia,
    helperText: ayuda,
    errorText: error,
    suffixIcon: sufijo,
    enabled: habilitado,
    filled: true,
    fillColor: Colors.white,
    helperMaxLines: 6,
    errorMaxLines: 6,
    border: borde(scheme.outlineVariant),
    enabledBorder: borde(scheme.outlineVariant),
    focusedBorder: borde(scheme.primary, 2),
    errorBorder: borde(scheme.error),
    focusedErrorBorder: borde(scheme.error, 2),
  );
}

// Etiqueta en negrita encima del campo. Puede ocupar varias líneas y se une
// con el campo para que el lector de pantalla los anuncie juntos.
class CampoConEtiqueta extends StatelessWidget {
  const CampoConEtiqueta({
    super.key,
    required this.etiqueta,
    required this.child,
  });

  final String etiqueta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
