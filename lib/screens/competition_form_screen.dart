import 'package:flutter/material.dart';

import '../data/competencia.dart';
import '../data/competencia_draft.dart';

// Mismas categorías y modalidades que usan los datos actuales
// (lib/data/mock_competencias.dart) y los estilos del Feed y del Detalle.
const List<String> _categorias = ['Académica', 'Deportiva', 'Esports', 'Otras'];
const List<String> _modalidades = ['Presencial', 'Virtual', 'Híbrida'];

const String _campoObligatorio = 'Este campo es obligatorio.';

// Los mensajes de error pueden ocupar varias líneas. Con una sola (el valor
// por defecto), en pantallas angostas o con texto grande se cortaban con «…»
// y no se leía qué faltaba.
const int _lineasDeError = 6;

// Formulario reutilizable para crear (initial == null) o editar una
// competencia. No guarda nada por sí mismo: arma un CompetenciaDraft y se lo
// entrega a onSave. Si onSave termina bien, cierra la pantalla; si lanza una
// excepción, conserva lo escrito y permite reintentar.
//
// Cuida dos casos en que se pierde trabajo: si la validación falla, lleva la
// pantalla al primer campo con error; y si se intenta salir con cambios sin
// guardar, pregunta antes de descartarlos.
class CompetitionFormScreen extends StatefulWidget {
  const CompetitionFormScreen({
    super.key,
    this.initial,
    required this.onSave,
    this.ahora,
  });

  final Competencia? initial;
  final Future<void> Function(CompetenciaDraft) onSave;

  // Hora actual, para avisar si el inicio elegido ya pasó. Las pruebas
  // pueden fijarla; por defecto es DateTime.now.
  final DateTime Function()? ahora;

  @override
  State<CompetitionFormScreen> createState() => _CompetitionFormScreenState();
}

class _CompetitionFormScreenState extends State<CompetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _reglasController;
  late final TextEditingController _costoController;
  late final TextEditingController _instruccionesController;
  late final TextEditingController _inscripcionUrlController;
  late final TextEditingController _contactoController;
  late final TextEditingController _imagenUrlController;

  String? _categoria;
  String? _modalidad;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool _guardando = false;
  String? _errorGuardado;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _esEdicion => widget.initial != null;

  bool get _inicioYaPaso {
    final inicio = _fechaInicio;
    if (inicio == null) {
      return false;
    }
    final ahora = (widget.ahora ?? DateTime.now)();
    return inicio.isBefore(ahora);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _tituloController = TextEditingController(text: initial?.titulo);
    _ubicacionController = TextEditingController(text: initial?.ubicacion);
    _descripcionController = TextEditingController(text: initial?.descripcion);
    _reglasController = TextEditingController(text: initial?.reglas);
    _costoController = TextEditingController(text: initial?.costo);
    _instruccionesController = TextEditingController(
      text: initial?.instruccionesParticipacion,
    );
    _inscripcionUrlController = TextEditingController(
      text: initial?.inscripcionUrl,
    );
    _contactoController = TextEditingController(text: initial?.contacto);
    _imagenUrlController = TextEditingController(text: initial?.imagenUrl);
    _categoria = initial?.categoria;
    _modalidad = initial?.modalidad;
    _fechaInicio = initial?.fechaInicio;
    _fechaFin = initial?.fechaFin;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _ubicacionController.dispose();
    _descripcionController.dispose();
    _reglasController.dispose();
    _costoController.dispose();
    _instruccionesController.dispose();
    _inscripcionUrlController.dispose();
    _contactoController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  // Si se edita una competencia con un valor que no está en la lista
  // (por ejemplo, datos antiguos), se agrega para no perderlo.
  List<String> _opcionesCon(List<String> base, String? actual) {
    if (actual == null || base.contains(actual)) {
      return base;
    }
    return [...base, actual];
  }

  // `actual` es el valor que ya tiene el campo; `sugerida` solo sirve como
  // punto de partida de los selectores cuando el campo está vacío.
  Future<DateTime?> _elegirFechaHora(
    DateTime? actual, {
    DateTime? sugerida,
  }) async {
    final base = actual ?? sugerida ?? DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) {
      return null;
    }
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (hora == null) {
      // Se canceló la hora. Si el campo ya tenía un valor, se conserva la
      // fecha recién elegida con la hora anterior; si estaba vacío, no se
      // inventa una hora.
      if (actual == null) {
        return null;
      }
      return DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        actual.hour,
        actual.minute,
      );
    }
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  // Compara lo que hay en pantalla con los datos iniciales.
  bool _hayCambios() {
    final initial = widget.initial;
    return _tituloController.text != (initial?.titulo ?? '') ||
        _ubicacionController.text != (initial?.ubicacion ?? '') ||
        _descripcionController.text != (initial?.descripcion ?? '') ||
        _reglasController.text != (initial?.reglas ?? '') ||
        _costoController.text != (initial?.costo ?? '') ||
        _instruccionesController.text !=
            (initial?.instruccionesParticipacion ?? '') ||
        _inscripcionUrlController.text != (initial?.inscripcionUrl ?? '') ||
        _contactoController.text != (initial?.contacto ?? '') ||
        _imagenUrlController.text != (initial?.imagenUrl ?? '') ||
        _categoria != initial?.categoria ||
        _modalidad != initial?.modalidad ||
        _fechaInicio != initial?.fechaInicio ||
        _fechaFin != initial?.fechaFin;
  }

  // Atrás (botón de la barra o del sistema): sale directo si no hay cambios;
  // si los hay, pregunta antes de descartarlos.
  Future<void> _intentarSalir() async {
    if (_guardando) {
      return;
    }
    final navigator = Navigator.of(context);
    if (!_hayCambios()) {
      navigator.pop();
      return;
    }
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Lo que escribiste todavía no se ha guardado.'),
        actions: [
          TextButton(
            key: const ValueKey('competition-form-discard-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            key: const ValueKey('competition-form-discard-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) {
      navigator.pop();
    }
  }

  // Desplaza la pantalla hasta el campo con error que esté más arriba.
  void _mostrarPrimerError(Set<FormFieldState<Object?>> invalidos) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      BuildContext? destino;
      double? menorY;
      for (final campo in invalidos) {
        if (!campo.mounted) {
          continue;
        }
        final render = campo.context.findRenderObject();
        if (render is! RenderBox || !render.hasSize) {
          continue;
        }
        final y = render.localToGlobal(Offset.zero).dy;
        if (menorY == null || y < menorY) {
          menorY = y;
          destino = campo.context;
        }
      }
      if (destino != null) {
        Scrollable.ensureVisible(
          destino,
          alignment: 0.1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _guardar() async {
    // Evita el doble envío: mientras se espera onSave, se ignoran los toques.
    if (_guardando) {
      return;
    }
    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }
    final invalidos = formState.validateGranularly();
    if (invalidos.isNotEmpty) {
      setState(() {
        _autovalidateMode = AutovalidateMode.always;
        _errorGuardado = null;
      });
      _mostrarPrimerError(invalidos);
      return;
    }

    final draft = CompetenciaDraft(
      titulo: _tituloController.text.trim(),
      categoria: _categoria!,
      fechaInicio: _fechaInicio!,
      ubicacion: _ubicacionController.text.trim(),
      modalidad: _modalidad!,
      descripcion: _descripcionController.text.trim(),
      reglas: _reglasController.text.trim(),
      costo: _costoController.text.trim(),
      instruccionesParticipacion: _instruccionesController.text.trim(),
      fechaFin: _fechaFin,
      inscripcionUrl: _opcionalONulo(_inscripcionUrlController.text),
      contacto: _opcionalONulo(_contactoController.text),
      imagenUrl: _opcionalONulo(_imagenUrlController.text),
    );

    setState(() {
      _guardando = true;
      _errorGuardado = null;
    });

    try {
      await widget.onSave(draft);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _guardando = false;
        _errorGuardado =
            'No se pudo guardar la competencia. Tus datos siguen aquí; '
            'inténtalo de nuevo.';
      });
      return;
    }

    if (!mounted) {
      return;
    }
    // _guardando se queda en true para que no se pueda tocar nada mientras
    // se cierra la pantalla.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Siempre se intercepta el regreso: _intentarSalir decide si sale
      // directo, pregunta por los cambios o espera a que termine de guardar.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _intentarSalir();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_esEdicion ? 'Editar competencia' : 'Nueva competencia'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _campos(context),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorGuardado != null) ...[
                  _MensajeError(texto: _errorGuardado!),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  key: const ValueKey('competition-form-save'),
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_esEdicion ? 'Guardar cambios' : 'Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _campos(BuildContext context) {
    const separacion = SizedBox(height: 16);
    final habilitado = !_guardando;
    return [
      const _Seccion(titulo: 'Información general'),
      _campoTexto(
        clave: 'titulo',
        controller: _tituloController,
        etiqueta: 'Título *',
        obligatorio: true,
      ),
      separacion,
      DropdownButtonFormField<String>(
        key: const ValueKey('competition-form-categoria'),
        initialValue: _categoria,
        // Ocupa el ancho disponible en vez del ancho de la opción más larga,
        // que con texto grande no cabe en pantallas angostas.
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Categoría *',
          errorMaxLines: _lineasDeError,
          border: OutlineInputBorder(),
        ),
        items: _opcionesCon(
          _categorias,
          widget.initial?.categoria,
        ).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: habilitado
            ? (valor) => setState(() => _categoria = valor)
            : null,
        validator: (valor) =>
            valor == null ? 'Selecciona una categoría.' : null,
      ),
      separacion,
      DropdownButtonFormField<String>(
        key: const ValueKey('competition-form-modalidad'),
        initialValue: _modalidad,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Modalidad *',
          errorMaxLines: _lineasDeError,
          border: OutlineInputBorder(),
        ),
        items: _opcionesCon(
          _modalidades,
          widget.initial?.modalidad,
        ).map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: habilitado
            ? (valor) => setState(() => _modalidad = valor)
            : null,
        validator: (valor) =>
            valor == null ? 'Selecciona una modalidad.' : null,
      ),
      separacion,
      _CampoFechaHora(
        key: const ValueKey('competition-form-fecha-inicio'),
        etiqueta: 'Inicio *',
        valor: _fechaInicio,
        habilitado: habilitado,
        onElegir: () async {
          final elegida = await _elegirFechaHora(_fechaInicio);
          if (elegida != null) {
            setState(() => _fechaInicio = elegida);
          }
        },
        // Aviso que no bloquea: se puede registrar un evento ya ocurrido.
        ayuda: _inicioYaPaso ? 'Esta fecha ya pasó.' : null,
        validator: (_) =>
            _fechaInicio == null ? 'Selecciona la fecha de inicio.' : null,
      ),
      separacion,
      _CampoFechaHora(
        key: const ValueKey('competition-form-fecha-fin'),
        etiqueta: 'Fin (opcional)',
        valor: _fechaFin,
        habilitado: habilitado,
        onElegir: () async {
          final elegida = await _elegirFechaHora(
            _fechaFin,
            sugerida: _fechaInicio,
          );
          if (elegida != null) {
            setState(() => _fechaFin = elegida);
          }
        },
        onLimpiar: () => setState(() => _fechaFin = null),
        validator: (_) {
          final inicio = _fechaInicio;
          final fin = _fechaFin;
          if (inicio != null && fin != null && fin.isBefore(inicio)) {
            return 'El fin debe ser igual o posterior al inicio.';
          }
          return null;
        },
      ),
      separacion,
      _campoTexto(
        clave: 'ubicacion',
        controller: _ubicacionController,
        etiqueta: 'Ubicación *',
        obligatorio: true,
      ),
      separacion,
      _campoTexto(
        clave: 'descripcion',
        controller: _descripcionController,
        etiqueta: 'Descripción *',
        obligatorio: true,
        multilinea: true,
      ),
      const SizedBox(height: 24),
      const _Seccion(titulo: 'Información para participar'),
      _campoTexto(
        clave: 'reglas',
        controller: _reglasController,
        etiqueta: 'Reglas *',
        obligatorio: true,
        multilinea: true,
      ),
      separacion,
      _campoTexto(
        clave: 'costo',
        controller: _costoController,
        etiqueta: 'Costo *',
        ayuda: 'Texto libre. Ej.: Gratis o Q50 por equipo',
        obligatorio: true,
      ),
      separacion,
      _campoTexto(
        clave: 'instrucciones',
        controller: _instruccionesController,
        etiqueta: 'Instrucciones para participar *',
        obligatorio: true,
        multilinea: true,
      ),
      separacion,
      _campoTexto(
        clave: 'inscripcion-url',
        controller: _inscripcionUrlController,
        etiqueta: 'Enlace de inscripción (opcional)',
        ayuda: 'https://…',
        teclado: TextInputType.url,
        capitalizacion: TextCapitalization.none,
        validator: _validarEnlaceOpcional,
      ),
      separacion,
      _campoTexto(
        clave: 'contacto',
        controller: _contactoController,
        etiqueta: 'Contacto (opcional)',
        capitalizacion: TextCapitalization.none,
      ),
      separacion,
      _campoTexto(
        clave: 'imagen-url',
        controller: _imagenUrlController,
        etiqueta: 'Enlace de imagen (opcional)',
        ayuda: 'https://…',
        teclado: TextInputType.url,
        capitalizacion: TextCapitalization.none,
        validator: _validarEnlaceOpcional,
      ),
      const SizedBox(height: 8),
      Text('* Campo obligatorio', style: Theme.of(context).textTheme.bodySmall),
    ];
  }

  Widget _campoTexto({
    required String clave,
    required TextEditingController controller,
    required String etiqueta,
    String? ayuda,
    bool obligatorio = false,
    bool multilinea = false,
    TextInputType? teclado,
    TextCapitalization capitalizacion = TextCapitalization.sentences,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      key: ValueKey('competition-form-$clave'),
      controller: controller,
      enabled: !_guardando,
      textCapitalization: capitalizacion,
      keyboardType: multilinea ? TextInputType.multiline : teclado,
      minLines: multilinea ? 2 : 1,
      maxLines: multilinea ? 5 : 1,
      textInputAction: multilinea
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: ayuda,
        errorMaxLines: _lineasDeError,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (obligatorio
              ? (valor) => (valor == null || valor.trim().isEmpty)
                    ? _campoObligatorio
                    : null
              : null),
    );
  }
}

String? _opcionalONulo(String texto) {
  final limpio = texto.trim();
  return limpio.isEmpty ? null : limpio;
}

// Vacío es válido (el campo es opcional). Si hay texto, debe ser un enlace
// http o https con host, por ejemplo https://example.com/inscripcion.
String? _validarEnlaceOpcional(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(texto);
  final esValido =
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
  return esValido
      ? null
      : 'Ingresa un enlace válido que empiece con http:// o https://.';
}

String _formatearFechaHora(DateTime fecha) {
  String dosDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year} '
      'a las ${dosDigitos(fecha.hour)}:${dosDigitos(fecha.minute)}';
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('competition-form-error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// Campo de fecha y hora. El valor vive en el State del formulario; este
// FormField solo lo muestra y ejecuta el validador que recibe.
class _CampoFechaHora extends StatelessWidget {
  const _CampoFechaHora({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.habilitado,
    required this.onElegir,
    required this.validator,
    this.onLimpiar,
    this.ayuda,
  });

  final String etiqueta;
  final DateTime? valor;
  final bool habilitado;
  final VoidCallback onElegir;
  final VoidCallback? onLimpiar;
  final FormFieldValidator<DateTime> validator;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: validator,
      builder: (field) {
        final actual = valor;
        return InkWell(
          onTap: habilitado ? onElegir : null,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            isEmpty: actual == null,
            decoration: InputDecoration(
              labelText: etiqueta,
              enabled: habilitado,
              errorText: field.errorText,
              helperText: ayuda,
              helperMaxLines: _lineasDeError,
              errorMaxLines: _lineasDeError,
              border: const OutlineInputBorder(),
              suffixIcon: actual != null && onLimpiar != null
                  ? IconButton(
                      key: ValueKey('${_claveTexto(key)}-limpiar'),
                      tooltip: 'Quitar fecha',
                      icon: const Icon(Icons.clear),
                      onPressed: habilitado ? onLimpiar : null,
                    )
                  : const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(actual == null ? '' : _formatearFechaHora(actual)),
          ),
        );
      },
    );
  }
}

String _claveTexto(Key? key) => key is ValueKey<String> ? key.value : 'fecha';
