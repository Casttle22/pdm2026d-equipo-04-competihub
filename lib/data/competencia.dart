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
  });

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

  // Las competencias sembradas desde mock_competencias.dart usan ids que
  // empiezan con «mock-». Las creadas en la app usan «local-». La interfaz
  // solo rotula como ficticias a las de ejemplo.
  bool get esDeEjemplo => id.startsWith('mock-');

  // Copia con otras fechas. La usan los datos de ejemplo, cuyas fechas se
  // calculan respecto al día en que se siembran.
  Competencia conFechas({
    required DateTime fechaInicio,
    required DateTime? fechaFin,
  }) {
    return Competencia(
      id: id,
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
    );
  }
}
