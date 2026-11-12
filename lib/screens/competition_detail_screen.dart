import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/competencia.dart';
import '../providers/competencias_providers.dart';
import '../providers/reloj_provider.dart';
import '../tema.dart';
import '../utils/fechas.dart';
import '../servicios/abridor_de_mapas.dart';
import '../widgets/boton_como_llegar.dart';
import '../widgets/boton_guardar.dart';
import '../widgets/categoria_estilo.dart';
import '../widgets/competition_delete_dialog.dart';
import '../widgets/etiqueta.dart';
import '../widgets/imagen_competencia.dart';
import '../widgets/linea_de_tiempo.dart';
import '../widgets/mapa_base.dart';
import '../widgets/tarjeta_competencia.dart';
import 'competition_form_screen.dart';

// Detalle de una competencia (S14): consulta por id con cuatro estados.
// - Cargando: indicador de progreso.
// - Error: mensaje para personas y Reintentar, que vuelve a consultar.
// - No encontrada (null): texto y acción para volver. No es un error.
// - Datos: el contenido informativo del Issue #9.
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  const CompetitionDetailScreen({super.key, required this.competitionId});

  final String competitionId;

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {
  bool _eliminando = false;

  Future<void> _eliminar(Competencia competencia) async {
    // El mensaje de confirmación se muestra en la pantalla anterior, por eso
    // se toman el navegador y el mensajero antes de cerrar esta.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await showCompetitionDeleteDialog(context, competencia.titulo) ||
        !mounted) {
      return;
    }
    setState(() => _eliminando = true);
    try {
      await ref.read(competenciasActionsProvider).eliminar(competencia.id);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Competencia eliminada.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la competencia.')),
      );
    }
  }

  // Abre el formulario de edición y confirma con un mensaje si se guardó.
  Future<void> _editar(Competencia competencia) async {
    final actions = ref.read(competenciasActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    var guardada = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CompetitionFormScreen(
          initial: competencia,
          onSave: (draft) async {
            await actions.actualizar(competencia.id, draft);
            guardada = true;
          },
        ),
      ),
    );
    if (guardada) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cambios guardados.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitionId = widget.competitionId;
    final competenciaAsync = ref.watch(competenciaPorIdProvider(competitionId));
    final competencia = competenciaAsync.asData?.value;
    final ahora = ref.watch(relojProvider)();

    return PopScope(
      canPop: !_eliminando,
      child: Scaffold(
        appBar: AppBar(
          // Título corto: con texto grande, «Detalle de competencia» se
          // cortaba al compartir la barra con los botones.
          title: const Text('Detalle'),
          scrolledUnderElevation: 1,
          actions: [
            if (competencia != null) ...[
              IconButton(
                tooltip: 'Editar competencia',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _eliminando ? null : () => _editar(competencia),
              ),
              // Eliminar va en un menú aparte para no quedar a un toque de
              // distancia de Editar.
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                enabled: !_eliminando,
                onSelected: (opcion) {
                  if (opcion == 'eliminar') {
                    _eliminar(competencia);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 12),
                        Flexible(child: Text('Eliminar competencia')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
          // Barra de progreso mientras se elimina.
          bottom: _eliminando
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(4),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        body: SafeArea(
          // skipLoadingOnRefresh: false hace que, al reintentar, se vea otra vez
          // el indicador de carga en lugar del error anterior.
          child: competenciaAsync.when(
            skipLoadingOnRefresh: false,
            loading: () => const _DetalleCargando(),
            error: (error, stackTrace) => _DetalleError(
              onReintentar: () =>
                  ref.invalidate(competenciaPorIdProvider(competitionId)),
            ),
            data: (competencia) => competencia == null
                ? const _DetalleNoEncontrada()
                : _DetalleContenido(competition: competencia, ahora: ahora),
          ),
        ),
      ),
    );
  }
}

class _DetalleCargando extends StatelessWidget {
  const _DetalleCargando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando competencia...'),
        ],
      ),
    );
  }
}

// Mensaje para personas, sin detalles técnicos de la excepción.
class _DetalleError extends StatelessWidget {
  const _DetalleError({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar esta competencia.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta de nuevo en un momento.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// La consulta funcionó pero no hay una competencia con ese id (null).
// No es un error: no se ofrece Reintentar, sino volver a la lista.
class _DetalleNoEncontrada extends StatelessWidget {
  const _DetalleNoEncontrada();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontró la competencia seleccionada.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Volver a competencias'),
            ),
          ],
        ),
      ),
    );
  }
}

// Contenido informativo del Issue #9. Recibe la competencia ya resuelta por
// el provider y la hora actual para el aviso de tiempo.
//
// Orden: cabecera, resumen con lo que más se pregunta (cuándo, dónde y
// costo) y después el resto de la información, en el mismo orden de siempre.
class _DetalleContenido extends StatelessWidget {
  const _DetalleContenido({required this.competition, required this.ahora});

  final Competencia competition;
  final DateTime ahora;

  String _twoDigits(int number) => number.toString().padLeft(2, '0');

  String _formatDate(DateTime date) =>
      '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';

  String _formatTime(DateTime date) =>
      '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

  Future<void> _copiar(
    BuildContext context,
    String valor,
    String mensaje,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: valor));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estilo = estiloDeCategoria(competition.categoria, scheme);
    final accentColor = estilo.color;
    final esEjemplo = competition.esDeEjemplo;

    final formattedDate = _formatDate(competition.fechaInicio);
    final formattedTime = _formatTime(competition.fechaInicio);
    final endDate = competition.fechaFin;
    final formattedEnd = endDate == null
        ? null
        : '${_formatDate(endDate)} a las ${_formatTime(endDate)}';
    final inscriptionUrl = competition.inscripcionUrl?.trim();
    final contact = competition.contacto?.trim();
    final tieneImagen = competition.imagenUrl?.trim().isNotEmpty ?? false;
    final limiteInscripcion = competition.fechaLimiteInscripcion;

    final fecha = _DetailInfoCard(
      icon: Icons.calendar_month_outlined,
      label: 'Fecha',
      value: formattedDate,
      accentColor: accentColor,
    );
    final hora = _DetailInfoCard(
      icon: Icons.schedule_outlined,
      label: 'Hora',
      value: formattedTime,
      accentColor: accentColor,
    );

    // El contenido se arma en tres bloques. En pantallas angostas van uno
    // debajo del otro; desde 600 dp, en dos columnas.
    final cabecera = <Widget>[
      // Con imagen, va arriba (si no carga, queda el fondo de la
      // categoría). Sin imagen, la cabecera de color ya cumple ese papel y
      // lleva el ícono de la categoría de fondo.
      if (tieneImagen) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ImagenCompetencia(
            key: const ValueKey('detalle-imagen'),
            imagenUrl: competition.imagenUrl,
            categoria: competition.categoria,
            alto: 160,
          ),
        ),
        const SizedBox(height: 12),
      ],
      // Cabecera visual: misma pantalla para todas las competencias.
      Container(
        padding: const EdgeInsets.all(20),
        foregroundDecoration: tieneImagen ? null : _IconoDeFondo(estilo.icono),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accentColor, Color.lerp(accentColor, Colors.black, 0.48)!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Etiqueta(
                  texto: competition.categoria,
                  icono: estilo.icono,
                  colorTexto: accentColor,
                  colorFondo: Colors.white,
                ),
                Etiqueta(
                  texto: etiquetaTemporal(competition, ahora),
                  icono: Icons.schedule_outlined,
                  colorTexto: accentColor,
                  colorFondo: Colors.white,
                ),
                if (limiteInscripcion != null)
                  EtiquetaDeInscripcion(competition: competition, ahora: ahora),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              competition.titulo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            // El rótulo y el identificador técnico solo acompañan a las
            // competencias de ejemplo, no a las creadas en la app.
            if (esEjemplo) ...[
              const SizedBox(height: 10),
              const Text(
                'Competencia ficticia de prueba',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.28)),
              const SizedBox(height: 6),
              Text(
                'Identificador: ${competition.id}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _ResumenClave(competition: competition, accentColor: accentColor),
      const SizedBox(height: 12),
      // Acciones principales. En un Wrap: con texto grande pasan a otra
      // línea en vez de desbordarse.
      Wrap(
        key: const ValueKey('detalle-acciones'),
        spacing: 8,
        runSpacing: 8,
        children: [
          BotonGuardar(competencia: competition, conTexto: true),
          if (admiteComoLlegar(competition.modalidad))
            BotonComoLlegar(competencia: competition),
        ],
      ),
    ];

    final general = <Widget>[
      Text(
        'Información general',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      // Fecha y hora van lado a lado; en pantallas muy angostas, una
      // debajo de la otra para que el texto no se parta.
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [fecha, const SizedBox(height: 12), hora],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: fecha),
                const SizedBox(width: 12),
                Expanded(child: hora),
              ],
            ),
          );
        },
      ),
      if (formattedEnd != null) ...[
        const SizedBox(height: 12),
        _DetailInfoCard(
          icon: Icons.event_outlined,
          label: 'Finaliza',
          value: formattedEnd,
          accentColor: accentColor,
        ),
      ],
      const SizedBox(height: 12),
      _DetailInfoCard(
        icon: Icons.devices_outlined,
        label: 'Modalidad',
        value: competition.modalidad,
        accentColor: accentColor,
      ),
      const SizedBox(height: 12),
      _DetailInfoCard(
        icon: Icons.location_on_outlined,
        label: 'Ubicación o acceso',
        value: competition.ubicacion,
        accentColor: accentColor,
      ),
      if (competition.tieneCoordenadas) ...[
        const SizedBox(height: 12),
        _MapaPequeno(competition: competition, accentColor: accentColor),
      ],
      const SizedBox(height: 12),
      _DetailInfoCard(
        icon: Icons.description_outlined,
        label: 'Descripción',
        value: competition.descripcion,
        accentColor: accentColor,
      ),
      if (competition.etapas.isNotEmpty) ...[
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            'Etapas y cronograma',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        LineaDeTiempo(
          key: const ValueKey('detalle-cronograma'),
          etapas: competition.etapas,
          ahora: ahora,
          competenciaFinalizada: estaFinalizada(competition, ahora),
          colorAcento: accentColor,
        ),
      ],
    ];

    final participar = <Widget>[
      Text(
        'Información para participar',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      if (limiteInscripcion != null) ...[
        _DetailInfoCard(
          key: const ValueKey('detalle-inscripcion'),
          icon: Icons.how_to_reg_outlined,
          label: 'Inscripción',
          value:
              '${etiquetaInscripcion(competition, ahora)}\n'
              'Fecha límite: ${_formatDate(limiteInscripcion)} a las '
              '${_formatTime(limiteInscripcion)}',
          accentColor: accentColor,
        ),
        const SizedBox(height: 12),
      ],
      _DetailInfoCard(
        icon: Icons.rule_outlined,
        label: 'Requisitos y reglas',
        value: competition.reglas,
        accentColor: accentColor,
      ),
      const SizedBox(height: 12),
      _DetailInfoCard(
        icon: Icons.payments_outlined,
        label: 'Costo',
        value: competition.costo,
        accentColor: accentColor,
      ),
      const SizedBox(height: 12),
      _DetailInfoCard(
        icon: Icons.how_to_reg_outlined,
        label: 'Cómo participar',
        value: competition.instruccionesParticipacion,
        accentColor: accentColor,
      ),
      if (inscriptionUrl != null && inscriptionUrl.isNotEmpty) ...[
        const SizedBox(height: 12),
        _DetailInfoCard(
          icon: Icons.link_outlined,
          label: 'Enlace de referencia',
          value: inscriptionUrl,
          accentColor: accentColor,
          action: IconButton(
            tooltip: 'Copiar enlace',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () =>
                _copiar(context, inscriptionUrl, 'Enlace copiado.'),
          ),
        ),
      ],
      if (contact != null && contact.isNotEmpty) ...[
        const SizedBox(height: 12),
        _DetailInfoCard(
          icon: Icons.alternate_email_outlined,
          label: 'Contacto',
          value: contact,
          accentColor: accentColor,
          action: IconButton(
            tooltip: 'Copiar contacto',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _copiar(context, contact, 'Contacto copiado.'),
          ),
        ),
      ],
      if (competition.tieneFichaDeTorneo) ...[
        const SizedBox(height: 24),
        _FormatoYPremios(competition: competition, accentColor: accentColor),
      ],
      if (esEjemplo) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Estos datos y los medios de contacto o inscripción son '
                  'ficticios. Se usan solo para desarrollo y no permiten '
                  'participar en eventos reales.',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ],
    ];

    const separacion = SizedBox(height: 24);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < anchoDosColumnas) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              ...cabecera,
              separacion,
              ...general,
              separacion,
              ...participar,
            ],
          );
        }
        // Dos columnas: a la izquierda lo que identifica al evento; a la
        // derecha lo necesario para participar. El ancho se limita para que
        // las líneas de texto no queden demasiado largas.
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                key: const ValueKey('detalle-dos-columnas'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [...cabecera, separacion, ...general],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: participar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Mapa pequeño con el marcador de la competencia. Es solo una vista (no se
// arrastra) para no interferir con el desplazamiento de la pantalla; para
// llegar está el botón «Cómo llegar».
class _MapaPequeno extends StatelessWidget {
  const _MapaPequeno({required this.competition, required this.accentColor});

  final Competencia competition;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(competition.latitud!, competition.longitud!);
    return Semantics(
      container: true,
      label: competition.esDeEjemplo
          ? 'Mapa con la ubicación ficticia de la competencia.'
          : 'Mapa con la ubicación de la competencia.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          key: const ValueKey('detalle-mapa'),
          height: 200,
          child: MapaBase(
            centro: punto,
            zoom: 15,
            interactivo: false,
            avisoFicticio: competition.esDeEjemplo
                ? 'Ubicación ficticia de ejemplo.'
                : null,
            marcadores: [
              Marker(
                point: punto,
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.location_on,
                  size: 44,
                  color: accentColor,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dibuja el ícono de la categoría, grande y casi transparente, en la esquina
// inferior derecha de la cabecera. Es decoración: no ocupa espacio ni cambia
// el tamaño de la cabecera.
class _IconoDeFondo extends Decoration {
  const _IconoDeFondo(this.icono);

  final IconData icono;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _PintorDeIcono(icono);
}

class _PintorDeIcono extends BoxPainter {
  _PintorDeIcono(this.icono);

  final IconData icono;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) {
      return;
    }
    const lado = 112.0;
    final pintor = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
          fontSize: lado,
          fontFamily: icono.fontFamily,
          package: icono.fontPackage,
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(offset & size, const Radius.circular(24)),
    );
    pintor.paint(
      canvas,
      offset + Offset(size.width - lado + 12, size.height - lado + 16),
    );
    canvas.restore();
    pintor.dispose();
  }
}

// Ficha de torneo: solo las filas con dato. Si no hay ninguno, la sección
// completa no se dibuja (lo decide quien la usa con tieneFichaDeTorneo).
class _FormatoYPremios extends StatelessWidget {
  const _FormatoYPremios({
    required this.competition,
    required this.accentColor,
  });

  final Competencia competition;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final formato = competition.formato;
    final tamano = formato == FormatoCompetencia.equipos
        ? describirTamanoEquipo(
            competition.tamanoEquipoMin,
            competition.tamanoEquipoMax,
          )
        : null;
    final premios = competition.premios?.trim();
    final organizador = competition.organizador?.trim();
    final filas = <Widget>[
      if (formato != null)
        _DetailInfoCard(
          icon: formato == FormatoCompetencia.equipos
              ? Icons.groups_outlined
              : Icons.person_outline,
          label: 'Formato',
          value: formato.etiqueta,
          accentColor: accentColor,
        ),
      if (tamano != null)
        _DetailInfoCard(
          icon: Icons.group_add_outlined,
          label: 'Tamaño del equipo',
          value: tamano,
          accentColor: accentColor,
        ),
      if (premios != null && premios.isNotEmpty)
        _DetailInfoCard(
          icon: Icons.emoji_events_outlined,
          label: 'Premios',
          value: premios,
          accentColor: accentColor,
        ),
      if (organizador != null && organizador.isNotEmpty)
        _DetailInfoCard(
          icon: Icons.apartment_outlined,
          label: 'Organizador',
          value: organizador,
          accentColor: accentColor,
        ),
    ];
    return Column(
      key: const ValueKey('detalle-formato-premios'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Formato y premios',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        for (final fila in filas) ...[const SizedBox(height: 12), fila],
      ],
    );
  }
}

// Lo que más se pregunta antes de decidir (cuándo, dónde y cuánto cuesta),
// visible sin desplazarse. Cada fila es un solo texto con etiqueta y valor,
// así un lector de pantalla lo anuncia completo.
class _ResumenClave extends StatelessWidget {
  const _ResumenClave({required this.competition, required this.accentColor});

  final Competencia competition;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilaResumen(
            icon: Icons.event_outlined,
            etiqueta: 'Cuándo',
            valor: formatearFechaHoraLegible(competition.fechaInicio),
            accentColor: accentColor,
          ),
          const SizedBox(height: 10),
          _FilaResumen(
            icon: Icons.location_on_outlined,
            etiqueta: 'Dónde',
            valor: '${competition.ubicacion} (${competition.modalidad})',
            accentColor: accentColor,
          ),
          const SizedBox(height: 10),
          _FilaResumen(
            icon: Icons.payments_outlined,
            etiqueta: 'Costo',
            valor: competition.costo,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
    required this.icon,
    required this.etiqueta,
    required this.valor,
    required this.accentColor,
  });

  final IconData icon;
  final String etiqueta;
  final String valor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accentColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$etiqueta: ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: valor,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Fila de información: ícono a la izquierda, etiqueta y valor a la derecha.
// `action` permite agregar un botón al final (por ejemplo, Copiar).
class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.action,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final action = this.action;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            // Etiqueta y valor se anuncian juntos en un lector de pantalla.
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 4), action],
        ],
      ),
    );
  }
}
