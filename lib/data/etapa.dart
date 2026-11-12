// Una etapa del cronograma de una competencia (por ejemplo, «Fase de grupos»
// o «Final»). El orden lo decide quien crea la competencia; no se reordena
// por fecha, porque puede haber etapas sin una hora exacta de inicio común.
class Etapa {
  const Etapa({
    required this.nombre,
    required this.fechaHora,
    this.descripcion,
  });

  final String nombre;
  final DateTime fechaHora;
  final String? descripcion;

  Etapa copiarCon({String? nombre, DateTime? fechaHora, String? descripcion}) {
    return Etapa(
      nombre: nombre ?? this.nombre,
      fechaHora: fechaHora ?? this.fechaHora,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Etapa &&
      other.nombre == nombre &&
      other.fechaHora == fechaHora &&
      other.descripcion == descripcion;

  @override
  int get hashCode => Object.hash(nombre, fechaHora, descripcion);
}

enum EstadoEtapa { completada, actual, proxima }

// Estado de cada etapa, en el mismo orden que la lista:
// - Si la competencia ya finalizó, todas están completadas.
// - Si no, la etapa actual es la última que ya empezó; las anteriores están
//   completadas y las siguientes, próximas. Si ninguna empezó, todas son
//   próximas y no se resalta ninguna.
List<EstadoEtapa> estadosDeEtapas(
  List<Etapa> etapas,
  DateTime ahora, {
  required bool competenciaFinalizada,
}) {
  if (competenciaFinalizada) {
    return [for (final _ in etapas) EstadoEtapa.completada];
  }
  var actual = -1;
  for (var i = 0; i < etapas.length; i++) {
    if (!etapas[i].fechaHora.isAfter(ahora)) {
      actual = i;
    }
  }
  return [
    for (var i = 0; i < etapas.length; i++)
      i < actual
          ? EstadoEtapa.completada
          : i == actual
          ? EstadoEtapa.actual
          : EstadoEtapa.proxima,
  ];
}

bool listasDeEtapasIguales(List<Etapa> a, List<Etapa> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
