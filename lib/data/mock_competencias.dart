import 'competencia.dart';

// Eventos inventados exclusivamente para desarrollo y pruebas.
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
  ),
]);
