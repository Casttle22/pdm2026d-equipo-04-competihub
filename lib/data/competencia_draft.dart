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
