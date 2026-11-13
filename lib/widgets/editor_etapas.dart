import 'package:flutter/material.dart';

import '../data/etapa.dart';
import '../utils/fechas.dart';
import 'decoracion_campo.dart';

// Editor del cronograma dentro del formulario: agregar, editar, reordenar y
// quitar etapas. Reordenar usa botones Subir y Bajar en vez de arrastrar,
// porque arrastrar no es accesible con lector de pantalla ni cómodo con
// texto grande. La lista vive en el formulario; este widget solo avisa de
// los cambios con onCambio.
class EditorEtapas extends StatelessWidget {
  const EditorEtapas({
    super.key,
    required this.etapas,
    required this.onCambio,
    required this.habilitado,
    this.fechaSugerida,
  });

  final List<Etapa> etapas;
  final ValueChanged<List<Etapa>> onCambio;
  final bool habilitado;

  // Punto de partida de los selectores para una etapa nueva (el inicio).
  final DateTime? fechaSugerida;

  Future<void> _agregar(BuildContext context) async {
    final nueva = await mostrarDialogoEtapa(
      context,
      fechaSugerida: etapas.isEmpty ? fechaSugerida : etapas.last.fechaHora,
    );
    if (nueva != null) {
      onCambio([...etapas, nueva]);
    }
  }

  Future<void> _editar(BuildContext context, int indice) async {
    final editada = await mostrarDialogoEtapa(context, inicial: etapas[indice]);
    if (editada != null) {
      onCambio([...etapas]..[indice] = editada);
    }
  }

  void _mover(int desde, int hacia) {
    final lista = [...etapas];
    final etapa = lista.removeAt(desde);
    lista.insert(hacia, etapa);
    onCambio(lista);
  }

  void _quitar(int indice) {
    onCambio([...etapas]..removeAt(indice));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (etapas.isEmpty)
          Text(
            'Sin etapas. Agrega las fases del evento (por ejemplo, '
            'clasificatoria y final) para mostrar un cronograma.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        for (var i = 0; i < etapas.length; i++)
          Card(
            key: ValueKey('editor-etapa-$i'),
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${etapas[i].nombre}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatearFechaHoraLegible(etapas[i].fechaHora),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  // Los botones pasan a otra línea si no caben.
                  Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      IconButton(
                        key: ValueKey('editor-etapa-$i-subir'),
                        tooltip: 'Subir «${etapas[i].nombre}»',
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: habilitado && i > 0
                            ? () => _mover(i, i - 1)
                            : null,
                      ),
                      IconButton(
                        key: ValueKey('editor-etapa-$i-bajar'),
                        tooltip: 'Bajar «${etapas[i].nombre}»',
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: habilitado && i < etapas.length - 1
                            ? () => _mover(i, i + 1)
                            : null,
                      ),
                      IconButton(
                        key: ValueKey('editor-etapa-$i-editar'),
                        tooltip: 'Editar «${etapas[i].nombre}»',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: habilitado
                            ? () => _editar(context, i)
                            : null,
                      ),
                      IconButton(
                        key: ValueKey('editor-etapa-$i-quitar'),
                        tooltip: 'Quitar «${etapas[i].nombre}»',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: habilitado ? () => _quitar(i) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('editor-etapa-agregar'),
            onPressed: habilitado ? () => _agregar(context) : null,
            icon: const Icon(Icons.add),
            label: const Text('Agregar etapa'),
          ),
        ),
      ],
    );
  }
}

// Diálogo para crear o editar una etapa. Devuelve null si se cancela.
Future<Etapa?> mostrarDialogoEtapa(
  BuildContext context, {
  Etapa? inicial,
  DateTime? fechaSugerida,
}) {
  return showDialog<Etapa>(
    context: context,
    builder: (_) =>
        _DialogoEtapa(inicial: inicial, fechaSugerida: fechaSugerida),
  );
}

class _DialogoEtapa extends StatefulWidget {
  const _DialogoEtapa({this.inicial, this.fechaSugerida});

  final Etapa? inicial;
  final DateTime? fechaSugerida;

  @override
  State<_DialogoEtapa> createState() => _DialogoEtapaState();
}

class _DialogoEtapaState extends State<_DialogoEtapa> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  DateTime? _fechaHora;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.inicial?.nombre);
    _descripcion = TextEditingController(text: widget.inicial?.descripcion);
    _fechaHora = widget.inicial?.fechaHora;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final base = _fechaHora ?? widget.fechaSugerida ?? DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) {
      return;
    }
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (hora == null) {
      return;
    }
    setState(() {
      _fechaHora = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  void _aceptar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final descripcion = _descripcion.text.trim();
    Navigator.of(context).pop(
      Etapa(
        nombre: _nombre.text.trim(),
        fechaHora: _fechaHora!,
        descripcion: descripcion.isEmpty ? null : descripcion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fecha = _fechaHora;
    return AlertDialog(
      title: Text(widget.inicial == null ? 'Nueva etapa' : 'Editar etapa'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('etapa-nombre'),
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: decoracionCampo(context, etiqueta: 'Nombre *'),
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'Escribe el nombre de la etapa.'
                  : null,
            ),
            const SizedBox(height: 12),
            FormField<DateTime>(
              validator: (_) =>
                  _fechaHora == null ? 'Elige la fecha y la hora.' : null,
              builder: (campo) => InkWell(
                key: const ValueKey('etapa-fecha'),
                onTap: _elegirFecha,
                child: InputDecorator(
                  isEmpty: fecha == null,
                  decoration: decoracionCampo(
                    context,
                    etiqueta: 'Fecha y hora *',
                    error: campo.errorText,
                    sufijo: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    fecha == null ? '' : formatearFechaHoraLegible(fecha),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('etapa-descripcion'),
              controller: _descripcion,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: decoracionCampo(
                context,
                etiqueta: 'Descripción (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('etapa-aceptar'),
          onPressed: _aceptar,
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
