import 'competencia_draft.dart';
import 'etapa.dart';

// Cómo se compite. Es opcional: si no se conoce, no se muestra.
enum FormatoCompetencia {
  individual('Individual'),
  equipos('Por equipos');

  const FormatoCompetencia(this.etiqueta);

  final String etiqueta;

  // Valor guardado en la base de datos (el nombre del enum).
  static FormatoCompetencia? desdeTexto(String? valor) {
    for (final formato in values) {
      if (formato.name == valor) {
        return formato;
      }
    }
    return null;
  }
}

// «3 personas por equipo», «De 2 a 5 personas por equipo», «Mínimo 2
// personas por equipo» o «Hasta 5 personas por equipo». null si no hay
// ningún dato.
String? describirTamanoEquipo(int? minimo, int? maximo) {
  String personas(int n) => n == 1 ? '1 persona' : '$n personas';
  if (minimo != null && maximo != null) {
    return minimo == maximo
        ? '${personas(minimo)} por equipo'
        : 'De $minimo a ${personas(maximo)} por equipo';
  }
  if (minimo != null) {
    return 'Mínimo ${personas(minimo)} por equipo';
  }
  if (maximo != null) {
    return 'Hasta ${personas(maximo)} por equipo';
  }
  return null;
}

class Competencia {
  const Competencia({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.fechaInicio,
    required this.ubicacion,
    required this.modalidad,
    required this.descripcion,
    required this.reglas,
    required this.costo,
    required this.instruccionesParticipacion,
    this.fechaFin,
    this.inscripcionUrl,
    this.contacto,
    this.imagenUrl,
    this.fechaLimiteInscripcion,
    this.formato,
    this.tamanoEquipoMin,
    this.tamanoEquipoMax,
    this.premios,
    this.organizador,
    this.etapas = const [],
    this.latitud,
    this.longitud,
  });

  // Une un id con los datos de un formulario. La usan las fuentes de datos
  // al crear o actualizar, para no repetir la lista de campos.
  Competencia.desdeBorrador(this.id, CompetenciaDraft draft)
    : titulo = draft.titulo,
      categoria = draft.categoria,
      fechaInicio = draft.fechaInicio,
      ubicacion = draft.ubicacion,
      modalidad = draft.modalidad,
      descripcion = draft.descripcion,
      reglas = draft.reglas,
      costo = draft.costo,
      instruccionesParticipacion = draft.instruccionesParticipacion,
      fechaFin = draft.fechaFin,
      inscripcionUrl = draft.inscripcionUrl,
      contacto = draft.contacto,
      imagenUrl = draft.imagenUrl,
      fechaLimiteInscripcion = draft.fechaLimiteInscripcion,
      formato = draft.formato,
      tamanoEquipoMin = draft.tamanoEquipoMin,
      tamanoEquipoMax = draft.tamanoEquipoMax,
      premios = draft.premios,
      organizador = draft.organizador,
      etapas = List.unmodifiable(draft.etapas),
      latitud = draft.latitud,
      longitud = draft.longitud;

  final String id;
  final String titulo;
  final String categoria;
  final DateTime fechaInicio;
  final String ubicacion;
  final String modalidad;
  final String descripcion;
  final String reglas;
  final String costo;
  final String instruccionesParticipacion;
  final DateTime? fechaFin;
  final String? inscripcionUrl;
  final String? contacto;
  final String? imagenUrl;

  // Hasta cuándo se puede inscribir alguien. Es opcional: sin este dato la
  // app no muestra ningún estado de inscripción, en lugar de suponerlo.
  final DateTime? fechaLimiteInscripcion;

  // Ficha de torneo, toda opcional. El tamaño de equipo solo tiene sentido
  // cuando el formato es por equipos.
  final FormatoCompetencia? formato;
  final int? tamanoEquipoMin;
  final int? tamanoEquipoMax;
  final String? premios;
  final String? organizador;

  // Cronograma, en el orden que eligió quien creó la competencia. La lista
  // del Inicio no lo carga (no lo muestra); el Detalle sí.
  final List<Etapa> etapas;

  // Punto en el mapa (opcional). Se guardan juntos: o están los dos o
  // ninguno.
  final double? latitud;
  final double? longitud;

  bool get tieneCoordenadas => latitud != null && longitud != null;

  bool get tieneFichaDeTorneo =>
      formato != null ||
      (premios?.trim().isNotEmpty ?? false) ||
      (organizador?.trim().isNotEmpty ?? false);

  // Las competencias sembradas desde mock_competencias.dart usan ids que
  // empiezan con «mock-». Las creadas en la app usan «local-». La interfaz
  // solo rotula como ficticias a las de ejemplo.
  bool get esDeEjemplo => id.startsWith('mock-');

  // Los mismos datos como borrador, para modificarlos y volver a armar la
  // competencia con desdeBorrador.
  CompetenciaDraft aBorrador() {
    return CompetenciaDraft(
      titulo: titulo,
      categoria: categoria,
      fechaInicio: fechaInicio,
      ubicacion: ubicacion,
      modalidad: modalidad,
      descripcion: descripcion,
      reglas: reglas,
      costo: costo,
      instruccionesParticipacion: instruccionesParticipacion,
      fechaFin: fechaFin,
      inscripcionUrl: inscripcionUrl,
      contacto: contacto,
      imagenUrl: imagenUrl,
      fechaLimiteInscripcion: fechaLimiteInscripcion,
      formato: formato,
      tamanoEquipoMin: tamanoEquipoMin,
      tamanoEquipoMax: tamanoEquipoMax,
      premios: premios,
      organizador: organizador,
      etapas: etapas,
      latitud: latitud,
      longitud: longitud,
    );
  }

  // Copia con otras fechas. La usan los datos de ejemplo, cuyas fechas se
  // calculan respecto al día en que se siembran.
  Competencia conFechas({
    required DateTime fechaInicio,
    required DateTime? fechaFin,
    DateTime? fechaLimiteInscripcion,
  }) {
    return Competencia.desdeBorrador(
      id,
      aBorrador().conFechas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        fechaLimiteInscripcion: fechaLimiteInscripcion,
      ),
    );
  }
}
