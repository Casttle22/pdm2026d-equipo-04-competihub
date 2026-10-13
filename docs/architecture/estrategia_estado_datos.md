# Estrategia de Estado y Fuente de Datos del MVP

## 1. Objetivo y alcance de M1

Este documento define la estrategia técnica para el manejo de estado y la fuente de datos del MVP de CompetiHub (M1), de modo que el equipo pueda implementar las funcionalidades del Issue #6 (modelo y feed) sin introducir incompatibilidades ni complejidad innecesaria.

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
- Estado de carga/vacío/error en el Feed (experiencia de usuario básica)

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

**Nota:** El Feed muestra una lista filtrada. No requiere paginación en M1 (dataset pequeño, < 50 items).

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
| `inscripcionUrl` | String? | No | Fuente de datos | Enlace externo a formulario/sitio |
| `contacto` | String? | No | Fuente de datos | Email/organizador para dudas |
| `imagenUrl` | String? | No | Fuente de datos | Imagen principal |

**Relación Feed → Detalle:** El `id` de la competencia seleccionada en el Feed es la clave para buscar y mostrar el detalle completo.

## 5. Estado mínimo de la aplicación

| Estado | Tipo | Alcance | Descripción |
|--------|------|---------|-------------|
| `categoriaSeleccionada` | `String?` | Global (app) | Categoría activa del filtro; `null` = "Todas" |
| `competenciaSeleccionadaId` | `String?` | Navegación (pantalla Detalle) | `id` de la competencia que se está viendo; se limpia al volver al Feed |
| `feedCompetencias` | `List<Competencia>` | Global (app) | Dataset completo cargado desde la fuente; base para filtrado |
| `estadoFeed` | `enum {cargando, listo, vacio, error}` | Vista Feed | Estado de carga inicial del dataset |

**No se requiere estado para:**
- Usuario autenticado (fuera de alcance)
- Favoritos/historial (fuera de alcance)
- Preferencias persistentes (fuera de alcance)
- Caché de imágenes (manejo nativo de Flutter `Image.network`)

## 6. Alternativas técnicas evaluadas

### 6.1 Fuente de datos para M1

| Opción | Descripción | Ventajas | Desventajas | Veredicto |
|--------|-------------|----------|-------------|-----------|
| **Datos ficticios en Dart (const List)** | `List<Competencia>` definida en un archivo `.dart` como `const` o `final` | Cero dependencias, compilación estática, tipo seguro, recarga en hot reload, sin I/O, ideal para M1 | No persiste entre sesiones, requiere recompilar para cambiar datos | **Recomendada para M1** |
| Archivo JSON local (`assets/data/competencias.json`) | JSON en `assets/`, leído con `rootBundle.loadString` | Separación datos/código, editable sin recompilar, base para futura API | Requiere `async`/`await`, parsing manual, manejo de errores de lectura, más código boilerplate | Viable para M2+ |
| Paquete `json_asset` / `flutter_assets` | Helpers para cargar JSON tipado | Menos boilerplate | Dependencia externa, no necesaria para dataset pequeño | Innecesaria |
| API remota (Firebase, REST, GraphQL) | Backend real | Realista, escalable | Requiere infraestructura, red, autenticación, manejo de errores de red, fuera de alcance M1 | **Fuera de alcance M1** |
| Base de datos local (sqflite, drift, hive) | Persistencia en dispositivo | Offline, consultas | Complejidad excesiva para M1, migraciones, esquema | **Fuera de alcance M1** |

**Conclusión:** Para M1, **datos ficticios definidos en Dart** (`lib/data/mock_competencias.dart`) es la opción más pequeña, comprensible y compatible con los fundamentos Flutter del curso. No hay necesidad demostrable de JSON local ni persistencia.

### 6.2 Manejo de estado

| Opción | Descripción | Ventajas | Desventajas | Veredicto |
|--------|-------------|----------|-------------|-----------|
| **`setState` + `StatefulWidget`** | Estado local en widgets que lo necesitan | Nativo, sin dependencias, comprensible, suficiente para 2-3 variables simples | No escala bien si el estado crece o se comparte entre ramas del árbol | **Recomendada para M1** |
| `ValueNotifier` / `ChangeNotifier` | Observable nativo de Flutter | Reactivo, separa estado de UI, sin paquetes externos | Requiere `AnimatedBuilder` o `ValueListenableBuilder`, ligera curva | Viable alternativa |
| `Provider` (`ChangeNotifierProvider`) | Inyección de dependencias + notificación | Estándar de facto, buen equilibrio, prueba en curso | Dependencia externa, `context.watch/read`, overkill para 3 variables | M2+ si el estado crece |
| `Riverpod` | Provider tipado, compile-time safe | Tipado fuerte, testing fácil, sin `context` | Curva de aprendizaje, dependencia, overkill para M1 | M2+ |
| `Bloc` / `Cubit` | Eventos/estados, separación estricta | Escalable, testeable, documentación viva | Verboso, curva pronunciada, overkill para M1 | Fuera de alcance M1 |
| `get_it` + `singleton` | Service locator | Desacopla | No reactivo por sí solo, patrón anti-Fluttter para estado simple | No recomendado |

**Conclusión:** Para M1, **`setState` en widgets puntuales** (o `ValueNotifier` si se prefiere separación) es suficiente. El estado global cabe en 3-4 variables simples. No hay justificación concreta para añadir paquetes externos. La simplicidad y la alineación con los fundamentos del curso priman.

### 6.3 Persistencia en M1

| Opción | Veredicto | Justificación |
|--------|-----------|---------------|
| `shared_preferences` (última categoría) | **No en M1** | El filtro por categoría no fue validado como necesidad específica de encuestados; añadir persistencia introduce complejidad (async, ciclo de vida, testing) sin valor demostrado para el MVP. |
| Sin persistencia | **Recomendada** | El usuario vuelve a "Todas" al reiniciar; comportamiento predecible y simple. |

## 7. Propuesta de fuente de datos para M1

### 7.1 Estructura recomendada

```
lib/
├── data/
│   ├── mock_competencias.dart      # const List<Competencia> competenciasMock
│   └── competencia.dart            # class Competencia { ... }
├── presentation/
│   ├── feed/
│   │   ├── feed_screen.dart
│   │   ├── feed_controller.dart    # (opcional) ValueNotifier para lista filtrada
│   │   └── competencia_card.dart
│   └── detalle/
│       └── detalle_screen.dart
└── main.dart
```

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
  final String? inscripcionUrl;
  final String? contacto;
  final String? imagenUrl;

  const Competencia({ ... });
}
```

### 7.3 Dataset de ejemplo (mínimo 8-10 items, 3-4 categorías)

Categorías sugeridas (basadas en hallazgos: esports dominante, plus académicas/deportivas):
- `Esports`
- `Académica`
- `Deportiva`
- `Otras`

El dataset debe cubrir:
- Fechas pasadas y futuras (para probar ordenación)
- Modalidades variadas
- Costos: gratis, pagados, "consultar"
- Con/sin URL de inscripción
- Con/sin imagen

## 8. Propuesta de manejo de estado

### 8.1 Arquitectura de estado (M1)

```
┌─────────────────────────────────────┐
│           CompetihubApp             │  (StatelessWidget)
│  - theme, routes, title             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│           HomeScreen                │  (StatefulWidget)
│  Estado global M1:                  │
│  - List<Competencia> _todas         │  ← Cargado una vez en initState
│  - String? _categoriaSeleccionada   │  ← null = "Todas"
│  - FeedState _estadoFeed            │  ← cargando/listo/vacio/error
│                                     │
│  Métodos:                           │
│  - _filtrar() -> List<Competencia>  │
│  - _cambiarCategoria(String?)       │
│  - _irADetalle(String id)           │
└──────────────┬──────────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
┌─────────────┐ ┌─────────────┐
│  FeedScreen │ │DetalleScreen│  (StatelessWidget)
│ (Stateless) │ │ (Stateless) │
│ - recibe    │ │ - recibe    │
│   lista     │ │   competencia│
│   filtrada  │ │   por id    │
│ - callback  │ │ - botón     │
│   onTap     │ │   "Volver"  │
└─────────────┘ └─────────────┘
```

### 8.2 Detalle de implementación

**HomeScreen (StatefulWidget)** — Único widget con `setState`:
- `initState`: carga `competenciasMock` → `_todas`, setea `_estadoFeed = listo`
- `_filtrar()`: si `_categoriaSeleccionada == null` → `_todas`; else `where((c) => c.categoria == _categoriaSeleccionada)`
- `_cambiarCategoria(cat)`: `setState(() => _categoriaSeleccionada = cat)`
- `_irADetalle(id)`: `Navigator.pushNamed(context, '/detalle', arguments: id)`

**FeedScreen (StatelessWidget)** — Recibe:
- `List<Competencia> competencias`
- `String? categoriaActual`
- `ValueChanged<String?> onCategoriaChanged`
- `ValueChanged<String> onCompetenciaTap`
- `FeedState estado`

**DetalleScreen (StatelessWidget)** — Recibe `competenciaId` via `ModalRoute.of(context)!.settings.arguments`, busca en `competenciasMock` (acceso global o pasado por constructor), muestra datos. Botón "Volver" hace `Navigator.pop(context)`.

### 8.3 Alternativa con `ValueNotifier` (si se prefiere separar lógica)

```dart
// feed_controller.dart
class FeedController extends ChangeNotifier {
  final List<Competencia> _todas = competenciasMock;
  String? _categoriaSeleccionada;
  FeedState _estado = FeedState.listo;

  List<Competencia> get filtradas => _categoriaSeleccionada == null
      ? _todas
      : _todas.where((c) => c.categoria == _categoriaSeleccionada).toList();

  String? get categoriaSeleccionada => _categoriaSeleccionada;
  FeedState get estado => _estado;

  void cambiarCategoria(String? cat) {
    _categoriaSeleccionada = cat;
    notifyListeners();
  }
}
```

Uso en `HomeScreen`: `final controller = FeedController();` + `AnimatedBuilder(animation: controller, builder: (_, _) => FeedScreen(...))`.

**Recomendación:** Empezar con `setState` en `HomeScreen` por simplicidad. Migrar a `ValueNotifier`/`ChangeNotifier` solo si el equipo lo valida en revisión de código.

## 9. Flujo de datos desde la fuente hasta la UI

```mermaid
flowchart TD
    A[compenciasMock<br/>lib/data/mock_competencias.dart] --> B[HomeScreen.initState<br/>_todas = competenciasMock]
    B --> C{_categoriaSeleccionada}
    C -- null --> D[_filtrar() -> _todas]
    C -- 'Esports' --> D
    C -- 'Académica' --> D
    D --> E[FeedScreen<br/>recibe lista filtrada]
    E --> F[Usuario toca tarjeta]
    F --> G[Navigator.push<br/>arguments: competencia.id]
    G --> H[DetalleScreen<br/>busca por id en competenciasMock]
    H --> I[Muestra campos completos]
    I --> J[Usuario pulsa Volver]
    J --> K[Navigator.pop]
    K --> E
    style A fill:#e1f5fe
    style B fill:#fff3e0
    style E fill:#e8f5e9
    style H fill:#e8f5e9
```

**Descripción textual:**

1. **Origen:** `competenciasMock` (const List<Competencia>) definida en `lib/data/mock_competencias.dart`.
2. **Carga inicial:** `HomeScreen.initState` asigna `_todas = competenciasMock`; `_estadoFeed = FeedState.listo`.
3. **Filtrado:** Al cambiar categoría (Dropdown/Chips), `setState(() => _categoriaSeleccionada = nueva)` → `_filtrar()` devuelve sublista → `FeedScreen` se reconstruye con nueva lista.
4. **Selección:** Usuario toca tarjeta → `Navigator.pushNamed('/detalle', arguments: competencia.id)`.
5. **Detalle:** `DetalleScreen` recibe `id` via `arguments`, busca en `competenciasMock` (acceso directo o pasado por constructor), renderiza todos los campos.
6. **Regreso:** Botón "Volver" → `Navigator.pop()` → `FeedScreen` vuelve a mostrar lista filtrada actual (estado conservado en `HomeScreen`).

## 10. Manejo de categoría y competencia seleccionada

### 10.1 Categoría seleccionada (filtro)

- **Tipo:** `String?` (`null` = "Todas")
- **Ubicación:** Estado de `HomeScreen` (o `FeedController`)
- **Persistencia:** **No** en M1 (ver §6.3)
- **Ciclo de vida:** Se reinicia a `null` al reiniciar la app
- **UI:** Chips / Dropdown / SegmentedButton en `FeedScreen`; callback `onCategoriaChanged`

### 10.2 Competencia seleccionada (navegación)

- **Tipo:** `String` (id de la competencia)
- **Transporte:** `Navigator.pushNamed(..., arguments: id)`
- **Recuperación en Detalle:** `final id = ModalRoute.of(context)!.settings.arguments as String; final competencia = competenciasMock.firstWhere((c) => c.id == id);`
- **Conservación:** No se guarda en estado global; el `id` viaja solo en la navegación. Al hacer `pop`, el `FeedScreen` muestra la misma lista filtrada que antes (estado en `HomeScreen` intacto).

## 11. Justificación y limitaciones

### 11.1 Justificación de decisiones clave

| Decisión | Justificación |
|----------|---------------|
| Datos ficticios en Dart (no JSON) | Cero I/O, tipo seguro en compile-time, hot reload funcional, sin dependencias, dataset < 50 items. JSON añade async/parsing sin beneficio en M1. |
| Sin persistencia (SharedPreferences) | El filtro por categoría no fue necesidad validada en encuesta (Issue #2: 55.6% usaban 2+ fuentes, pero no pidieron "recordar mi filtro"). Persistencia añade async, testing, complejidad de ciclo de vida. |
| `setState` / `StatefulWidget` único | Estado global cabe en 3 variables. No hay árbol profundo de widgets compartiendo estado. Paquetes externos (Provider, Riverpod, Bloc) introducen conceptos (context, providers, streams) que distraen de los fundamentos Flutter del curso. |
| Modelo `Competencia` inmutable (`const`) | Seguridad de tipos, rendimiento (const constructor), compatibilidad con `ListView.builder` y claves estables. |
| `id` como String (no int) | Flexible para futuras APIs (UUID, slugs), evita colisiones, legible en logs/debug. |
| Categorías como String (no enum) | Extensible sin recompilar modelo; dataset mock define las categorías reales. Enum sería prematuro sin backend. |

### 11.2 Limitaciones conocidas

1. **Dataset estático:** No refleja datos reales ni actualizaciones. M2+ debe migrar a JSON local o API.
2. **Sin ordenación configurable:** M1 ordena por `fechaInicio` ascendente fijo. Requerimientos de ordenación (próximas primero, pasadas al final) se definen en M2.
3. **Sin búsqueda textual:** Solo filtro por categoría. Búsqueda por nombre/ubicación queda para M2+.
4. **Imágenes:** `imagenUrl` opcional; `Image.network` maneja caché nativo. Placeholders y error handling básicos.
5. **Internacionalización:** Textos hardcoded en español. i18n (arb/intl) queda para M2+.
6. **Accesibilidad:** Semántica básica (tooltics, labels) en M1; auditoría completa en QA (Issue #7).

### 11.3 Riesgos mitigados

- **Incompatibilidad con #6:** El modelo `Competencia` y la lista `competenciasMock` son la única fuente de verdad. Ricardo (Issue #6) implementa Feed y modelo basándose en esta definición.
- **Cambio de fuente de datos:** La interfaz `Competencia` y el patrón de acceso (lista en memoria) permiten swap a JSON/API cambiando solo `mock_competencias.dart` → `repository.dart` sin tocar UI.
- **Escalabilidad de estado:** Si M2 añade favoritos, historial, usuario → se introduce `ChangeNotifier`/`Provider` en `HomeScreen` sin reescribir `FeedScreen`/`DetalleScreen`.

## 12. Relación con los Issues posteriores

| Issue | Tema | Cómo se conecta con este documento |
|-------|------|-------------------------------------|
| **#6** | Modelo y Feed | **Consumidor directo.** Usa `Competencia`, `competenciasMock`, filtro por categoría, navegación a Detalle. Este doc define el contrato. |
| **#7** | Detalle y QA | Usa mismos campos de `Competencia`. QA valida que el detalle muestre todos los campos obligatorios de §4.2. |
| **#8** | Navegación y transiciones | Implementa `HomeScreen` → `FeedScreen` → `DetalleScreen` con estado descrito en §8. Transiciones y animaciones sobre esta base. |
| **#9** | Filtro y categorías | Extiende el filtro (búsqueda, multi-categoría, ordenación). Estado base (`categoriaSeleccionada`) ya existe. |
| **#10+** | Persistencia, API, Auth | Migración natural: `mock_competencias.dart` → `CompetenciaRepository` (interface) → implementaciones `MockRepository` / `JsonAssetRepository` / `ApiRepository`. Estado migra a `Provider`/`Riverpod`. |

## 13. Decisiones pendientes y condiciones para aprobación

| Tema | Decisión pendiente | Condición para resolver |
|------|-------------------|--------------------------|
| **Controlador de Feed** | `setState` en `HomeScreen` vs `ValueNotifier`/`ChangeNotifier` | Revisión de código en PR #6; si el equipo prefiere separación lógica, adoptar `ChangeNotifier`. |
| **Ordenación por defecto** | ¿`fechaInicio` ascendente? ¿Próximas primero? | Definir en PR #6 con Ricardo; documentar aquí como ADR menor. |
| **Categorías: String vs Enum** | Mantener String en M1 | Revisar en M2 cuando haya backend; si API usa enum fijo, migrar modelo. |
| **Imagen placeholder** | Asset local vs color sólido | Definir en PR #6/7; asset recomendado para UX. |
| **Manejo de error en Detalle (id no encontrado)** | `assert` vs pantalla amigable | Pantalla amigable en M1; `assert` solo en debug. |

---

**Preparado por:** Alejandro (@ALECARRIUMES) — Arquitectura  
**Fecha:** 13/10/2026  
**Estado:** Propuesta técnica para revisión del equipo  
**PR asociado:** Draft → `docs: definir estrategia de estado y fuente de datos del MVP`  
**Cierra:** #4 (tras validación del equipo)