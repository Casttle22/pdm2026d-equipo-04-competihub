import 'competencia_draft.dart';

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
      fechaLimiteInscripcion = draft.fechaLimiteInscripcion;

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
