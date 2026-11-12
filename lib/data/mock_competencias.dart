import 'competencia.dart';
import 'etapa.dart';

// Eventos inventados exclusivamente para desarrollo y pruebas.
// La ficha de torneo (formato y tamaño de equipo) sale de las reglas de cada
// ejemplo; premios y organizador también son ficticios y lo dicen. La
// carrera no tiene ficha: sus reglas no dicen si es individual.
// Las coordenadas de los ejemplos presenciales e híbridos son ficticias: son
// puntos elegidos alrededor del centro de Quetzaltenango (centroDeEjemplo),
// no la ubicación de ningún evento. El mapa lo avisa.
// No representan eventos reales ni evidencia de investigación de usuarios.
final List<Competencia> competenciasMock = List<Competencia>.unmodifiable([
  Competencia(
    id: 'mock-esports-01',
    titulo: 'Copa ficticia de arena digital',
    categoria: 'Esports',
    fechaInicio: DateTime(2026, 10, 20, 18),
    fechaFin: DateTime(2026, 10, 20, 21),
    ubicacion: 'Sala virtual de prueba Alfa',
    modalidad: 'Virtual',
    descripcion:
        'Torneo ficticio por equipos en una arena digital de práctica.',
    reglas: 'Equipos de tres personas; disponer de equipo y conexión propios.',
    costo: 'Gratis',
    instruccionesParticipacion:
        'En este escenario de prueba, completar el formulario ficticio con el nombre del equipo. No hay inscripción real.',
    inscripcionUrl: 'https://example.com/competihub/mock-esports-01',
    contacto: 'arena@example.com',
    formato: FormatoCompetencia.equipos,
    tamanoEquipoMin: 3,
    tamanoEquipoMax: 3,
    premios: 'Trofeo simbólico de prueba (ficticio)',
    organizador: 'Club ficticio de arena digital',
  ),
  Competencia(
    id: 'mock-academic-01',
    titulo: 'Reto ficticio de programación',
    categoria: 'Académica',
    fechaInicio: DateTime(2026, 10, 24, 9),
    fechaFin: DateTime(2026, 10, 24, 13),
    ubicacion: 'Laboratorio ficticio Prisma, aula 2',
    modalidad: 'Presencial',
    descripcion: 'Desafío simulado de algoritmos y resolución de problemas.',
    reglas:
        'Participación individual; llevar computadora y conocer programación básica.',
    costo: 'Q 25 ficticios',
    instruccionesParticipacion:
        'Para la simulación, preparar un alias y presentarse en el laboratorio de prueba. No asistir a un lugar real.',
    formato: FormatoCompetencia.individual,
    organizador: 'Laboratorio ficticio Prisma',
    latitud: 14.8405,
    longitud: -91.5235,
  ),
  Competencia(
    id: 'mock-sports-01',
    titulo: 'Carrera ficticia de cinco kilómetros',
    categoria: 'Deportiva',
    fechaInicio: DateTime(2026, 11, 1, 7, 30),
    ubicacion: 'Circuito imaginario del Parque Nube',
    modalidad: 'Presencial',
    descripcion:
        'Carrera recreativa inventada para probar información deportiva.',
    reglas:
        'Usar calzado deportivo y respetar el recorrido simulado de cinco kilómetros.',
    costo: 'Q 40 ficticios',
    instruccionesParticipacion:
        'En el ejemplo, solicitar un dorsal al contacto ficticio. No se reciben solicitudes ni pagos reales.',
    contacto: 'carrera@example.com',
    latitud: 14.829,
    longitud: -91.512,
  ),
  Competencia(
    id: 'mock-academic-02',
    titulo: 'Olimpiada ficticia de lógica',
    categoria: 'Académica',
    fechaInicio: DateTime(2026, 11, 7, 10),
    fechaFin: DateTime(2026, 11, 8, 12),
    ubicacion: 'Aula imaginaria Delta y sala virtual de prueba',
    modalidad: 'Híbrida',
    descripcion: 'Encuentro ficticio de acertijos y razonamiento matemático.',
    reglas:
        'Parejas de participantes; resolver los ejercicios sin ayuda externa.',
    costo: 'Gratis',
    instruccionesParticipacion:
        'En la simulación, registrar una pareja y elegir modalidad mediante el enlace de ejemplo. No hay registro real.',
    inscripcionUrl: 'https://example.com/competihub/mock-academic-02',
    formato: FormatoCompetencia.equipos,
    tamanoEquipoMin: 2,
    tamanoEquipoMax: 2,
    premios: 'Diplomas simbólicos (ficticios)',
    latitud: 14.8372,
    longitud: -91.5098,
  ),
  Competencia(
    id: 'mock-other-01',
    titulo: 'Desafío ficticio de ilustración',
    categoria: 'Otras',
    fechaInicio: DateTime(2026, 11, 14, 14),
    ubicacion: 'Galería virtual de prueba Pixel',
    modalidad: 'Virtual',
    descripcion:
        'Concurso inventado para crear una ilustración sobre ciudades imaginarias.',
    reglas:
        'Entregar una obra original en formato PNG; una propuesta por persona.',
    costo: 'Consultar (simulado)',
    instruccionesParticipacion:
        'En este escenario, enviar una ilustración al correo de ejemplo. No se reciben obras reales.',
    contacto: 'ilustracion@example.com',
    formato: FormatoCompetencia.individual,
  ),
  Competencia(
    id: 'mock-esports-02',
    titulo: 'Liga ficticia de estrategia',
    categoria: 'Esports',
    fechaInicio: DateTime(2026, 9, 12, 16),
    fechaFin: DateTime(2026, 9, 12, 20),
    ubicacion: 'Centro de juegos imaginario Órbita',
    modalidad: 'Presencial',
    descripcion:
        'Evento ficticio pasado para probar fechas y variedad del feed.',
    reglas: 'Participación individual; partidas de estrategia por turnos.',
    costo: 'Q 15 ficticios',
    instruccionesParticipacion:
        'Ejemplo de evento finalizado: se habría reservado un puesto en la sede imaginaria. No admite inscripciones reales.',
    formato: FormatoCompetencia.individual,
    latitud: 14.8318,
    longitud: -91.5262,
  ),
]);

// Centro de Quetzaltenango, alrededor del cual están las ubicaciones
// ficticias de los ejemplos. También es el centro inicial de los mapas.
const double latitudCentroDeEjemplo = 14.8347;
const double longitudCentroDeEjemplo = -91.5181;

// Días, respecto a hoy, en que empieza cada competencia de ejemplo dentro de
// la app. Las fechas fijas de arriba son solo la base (hora del día y
// duración): con ellas, al pasar el tiempo, todos los ejemplos terminaban
// como «Finalizada». Una queda en el pasado a propósito, para que el estado
// «Finalizada» se pueda ver y probar.
const Map<String, int> diasDeInicioDeEjemplo = {
  'mock-esports-01': 3,
  'mock-academic-01': 7,
  'mock-sports-01': 12,
  'mock-academic-02': 18,
  'mock-other-01': 25,
  'mock-esports-02': -20,
};

// Fechas de una competencia de ejemplo relativas a `hoy`. Conserva la hora
// del día y la duración de los datos base. Devuelve null si el id no es de
// una competencia de ejemplo conocida.
({DateTime inicio, DateTime? fin})? fechasDeEjemplo(String id, DateTime hoy) {
  final dias = diasDeInicioDeEjemplo[id];
  if (dias == null) {
    return null;
  }
  for (final base in competenciasMock) {
    if (base.id != id) {
      continue;
    }
    final inicioBase = base.fechaInicio;
    final inicio = DateTime(
      hoy.year,
      hoy.month,
      hoy.day + dias,
      inicioBase.hour,
      inicioBase.minute,
    );
    final finBase = base.fechaFin;
    if (finBase == null) {
      return (inicio: inicio, fin: null);
    }
    // La duración se cuenta en días de calendario para que un cambio de
    // horario no mueva la hora de cierre.
    final diasDeDuracion =
        DateTime.utc(finBase.year, finBase.month, finBase.day)
            .difference(
              DateTime.utc(inicioBase.year, inicioBase.month, inicioBase.day),
            )
            .inDays;
    return (
      inicio: inicio,
      fin: DateTime(
        inicio.year,
        inicio.month,
        inicio.day + diasDeDuracion,
        finBase.hour,
        finBase.minute,
      ),
    );
  }
  return null;
}

// Días, respecto a hoy, en que cierra la inscripción de cada ejemplo (a las
// 23:59). Están elegidos para que se vean los cuatro estados: abiertas,
// cierra en N días, cierra hoy y cerradas. Un ejemplo queda sin límite.
const Map<String, int> diasDeCierreDeEjemplo = {
  'mock-esports-01': 2,
  'mock-academic-01': 0,
  'mock-sports-01': 10,
  'mock-other-01': -1,
  'mock-esports-02': -22,
};

DateTime? limiteDeInscripcionDeEjemplo(String id, DateTime hoy) {
  final dias = diasDeCierreDeEjemplo[id];
  if (dias == null) {
    return null;
  }
  return DateTime(hoy.year, hoy.month, hoy.day + dias, 23, 59);
}

// Cronograma de algunos ejemplos, como distancia desde su inicio. Así sigue
// siendo coherente aunque las fechas de los ejemplos se recalculen.
final Map<
  String,
  List<({String nombre, Duration desdeInicio, String descripcion})>
>
etapasDeEjemplo = {
  'mock-esports-01': [
    (
      nombre: 'Fase de grupos',
      desdeInicio: Duration.zero,
      descripcion: 'Partidas de prueba entre todos los equipos ficticios.',
    ),
    (
      nombre: 'Semifinales',
      desdeInicio: const Duration(hours: 1, minutes: 30),
      descripcion: 'Los cuatro mejores equipos de la fase de grupos.',
    ),
    (
      nombre: 'Final',
      desdeInicio: const Duration(hours: 2, minutes: 30),
      descripcion: 'Partida decisiva del torneo ficticio.',
    ),
  ],
  'mock-academic-02': [
    (
      nombre: 'Ronda clasificatoria',
      desdeInicio: Duration.zero,
      descripcion: 'Acertijos individuales por pareja, en sala virtual.',
    ),
    (
      nombre: 'Gran final',
      desdeInicio: const Duration(days: 1),
      descripcion: 'Las cinco mejores parejas, en el aula imaginaria.',
    ),
  ],
};

// Etapas de un ejemplo a partir de su fecha de inicio. Vacío si no tiene.
List<Etapa> etapasDeEjemploDesde(String id, DateTime inicio) {
  return [
    for (final etapa in etapasDeEjemplo[id] ?? const [])
      Etapa(
        nombre: etapa.nombre,
        fechaHora: inicio.add(etapa.desdeInicio),
        descripcion: etapa.descripcion,
      ),
  ];
}

// Los ejemplos tal como se ven en la app: con fechas relativas a `hoy`.
List<Competencia> competenciasDeEjemplo(DateTime hoy) {
  return [
    for (final base in competenciasMock)
      switch (fechasDeEjemplo(base.id, hoy)) {
        final fechas? => Competencia.desdeBorrador(
          base.id,
          base
              .aBorrador()
              .conFechas(
                fechaInicio: fechas.inicio,
                fechaFin: fechas.fin,
                fechaLimiteInscripcion: limiteDeInscripcionDeEjemplo(
                  base.id,
                  hoy,
                ),
              )
              .conEtapas(etapasDeEjemploDesde(base.id, fechas.inicio)),
        ),
        null => base,
      },
  ];
}
