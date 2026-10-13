# Estrategia de Estado y Fuente de Datos del MVP

## 1. Objetivo y alcance de M1

Este documento define la estrategia técnica para el manejo de estado y la fuente de datos del MVP de CompetiHub (M1), de modo que el equipo pueda implementar las funcionalidades de los Issues posteriores sin introducir incompatibilidades ni complejidad innecesaria.

**Alcance de M1 (según Issues #1 y #3):**

- Feed de competencias disponibles
- Filtrado por categoría
- Pantalla de detalle con información clave para comprender una competencia y saber cómo participar
- Navegación: Feed → Detalle → Regreso al Feed

**Fuera de alcance de M1:**

- Autenticación, cuentas de usuario, inscripciones, pagos
- Gestión avanzada para organizadores
- Persistencia local o remota de preferencias
- Sincronización, caché avanzado, modo offline

## 2. Fuentes documentales y estado de aprobación

| Documento | Ubicación | Estado | Relevancia para este Issue |
|-----------|-----------|--------|----------------------------|
| README.md | `/README.md` | Aprobado (main) | Problema, flujo MVP, roles |
| Hallazgos de encuesta | `/docs/research/hallazgos_encuesta.md` | Aprobado (main, Issue #2) | Información requerida, limitaciones de muestra |
| Flujo de navegación MVP | `/docs/flujo_navegacion_mvp.md` | Aprobado (main, Issue #3, PR #14) | Vistas, transiciones, límites |
| Código base Flutter | `/lib/main.dart`, `/pubspec.yaml` | Integrado (main, Issue #5) | Punto de partida técnico |

**Nota:** El documento de flujo de navegación (Issue #3) fue integrado en main mediante el PR #14 el 13/10/2026 (commit 395c989). Este Issue #4 se basa en su versión final aprobada.

## 3. Necesidades del flujo principal

A partir del flujo aprobado (**Explorar → Filtrar → Seleccionar → Consultar detalle → Comprender → Participar**) y los hallazgos de investigación, se derivan las siguientes necesidades de datos y estado:

### 3.1 Información que el usuario necesita encontrar rápidamente (hallazgos cualitativos, Issue #2)

- Ubicación/lugar
- Fecha/hora
- Costo
- Tipo/tema (categoría)
- Requisitos/reglas
- Modalidad
- Instrucciones de participación/inscripción

### 3.2 Interacciones que requieren estado (Issue #3)

- Categoría seleccionada en el filtro (afecta qué competencias se muestran en el Feed)
- Competencia seleccionada al navegar al Detalle (identificador para recuperar sus datos)
- Estado vacío cuando el filtro no produce resultados (se contempla en Issue #7)

## 4. Datos mínimos por vista

### 4.1 Vista A: Feed de Competencias

| Campo | Tipo | Obligatorio | Origen | Uso |
|-------|------|-------------|--------|-----|
| `id` | String | Sí | Fuente de datos | Identificador único, clave para navegación al detalle |
| `titulo` | String | Sí | Fuente de datos | Texto principal de la tarjeta |
| `categoria` | String | Sí | Fuente de datos | Filtrado y etiqueta visual |
| `fechaInicio` | DateTime | Sí | Fuente de datos | Ordenación y visualización |
| `ubicacion` | String | Sí | Fuente de datos | Visualización en tarjeta |
| `modalidad` | String | No | Fuente de datos | Etiqueta visual (presencial/virtual/híbrida) |
| `imagenUrl` | String? | No | Fuente de datos | Imagen ilustrativa opcional |

**Total: 7 campos (5 obligatorios, 2 opcionales).**

**Nota:** El Feed muestra una lista filtrada. No requiere paginación en M1 (dataset pequeño).

### 4.2 Vista B: Detalle de la Competencia

| Campo | Tipo | Obligatorio | Origen | Uso |
|-------|------|-------------|--------|-----|
| `id` | String | Sí | Fuente de datos | Confirmación de identidad |
| `titulo` | String | Sí | Fuente de datos | Encabezado |
| `categoria` | String | Sí | Fuente de datos | Etiqueta |
| `fechaInicio` | DateTime | Sí | Fuente de datos | Fecha/hora de inicio |
| `fechaFin` | DateTime? | No | Fuente de datos | Fecha/hora de fin (si aplica) |
| `ubicacion` | String | Sí | Fuente de datos | Lugar o enlace virtual |
| `modalidad` | String | Sí | Fuente de datos | Presencial / Virtual / Híbrida |
| `descripcion` | String | Sí | Fuente de datos | Qué es la competencia |
| `reglas` | String | Sí | Fuente de datos | Reglas/requisitos de participación |
| `costo` | String | Sí | Fuente de datos | Gratis / Monto / "Consultar" |
| `instruccionesParticipacion` | String | Sí | Fuente de datos | Cómo participar (pasos, enlaces, contacto) |
| `inscripcionUrl` | String? | No | Fuente de datos | Enlace externo a formulario/sitio (complementa instrucciones) |
| `contacto` | String? | No | Fuente de datos | Email/organizador para dudas (complementa instrucciones) |
| `imagenUrl` | String? | No | Fuente de datos | Imagen principal |

**Total: 14 campos (10 obligatorios, 4 opcionales).**

**Relación Feed → Detalle:** El `id` de la competencia seleccionada en el Feed es la clave para buscar y mostrar el detalle completo.

## 5. Estado mínimo de la aplicación

| Estado | Tipo | Alcance | Descripción |
|--------|------|---------|-------------|
| `categoriaSeleccionada` | `String?` | Global (app) | Categoría activa del filtro; `null` = "Todas" |
| `todasLasCompetencias` | `List<Competencia>` | Global (app) | Dataset completo cargado desde la fuente; única fuente de verdad |

**No se requiere estado para:**

- Usuario autenticado (fuera de alcance)
- Favoritos/historial (fuera de alcance)
- Preferencias persistentes (fuera de alcance)
- Caché de imágenes (manejo nativo de Flutter `Image.network`)
- Estados de carga/error de red (fuente síncrona y local)
- `competenciaSeleccionadaId` (se transfiere por navegación, no es estado global)

**La lista filtrada se deriva** de `todasLasCompetencias` aplicando el filtro de `categoriaSeleccionada`; no se mantiene una segunda copia.

**Nota sobre `final List<Competencia>`:** declarar la variable como `final` impide reasignarla, pero no impide modificar el contenido de la lista (agregar/eliminar elementos). Si se desea una colección de solo lectura para el consumidor, se puede exponer `List.unmodifiable(todasLasCompetencias)` o `UnmodifiableListView(todasLasCompetencias)`.

## 6. Alternativas técnicas evaluadas

### 6.1 Fuente de datos para M1

| Opción | Descripción | Ventajas | Desventajas | Veredicto |
|--------|-------------|----------|-------------|-----------|
| **Datos ficticios en Dart (`final List`)** | `List<Competencia>` definida en un archivo `.dart` como `final` | Cero dependencias, tipo seguro, recarga en hot reload, sin I/O, ideal para M1 | No persiste entre sesiones, requiere recompilar para cambiar datos | **Recomendada para M1** |
| Archivo JSON local (`assets/data/competencias.json`) | JSON en `assets/`, leído con `rootBundle.loadString` | Separación datos/código, editable sin recompilar | Requiere `async`/`await`, parsing manual, manejo de errores; los assets empaquetados no se actualizan sin nueva compilación y distribución de la app | Viable para M2+ |
| Paquete `json_asset` / `flutter_assets` | Helpers para cargar JSON tipado | Menos boilerplate | Dependencia externa, no necesaria para dataset pequeño | Innecesaria |
| API remota (Firebase, REST, GraphQL) | Backend real | Realista, escalable | Requiere infraestructura, red, autenticación, manejo de errores de red, fuera de alcance M1 | **Fuera de alcance M1** |
| Base de datos local (sqflite, drift, hive) | Persistencia en dispositivo | Offline, consultas | Complejidad excesiva para M1, migraciones, esquema | **Fuera de alcance M1** |

**Conclusión:** Para M1, **datos ficticios definidos en Dart** (`lib/data/mock_competencias.dart` con `final List<Competencia>`) es la opción más pequeña, comprensible y compatible con los fundamentos Flutter del curso. No hay necesidad demostrable de JSON local ni persistencia.

### 6.2 Manejo de estado

| Opción | Descripción | Ventajas | Desventajas | Veredicto |
|--------|-------------|----------|-------------|-----------|
| **`setState` + `StatefulWidget`** | Estado local en widgets que lo necesitan | Nativo, sin dependencias, comprensible, suficiente para 2 variables simples | No escala bien si el estado crece o se comparte entre ramas del árbol | **Recomendada para M1** |
| `ValueNotifier` / `ChangeNotifier` | Observable nativo de Flutter | Reactivo, separa estado de UI, sin paquetes externos | Requiere `AnimatedBuilder` o `ListenableBuilder`, ligera curva | Alternativa si el equipo prefiere separar lógica |
| `Provider` (`ChangeNotifierProvider`) | Inyección de dependencias + notificación | Estándar de facto, buen equilibrio | Dependencia externa, `context.watch/read`, overkill para 2 variables | M2+ si el estado crece |
| `Riverpod` | Provider tipado, compile-time safe | Tipado fuerte, testing fácil, sin `context` | Curva de aprendizaje, dependencia, overkill para M1 | M2+ |
| `Bloc` / `Cubit` | Eventos/estados, separación estricta | Escalable, testeable, documentación viva | Verboso, curva pronunciada, overkill para M1 | Fuera de alcance M1 |
| `get_it` + `singleton` | Service locator | Desacopla | No reactivo por sí solo, patrón anti-Flutter para estado simple | No recomendado |

**Conclusión:** Para M1, **`setState` en `StatefulWidget`** es la estrategia recomendada. El estado global cabe en dos variables (`categoriaSeleccionada` y `todasLasCompetencias`). Cada Issue implementará el estado donde resulte apropiado; no se impone un único `StatefulWidget` raíz como requisito absoluto. No hay justificación concreta para añadir paquetes externos. La simplicidad y la alineación con los fundamentos del curso priman.

### 6.3 Persistencia en M1

| Opción | Veredicto | Justificación |
|--------|-----------|---------------|
| `shared_preferences` (última categoría) | **No en M1** | M1 no necesita conservar preferencias entre sesiones; añadir persistencia introduce complejidad (async, ciclo de vida, testing) sin valor demostrado para el MVP. |
| Sin persistencia | **Recomendada** | El usuario vuelve a "Todas" al reiniciar; comportamiento predecible y simple. |

## 7. Propuesta de fuente de datos para M1

### 7.1 Estructura sugerida (referencial, no prescriptiva)

```
lib/
├── data/
│   ├── mock_competencias.dart      # final List<Competencia> competenciasMock
│   └── competencia.dart            # class Competencia { ... }
└── main.dart
```

La organización interna de carpetas (`presentation/`, `feed/`, `detalle/`, controladores, etc.) corresponde a los Issues de implementación (#6, #8, #9). Este documento solo exige que exista un único punto de acceso a los datos mock.

### 7.2 Modelo de datos `Competencia`

```dart
class Competencia {
  final String id;
  final String titulo;
  final String categoria;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String ubicacion;
  final String modalidad; // 'Presencial' | 'Virtual' | 'Hibrida'
  final String descripcion;
  final String reglas;
  final String costo;
  final String instruccionesParticipacion;
  final String? inscripcionUrl;
  final String? contacto;
  final String? imagenUrl;

  const Competencia({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.fechaInicio,
    this.fechaFin,
    required this.ubicacion,
    required this.modalidad,
    required this.descripcion,
    required this.reglas,
    required this.costo,
    required this.instruccionesParticipacion,
    this.inscripcionUrl,
    this.contacto,
    this.imagenUrl,
  });
}
```

**Notas:**

- El constructor `const` es válido cuando todos los argumentos son constantes de compilación. Para `DateTime` creados en tiempo de ejecución (p. ej., `DateTime.now()` o parseados), la lista debe declararse `final` (no `const`).
- `instruccionesParticipacion` es obligatorio y cubre el requisito de "saber cómo participar" (Issue #9). `inscripcionUrl` y `contacto` son complementos opcionales.
- `modalidad` como `String` (no enum) permite extensibilidad sin recompilar; el dataset mock define los valores reales.

### 7.3 Dataset de ejemplo

El dataset mock debe contener varias competencias ficticias suficientes para verificar el feed, cubriendo 3-4 categorías (p. ej., `Esports`, `Académica`, `Deportiva`, `Otras`), con fechas pasadas y futuras, modalidades variadas, costos diversos y combinaciones de campos opcionales.

## 8. Propuesta de manejo de estado

### 8.1 Arquitectura de estado (M1) — descripción conceptual

```
CompetihubApp (StatelessWidget)
  └─ HomeScreen (StatefulWidget)
       Estado:
       - final List<Competencia> todasLasCompetencias  // fuente única
       - String? categoriaSeleccionada                  // null = "Todas"
       
       Derivado (no almacenado):
       - List<Competencia> competenciasFiltradas = 
           categoriaSeleccionada == null
               ? todasLasCompetencias
               : todasLasCompetencias.where((c) => c.categoria == categoriaSeleccionada).toList()
       
       Acciones:
       - cambiarCategoria(String? nueva)
       - navegarADetalle(String id)  // mecanismo de navegación definido en #8
       
       ├─ FeedScreen (recibe competenciasFiltradas + callback cambiarCategoria + callback onTap)
       └─ DetalleScreen (recibe id vía navegación, busca en todasLasCompetencias)
```

### 8.2 Detalle de la estrategia recomendada

- **`HomeScreen`** (o widget equivalente) mantiene el estado global M1 mediante `setState`.
- **`todasLasCompetencias`** se inicializa una vez (p. ej., en `initState` o como `late final`) a partir de `competenciasMock`.
- **`categoriaSeleccionada`** cambia con `setState(() => categoriaSeleccionada = nueva)`.
- **Lista filtrada** se computa en `build` o en un método auxiliar; no hay segunda fuente de verdad.
- **Navegación al detalle:** el `id` de la competencia se pasa como argumento de la ruta (mecanismo a definir en Issue #8; p. ej., `Navigator.pushNamed` con `arguments` o `go_router`). El Issue #4 no prescribe la API concreta.
- **DetalleScreen** recupera el `id` y busca la competencia en `todasLasCompetencias` (acceso directo al dato global o pasado por constructor).
- **Regreso:** `Navigator.pop()` restaura el Feed con el filtro activo intacto (estado en `HomeScreen` no cambia).

### 8.3 Alternativa con `ChangeNotifier` (opcional, solo si el equipo lo prefiere)

```dart
class FeedState extends ChangeNotifier {
  final List<Competencia> todasLasCompetencias;
  String? categoriaSeleccionada;

  FeedState(this.todasLasCompetencias);

  List<Competencia> get filtradas => categoriaSeleccionada == null
      ? todasLasCompetencias
      : todasLasCompetencias.where((c) => c.categoria == categoriaSeleccionada).toList();

  void cambiarCategoria(String? cat) {
    categoriaSeleccionada = cat;
    notifyListeners();
  }
}
```

Uso: `FeedState(competenciasMock)` provisto via `ChangeNotifierProvider` o consumido con `AnimatedBuilder` / `ListenableBuilder` (sin paquetes externos). **No es obligatoria para M1**; `setState` es suficiente y más simple.

## 9. Flujo de datos desde la fuente hasta la UI

```mermaid
flowchart TD
    A[competenciasMock<br/>lib/data/mock_competencias.dart] --> B[HomeScreen.initState<br/>todasLasCompetencias = competenciasMock]
    B --> C{categoriaSeleccionada}
    C -- null --> D[filtradas = todasLasCompetencias]
    C -- 'Esports' --> D
    C -- 'Académica' --> D
    D --> E[FeedScreen<br/>recibe lista filtrada]
    E --> F[Usuario toca tarjeta]
    F --> G[Navegación con id<br/>(mecanismo definido en #8)]
    G --> H[DetalleScreen<br/>busca por id en todasLasCompetencias]
    H --> I[Muestra información relevante del detalle]
    I --> J[Usuario pulsa Volver]
    J --> K[Navigator.pop]
    K --> E
    style A fill:#e1f5fe
    style B fill:#fff3e0
    style E fill:#e8f5e9
    style H fill:#e8f5e9
```

**Descripción textual:**

1. **Origen:** `competenciasMock` (`final List<Competencia>`) definida en `lib/data/mock_competencias.dart`.
2. **Carga inicial:** `HomeScreen` asigna `todasLasCompetencias = competenciasMock` (una sola vez).
3. **Filtrado:** Al cambiar categoría, `setState(() => categoriaSeleccionada = nueva)` → la lista filtrada se deriva en el build → `FeedScreen` se reconstruye.
4. **Selección:** Usuario toca tarjeta → navegación con el `id` de la competencia (mecanismo definido en Issue #8).
5. **Detalle:** `DetalleScreen` recibe el `id`, busca en `todasLasCompetencias`, renderiza la información relevante.
6. **Regreso:** `Navigator.pop()` → `FeedScreen` muestra la misma lista filtrada (estado en `HomeScreen` intacto).

## 10. Manejo de categoría y competencia seleccionada

### 10.1 Categoría seleccionada (filtro)

- **Tipo:** `String?` (`null` = "Todas")
- **Ubicación:** Estado de `HomeScreen` (o `FeedState` si se usa `ChangeNotifier`)
- **Persistencia:** **No** en M1 (ver §6.3)
- **Ciclo de vida:** Se reinicia a `null` al reiniciar la app
- **UI:** Chips / Dropdown / SegmentedButton en `FeedScreen`; callback `onCategoriaChanged`

### 10.2 Competencia seleccionada (navegación)

- **Tipo:** `String` (id de la competencia)
- **Transporte:** Argumentos de la ruta de navegación (definido en Issue #8)
- **Recuperación en Detalle:** Búsqueda por `id` en `todasLasCompetencias` (acceso global o pasado por constructor)
- **Conservación:** No se guarda en estado global; el `id` viaja solo en la navegación. Al hacer `pop`, el `FeedScreen` muestra la misma lista filtrada que antes (estado en `HomeScreen` intacto).

## 11. Justificación y limitaciones

### 11.1 Justificación de decisiones clave

| Decisión | Justificación |
|----------|---------------|
| Datos ficticios en Dart (no JSON) | Cero I/O, tipo seguro en compile-time, hot reload funcional, sin dependencias, dataset pequeño. JSON añade async/parsing sin beneficio en M1. |
| Sin persistencia (SharedPreferences) | M1 no necesita conservar preferencias entre sesiones; añadir persistencia introduce complejidad (async, ciclo de vida, testing) sin valor para el MVP. |
| `setState` / `StatefulWidget` | Estado global cabe en 2 variables. No hay árbol profundo compartiendo estado. Paquetes externos introducen conceptos (context, providers, streams) que distraen de los fundamentos Flutter del curso. |
| Modelo `Competencia` inmutable (`final` fields) | Seguridad de tipos, rendimiento, compatibilidad con `ListView.builder` y claves estables. Constructor `const` cuando los argumentos lo permiten. |
| `id` como String (no int) | Flexible para futuras APIs (UUID, slugs), evita colisiones, legible en logs/debug. |
| Categorías como String (no enum) | Extensible sin recompilar modelo; dataset mock define las categorías reales. Enum sería prematuro sin backend. |
| `instruccionesParticipacion` obligatorio | Cumple requisito de "saber cómo participar" (Issue #9) sin depender de campos opcionales. |

### 11.2 Limitaciones conocidas

1. **Dataset estático:** No refleja datos reales ni actualizaciones. M2+ migrará a JSON local o API.
2. **Sin ordenación configurable:** M1 no define ordenación obligatoria; el dataset mock puede venir preordenado. Requerimientos de ordenación se definen en Issues futuros.
3. **Sin búsqueda textual:** Solo filtro por categoría. Búsqueda por nombre/ubicación queda para Issues futuros.
4. **Imágenes:** `imagenUrl` opcional; `Image.network` maneja caché nativo. Placeholders y error handling básicos.
5. **Internacionalización:** Textos hardcoded en español. i18n (arb/intl) queda para Issues futuros.
6. **Accesibilidad:** Semántica básica en M1; auditoría completa en QA (Issue #10).

### 11.3 Riesgos mitigados

- **Incompatibilidad con #6:** El modelo `Competencia` y la lista `competenciasMock` son la única fuente de verdad. Ricardo (Issue #6) implementa modelo y feed basándose en esta definición.
- **Cambio de fuente de datos:** El modelo `Competencia` y el patrón de acceso (lista en memoria) permiten swap a JSON/API cambiando solo el proveedor de datos sin tocar UI, **siempre que la UI acceda a los datos a través de una abstracción** (p. ej., un repositorio o provider) y no a una variable global directa.
- **Escalabilidad de estado:** Si M2 añade favoritos, historial, usuario → se introduce `ChangeNotifier`/`Provider` en `HomeScreen` sin reescribir `FeedScreen`/`DetalleScreen`.

## 12. Relación con los Issues posteriores

| Issue | Responsable | Tema | Cómo se conecta con este documento |
|-------|-------------|------|-------------------------------------|
| **#6** | Ricardo | Modelo de competencia, datos ficticios y feed visible | **Consumidor directo.** Usa `Competencia`, `competenciasMock`, lista filtrada derivada. Este doc define el contrato de datos. |
| **#7** | Wesley | Filtro por categoría | Implementa la UI de filtro que modifica `categoriaSeleccionada` y maneja estado vacío. Estado base ya definido aquí. |
| **#8** | Ricardo | Navegación del feed al detalle | Define el mecanismo de navegación (cómo pasar el `id` y volver). Estrategia de conservación de filtro ya definida aquí. |
| **#9** | José | Información completa del detalle | Usa los 14 campos de `Competencia` (10 obligatorios). `instruccionesParticipacion` garantiza "cómo participar". |
| **#10** | José | QA y evidencia del flujo | Valida que el flujo completo funcione con los datos y estado definidos aquí. |

## 13. Decisiones pendientes y condiciones para aprobación

| Tema | Decisión pendiente | Condición para resolver |
|------|-------------------|--------------------------|
| **Mecanismo de navegación** | API de routing (`Navigator.pushNamed`, `go_router`, etc.) | Definido en Issue #8; este doc solo requiere que el `id` viaje como argumento. |
| **Estructura de carpetas/controladores** | Organización interna de `presentation/` | Definida en Issues #6, #8, #9; este doc solo exige único punto de acceso a datos mock. |
| **Ordenación por defecto** | ¿Dataset preordenado? ¿Ordenación en UI? | No es criterio de M1; se define en Issues futuros si aplica. |
| **Categorías: String vs Enum** | Mantener String en M1 | Revisar cuando haya backend; si API usa enum fijo, migrar modelo. |
| **Imagen placeholder** | Asset local vs color sólido | Definir en PR #6/9; asset recomendado para UX. |
| **Error en Detalle (id no encontrado)** | `assert` debug vs pantalla amigable | Pantalla amigable en M1; `assert` solo en debug. |

---

**Preparado por:** Alejandro (@ALECARRIUMES) — Arquitectura  
**Fecha:** 13/10/2026  
**Estado:** Propuesta técnica para revisión del equipo  
**PR asociado:** #15 → `docs: definir estrategia de estado y fuente de datos del MVP`  
**Cierra:** #4 (tras validación del equipo)