import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/competencia.dart';
import '../data/competencia_draft.dart';
import '../data/etapa.dart';
import '../tema.dart';
import '../widgets/decoracion_campo.dart';
import '../widgets/editor_etapas.dart';
import 'selector_ubicacion_screen.dart';

// Mismas categorías y modalidades que usan los datos actuales
// (lib/data/mock_competencias.dart) y los estilos del Feed y del Detalle.
const List<String> _categorias = ['Académica', 'Deportiva', 'Esports', 'Otras'];
const List<String> _modalidades = ['Presencial', 'Virtual', 'Híbrida'];

const String _campoObligatorio = 'Este campo es obligatorio.';

// Los mensajes de error pueden ocupar varias líneas (ver decoracionCampo):
// con una sola, en pantallas angostas o con texto grande se cortaban con «…».

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
  late final TextEditingController _equipoMinController;
  late final TextEditingController _equipoMaxController;
  late final TextEditingController _premiosController;
  late final TextEditingController _organizadorController;

  String? _categoria;
  String? _modalidad;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  DateTime? _fechaLimiteInscripcion;
  FormatoCompetencia? _formato;
  List<Etapa> _etapas = const [];
  LatLng? _punto;

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
    _equipoMinController = TextEditingController(
      text: initial?.tamanoEquipoMin?.toString(),
    );
    _equipoMaxController = TextEditingController(
      text: initial?.tamanoEquipoMax?.toString(),
    );
    _premiosController = TextEditingController(text: initial?.premios);
    _organizadorController = TextEditingController(text: initial?.organizador);
    _formato = initial?.formato;
    _etapas = initial?.etapas ?? const [];
    _punto = initial != null && initial.tieneCoordenadas
        ? LatLng(initial.latitud!, initial.longitud!)
        : null;
    _categoria = initial?.categoria;
    _modalidad = initial?.modalidad;
    _fechaInicio = initial?.fechaInicio;
    _fechaFin = initial?.fechaFin;
    _fechaLimiteInscripcion = initial?.fechaLimiteInscripcion;
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
    _equipoMinController.dispose();
    _equipoMaxController.dispose();
    _premiosController.dispose();
    _organizadorController.dispose();
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
        _equipoMinController.text !=
            (initial?.tamanoEquipoMin?.toString() ?? '') ||
        _equipoMaxController.text !=
            (initial?.tamanoEquipoMax?.toString() ?? '') ||
        _premiosController.text != (initial?.premios ?? '') ||
        _organizadorController.text != (initial?.organizador ?? '') ||
        _formato != initial?.formato ||
        !listasDeEtapasIguales(_etapas, initial?.etapas ?? const []) ||
        _punto?.latitude != initial?.latitud ||
        _punto?.longitude != initial?.longitud ||
        _categoria != initial?.categoria ||
        _modalidad != initial?.modalidad ||
        _fechaInicio != initial?.fechaInicio ||
        _fechaFin != initial?.fechaFin ||
        _fechaLimiteInscripcion != initial?.fechaLimiteInscripcion;
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

    final porEquipos = _formato == FormatoCompetencia.equipos;
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
      fechaLimiteInscripcion: _fechaLimiteInscripcion,
      formato: _formato,
      // El tamaño de equipo solo se guarda si el formato es por equipos.
      tamanoEquipoMin: porEquipos ? _entero(_equipoMinController.text) : null,
      tamanoEquipoMax: porEquipos ? _entero(_equipoMaxController.text) : null,
      premios: _opcionalONulo(_premiosController.text),
      organizador: _opcionalONulo(_organizadorController.text),
      etapas: _etapas,
      latitud: _punto?.latitude,
      longitud: _punto?.longitude,
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
        // Barra inferior fija con el botón de guardar, de ancho completo.
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A102A43),
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radioCampo),
                      ),
                    ),
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _esEdicion
                                ? 'Guardar cambios'
                                : 'Crear competencia',
                          ),
                  ),
                ],
              ),
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
      CampoConEtiqueta(
        etiqueta: 'Categoría *',
        child: DropdownButtonFormField<String>(
          key: const ValueKey('competition-form-categoria'),
          initialValue: _categoria,
          // Ocupa el ancho disponible en vez del ancho de la opción más larga,
          // que con texto grande no cabe en pantallas angostas.
          isExpanded: true,
          decoration: decoracionCampo(context),
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
      ),
      separacion,
      CampoConEtiqueta(
        etiqueta: 'Modalidad *',
        child: DropdownButtonFormField<String>(
          key: const ValueKey('competition-form-modalidad'),
          initialValue: _modalidad,
          isExpanded: true,
          decoration: decoracionCampo(context),
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
      const _Seccion(titulo: 'Fecha y hora'),
      _CampoFechaHora(
        key: const ValueKey('competition-form-fecha-inicio'),
        etiqueta: 'Fecha y hora de inicio *',
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
        etiqueta: 'Fecha y hora de fin (opcional)',
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
      const SizedBox(height: 24),
      const _Seccion(titulo: 'Ubicación'),
      _campoTexto(
        clave: 'ubicacion',
        controller: _ubicacionController,
        etiqueta: 'Ubicación *',
        obligatorio: true,
      ),
      separacion,
      _PuntoEnMapa(
        punto: _punto,
        habilitado: habilitado,
        onElegir: () async {
          final elegido = await Navigator.of(context).push<LatLng>(
            MaterialPageRoute(
              builder: (_) => SelectorUbicacionScreen(inicial: _punto),
            ),
          );
          if (elegido != null && mounted) {
            setState(() => _punto = elegido);
          }
        },
        onQuitar: () => setState(() => _punto = null),
      ),
      const SizedBox(height: 24),
      const _Seccion(titulo: 'Participación'),
      _CampoFechaHora(
        key: const ValueKey('competition-form-fecha-limite'),
        etiqueta: 'Límite de inscripción (opcional)',
        valor: _fechaLimiteInscripcion,
        habilitado: habilitado,
        onElegir: () async {
          final elegida = await _elegirFechaHora(
            _fechaLimiteInscripcion,
            sugerida: _fechaInicio,
          );
          if (elegida != null) {
            setState(() => _fechaLimiteInscripcion = elegida);
          }
        },
        onLimpiar: () => setState(() => _fechaLimiteInscripcion = null),
        ayuda: 'Hasta cuándo se puede inscribir alguien.',
        validator: (_) {
          final inicio = _fechaInicio;
          final limite = _fechaLimiteInscripcion;
          if (inicio != null && limite != null && limite.isAfter(inicio)) {
            return 'El límite de inscripción no puede ser posterior al '
                'inicio.';
          }
          return null;
        },
      ),
      separacion,
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
      const SizedBox(height: 24),
      const _Seccion(titulo: 'Formato y premios'),
      CampoConEtiqueta(
        etiqueta: 'Formato (opcional)',
        child: DropdownButtonFormField<FormatoCompetencia?>(
          key: const ValueKey('competition-form-formato'),
          initialValue: _formato,
          isExpanded: true,
          decoration: decoracionCampo(context),
          items: const [
            DropdownMenuItem(value: null, child: Text('Sin especificar')),
            DropdownMenuItem(
              value: FormatoCompetencia.individual,
              child: Text('Individual'),
            ),
            DropdownMenuItem(
              value: FormatoCompetencia.equipos,
              child: Text('Por equipos'),
            ),
          ],
          onChanged: habilitado
              ? (valor) => setState(() => _formato = valor)
              : null,
        ),
      ),
      if (_formato == FormatoCompetencia.equipos) ...[
        separacion,
        // Uno debajo del otro: con texto grande, dos campos lado a lado no
        // caben en 360 dp.
        _campoTexto(
          clave: 'equipo-min',
          controller: _equipoMinController,
          etiqueta: 'Mínimo de personas por equipo (opcional)',
          teclado: TextInputType.number,
          capitalizacion: TextCapitalization.none,
          validator: _validarTamano,
        ),
        separacion,
        _campoTexto(
          clave: 'equipo-max',
          controller: _equipoMaxController,
          etiqueta: 'Máximo de personas por equipo (opcional)',
          teclado: TextInputType.number,
          capitalizacion: TextCapitalization.none,
          validator: (valor) {
            final error = _validarTamano(valor);
            if (error != null) {
              return error;
            }
            final minimo = _entero(_equipoMinController.text);
            final maximo = _entero(valor ?? '');
            if (minimo != null && maximo != null && maximo < minimo) {
              return 'El máximo no puede ser menor que el mínimo.';
            }
            return null;
          },
        ),
      ],
      separacion,
      _campoTexto(
        clave: 'premios',
        controller: _premiosController,
        etiqueta: 'Premios (opcional)',
        multilinea: true,
      ),
      separacion,
      _campoTexto(
        clave: 'organizador',
        controller: _organizadorController,
        etiqueta: 'Organizador (opcional)',
      ),
      const SizedBox(height: 24),
      const _Seccion(titulo: 'Etapas y cronograma'),
      EditorEtapas(
        etapas: _etapas,
        habilitado: habilitado,
        fechaSugerida: _fechaInicio,
        onCambio: (etapas) => setState(() => _etapas = etapas),
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
    return CampoConEtiqueta(
      etiqueta: etiqueta,
      child: TextFormField(
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
        decoration: decoracionCampo(context, sugerencia: ayuda),
        validator:
            validator ??
            (obligatorio
                ? (valor) => (valor == null || valor.trim().isEmpty)
                      ? _campoObligatorio
                      : null
                : null),
      ),
    );
  }
}

int? _entero(String texto) => int.tryParse(texto.trim());

// Vacío es válido. Si hay texto, debe ser un número entero de 1 a 100.
String? _validarTamano(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return null;
  }
  final numero = int.tryParse(texto);
  if (numero == null || numero < 1 || numero > 100) {
    return 'Escribe un número entero entre 1 y 100.';
  }
  return null;
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
      child: Semantics(
        header: true,
        child: Text(
          titulo,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// Punto en el mapa (opcional): muestra si hay uno elegido y permite elegirlo
// en el mapa, cambiarlo o quitarlo.
class _PuntoEnMapa extends StatelessWidget {
  const _PuntoEnMapa({
    required this.punto,
    required this.habilitado,
    required this.onElegir,
    required this.onQuitar,
  });

  final LatLng? punto;
  final bool habilitado;
  final VoidCallback onElegir;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final punto = this.punto;
    return CampoConEtiqueta(
      etiqueta: 'Punto en el mapa (opcional)',
      child: InputDecorator(
        key: const ValueKey('competition-form-punto'),
        decoration: decoracionCampo(
          context,
          ayuda: 'Sirve para el mapa y para «Cómo llegar».',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(punto == null ? 'Sin punto elegido' : describirPunto(punto)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('competition-form-elegir-punto'),
                  onPressed: habilitado ? onElegir : null,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    punto == null ? 'Elegir en el mapa' : 'Cambiar punto',
                  ),
                ),
                if (punto != null)
                  TextButton.icon(
                    key: const ValueKey('competition-form-quitar-punto'),
                    onPressed: habilitado ? onQuitar : null,
                    icon: const Icon(Icons.clear),
                    label: const Text('Quitar punto'),
                  ),
              ],
            ),
          ],
        ),
      ),
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
        return CampoConEtiqueta(
          etiqueta: etiqueta,
          child: InkWell(
            onTap: habilitado ? onElegir : null,
            borderRadius: BorderRadius.circular(radioCampo),
            child: InputDecorator(
              isEmpty: actual == null,
              decoration: decoracionCampo(
                context,
                sugerencia: 'Elegir fecha y hora',
                habilitado: habilitado,
                error: field.errorText,
                ayuda: ayuda,
                sufijo: actual != null && onLimpiar != null
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
          ),
        );
      },
    );
  }
}

String _claveTexto(Key? key) => key is ValueKey<String> ? key.value : 'fecha';
