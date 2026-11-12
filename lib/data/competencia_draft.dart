import 'competencia.dart' show FormatoCompetencia;

class CompetenciaDraft {
  const CompetenciaDraft({
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
  });

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
  final DateTime? fechaLimiteInscripcion;
  final FormatoCompetencia? formato;
  final int? tamanoEquipoMin;
  final int? tamanoEquipoMax;
  final String? premios;
  final String? organizador;

  // Copia con otras fechas; el resto de los datos no cambia.
  CompetenciaDraft conFechas({
    required DateTime fechaInicio,
    required DateTime? fechaFin,
    required DateTime? fechaLimiteInscripcion,
  }) {
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
    );
  }
}

// Contrato de integración con los widgets asignados a José:
// CompetitionFormScreen({
//   Competencia? initial,
//   required Future<void> Function(CompetenciaDraft) onSave,
// })
// Future<bool> showCompetitionDeleteDialog(
//   BuildContext context,
//   String titulo,
// )
