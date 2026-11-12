# Bitácora de uso de IA

Cada uso de IA que termina en el repo se registra aquí (el más reciente arriba).
El objetivo no es justificar el uso, sino demostrar **criterio**:
qué especificaste, qué revisaste y qué rechazaste.

| Campo | Qué escribir |
|---|---|
| Fecha / autor | `2026-10-24 · @usuario` |
| Herramienta | Claude, Copilot, ChatGPT, Big Pickle… |
| Especificación | Qué pediste y con qué restricciones (pegar el prompt o resumirlo) |
| Resultado | Qué devolvió, en una frase |
| Aceptado | Qué quedó en el código y por qué |
| Rechazado / corregido | Qué cambiaste y por qué. **Esta es la columna más importante.** |
| Verificación | Cómo comprobaste que funciona (pruebas, dispositivo) |
| Commit / PR | Enlace |

---
## 2026-11-11 · @AlexDLG1 — Módulo 0: textos que se cortaban con letra grande

- **Herramienta:** Claude Code (Claude Fable 5.2).
- **Especificación:** "Que los mensajes de error del formulario no se corten con texto grande (errorMaxLines o equivalente). Que el título de la barra del Detalle tampoco se corte, o se acorte a «Detalle»."
- **Resultado:** `errorMaxLines` en todos los campos del formulario, listas desplegables con `isExpanded` y título «Detalle».
- **Aceptado:** Una constante (`_lineasDeError`) compartida por los cuatro tipos de campo; título corto en la barra, porque el título completo de la competencia ya está en la cabecera.
- **Rechazado / corregido:**
  - La primera versión (4 líneas de error) no alcanzaba para el mensaje de enlace inválido a 360 dp y 2.0; se subió a 6.
  - La prueba nueva encontró un desbordamiento que no se había pedido: las listas de Categoría y Modalidad medían el ancho de su opción más larga. Se corrigió con `isExpanded: true`.
  - No se usó un tema global de `InputDecoration`: el formulario se prueba suelto, sin el tema de la app, y el arreglo debía valer ahí también.
- **Verificación:** `test/modulo0_texto_grande_test.dart` (3 pruebas a 360 dp y texto 2.0: errores completos, error de enlace en varias líneas y título sin cortar). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 93/93.
- **Commit / PR:** commit «fix: textos que se cortaban con letra grande» en `feat/fases-2-3` (sin PR).

---
## 2026-11-11 · @AlexDLG1 — Pulido de UX, fase 1 (commit `13adee4`)

- **Herramienta:** Claude en claude.ai: implementado con Claude Fable 5.2 y verificado con Claude Opus 5.5, por encargo de Alex.
- **Especificación:** Pulir el Feed, el Detalle y el formulario sin cambiar la arquitectura (repositorio único, providers de Riverpod): Feed ordenado por fecha con aviso de cuánto falta y el costo en la tarjeta; Detalle con un resumen arriba y botones para copiar; formulario que lleve al primer error y pida confirmar antes de descartar cambios.
- **Resultado:** 15 archivos (1 622 líneas agregadas): `lib/utils/fechas.dart`, `lib/providers/reloj_provider.dart`, `lib/widgets/categoria_estilo.dart`, `lib/widgets/etiqueta.dart`, cambios en `lib/main.dart`, en el Detalle y en el formulario, y cinco archivos de pruebas nuevos.
- **Aceptado:**
  - Orden «próximas primero, finalizadas al final» en la capa de datos, con la hora inyectada (`relojProvider`) para poder probarlo con una fecha fija.
  - Etiquetas de tiempo («Faltan N días», «Hoy», «Mañana», «En curso», «Finalizada») y rótulo «Finalizadas» en el Feed.
  - Colores por categoría con contraste AA comprobado en `test/categoria_estilo_test.dart`.
  - Resumen «Cuándo, Dónde, Costo» en el Detalle, botones de copiar enlace y contacto, y Eliminar dentro de un menú para alejarlo de Editar.
  - Formulario: desplazamiento al primer campo inválido, aviso de fecha pasada que no bloquea y diálogo «¿Descartar cambios?».
- **Rechazado / corregido:**
  - El commit se entregó con 2 de 90 pruebas en rojo; se corrigieron en `0cde13c` (ver la entrada siguiente). Lección: verificar el commit, no el árbol de trabajo.
  - La entrada de bitácora no venía con el commit; se agrega aquí, después.
- **Verificación:** Ver la entrada siguiente: 90/90 pruebas tras `0cde13c`, formato y análisis sin observaciones, y revisión visual a 360 dp con texto a 1.0, 1.3 y 2.0.
- **Commit / PR:** `13adee4` en `feat/pulido-ux-fase1` (sin PR).

---
## 2026-11-11 · @AlexDLG1 — Verificación de la rama `feat/pulido-ux-fase1` y corrección de dos pruebas

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Antes de integrar el pulido de la fase 1, ejecutar `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze` y `flutter test`; si algo falla, corregirlo sin borrar ni debilitar pruebas; revisar Feed, Detalle y Formulario a 360 dp y con texto grande."
- **Resultado:** El commit `13adee4` tal cual fallaba 2 de 90 pruebas. Se corrigieron y la suite queda en 90/90.
- **Aceptado:**
  - `lib/screens/competition_detail_screen.dart`: el texto "Eliminar competencia" del menú va dentro de `Flexible`. Sin eso, la fila se desbordaba 62 px en la prueba y, en un teléfono con texto grande, el menú tiene el mismo problema.
  - `test/competition_detail_content_test.dart`: `pumpAndSettle()` después de cada `scrollUntilVisible`.
- **Rechazado / corregido:**
  - En el árbol de trabajo había un arreglo sin commit que bajaba el paso de desplazamiento de 160 a 50 px. Se investigó antes de aceptarlo: la causa no era el tamaño del paso. `scrollUntilVisible` termina con `ensureVisible`, que mueve la lista pero no la vuelve a dibujar; la búsqueda siguiente miraba la posición anterior, no veía la tarjeta de Modalidad y el arrastre extra la dejaba arriba de la pantalla (`find.text` ignora lo que está fuera de pantalla). Con 50 px pasaba solo porque el paso es menor que el alto de una tarjeta. Se restauró 160 px y se agregó el `pumpAndSettle()`; las mismas verificaciones, sin quitar ninguna.
- **Verificación:**
  - Línea base en un worktree temporal de `13adee4`: `flutter test` 88/90 (fallaban "El detalle presenta datos generales y cómo participar" y "Eliminar está en el menú de opciones y pide confirmación").
  - Tras la corrección: `dart format --set-exit-if-changed lib test` 0 cambios, `flutter analyze` sin observaciones, `flutter test` 90/90.
  - Revisión visual sin emulador: esta computadora no tiene SDK de Android (`flutter doctor`: *Unable to locate Android SDK*). En su lugar, una prueba temporal fuera del repositorio dibujó Feed, Detalle, menú, Formulario (vacío, con errores y diálogo de descartar) a 360×780 dp con Roboto y escalas de texto 1.0, 1.3 y 2.0: ningún desbordamiento. Hallazgos pendientes: a 2.0 los mensajes de error del formulario se cortan con "…" y el título "Detalle de competencia" se corta desde 1.3. Las capturas usan el repositorio falso, así que no reflejan el orden por fecha (que se aplica en la capa SQLite).
- **Commit / PR:** commit en `feat/pulido-ux-fase1` (sin PR: el equipo integra ramas a `main` directamente).

---
## 2026-11-05 · @Pabloricalderon — Issue #22: pruebas de estados asíncronos del Detalle

- **Herramienta:** ChatGPT (OpenAI).
- **Especificación:** Se solicitó revisar la rama compartida `feat/22-estados-detalle` y preparar un patch para implementar las pruebas correspondientes al Issue #22. Se estableció como restricción respetar la implementación de Alex, no modificar el código de producción del Detalle y conservar las pruebas existentes del Feed, la navegación y el Issue #9.
- **Resultado:** Patch con modificaciones en `test/fakes/fake_competencias_repository.dart`, `test/navigation_test.dart` y `test/competition_detail_content_test.dart`, además del nuevo archivo `test/detail_states_test.dart`.
- **Aceptado:**
  - Extensión de `FakeCompetenciasRepository` para controlar las respuestas por identificador y registrar las consultas realizadas.
  - Cuatro pruebas de widget para verificar carga, error con recuperación mediante Reintentar, competencia no encontrada y presentación correcta de datos.
  - Comprobación de que no se producen reintentos automáticos después de un error.
  - Adaptación de las pruebas anteriores al constructor `CompetitionDetailScreen(competitionId: ...)` y al uso de `ProviderScope`, conservando las verificaciones existentes.
- **Rechazado / corregido:**
  - No se modificó `lib/main.dart` ni `lib/screens/competition_detail_screen.dart`, ya que su implementación corresponde a Alex.
  - Se descartó crear una rama independiente desde `main`, utilizando la rama compartida `feat/22-estados-detalle`.
  - No se incorporaron dependencias nuevas, servicios externos ni funcionalidades fuera del alcance del Issue #22.
  - Se corrigió el formato de `test/detail_states_test.dart` después de aplicar el patch.
  - No se realizó commit ni push antes de completar las verificaciones locales.
- **Verificación:** Se aplicó el patch sin conflictos mediante `git apply`. `flutter analyze` y `dart analyze` finalizaron sin observaciones. `flutter test` terminó con **32 pruebas aprobadas**. `git diff --check` no mostró problemas. Las verificaciones corresponden a la rama local antes de incorporar las actualizaciones pendientes de `main`.
- **Commit / PR:** Commit de pruebas `8d4c698`, publicado en `feat/22-estados-detalle`. Integración de `main` mediante los commits `ddaf911` y `b4e141c`. Issue #22: https://github.com/Casttle22/pdm2026d-equipo-04-competihub/issues/22. PR pendiente de apertura.

- **Actualización 2026-11-05 — Integración final con main:**
  - **Especificación:** Se solicitó incorporar los cambios recientes de `main` a la rama compartida del Issue #22, resolver los conflictos provocados por los PR #28 y #29 y conservar tanto las pruebas del Detalle como las funcionalidades de CRUD, sin sobrescribir el trabajo de los compañeros.
  - **Resultado:** Se integró `origin/main` mediante un merge normal y se resolvieron dos conflictos: `lib/screens/competition_detail_screen.dart` y `test/fakes/fake_competencias_repository.dart`.
  - **Aceptado:** Se conservó la versión de `competition_detail_screen.dart` proveniente de `main`, que incluye los estados asíncronos y las funcionalidades recientes de edición y eliminación. En el repositorio falso se conservaron `respuestaPorId`, `llamadasPorId` e `idsConsultados`, manteniendo también la búsqueda por identificador utilizada en las pruebas del CRUD.
  - **Rechazado / corregido:** No se reemplazó el repositorio falso únicamente con la versión de `main`, porque se habrían perdido las capacidades necesarias para simular errores, respuestas controladas y conteos de consultas. Tampoco se descartaron los cambios de producción del CRUD ni se realizó un push forzado. Se descartó una versión antigua con marcadores de conflicto que VS Code conservaba sin guardar, manteniendo el archivo correcto del disco.
  - **Verificación local:** Después de resolver los conflictos, `flutter test` finalizó con **50 pruebas aprobadas**. `flutter analyze` y `dart analyze` terminaron sin observaciones. `dart format --output=none --set-exit-if-changed lib test` verificó 19 archivos sin cambios. `git diff --cached --check` no detectó problemas.
  - **Publicación:** Merge `b4e141c` publicado correctamente en `feat/22-estados-detalle`. Queda pendiente la ejecución del CI del PR, la evidencia visual requerida y la revisión independiente.

---

## 2026-10-29 · @AlexDLG1 — Issue #10: verificación del flujo principal de M1

- **Herramienta:** Claude (Anthropic).
- **Especificación:** Se pidió confirmar mi rol tras el cambio de parejas (Detalle con Ricardo, Issue #10), leer el estado del repositorio sin modificarlo, preparar una matriz de 11 casos para verificar el flujo principal de M1, extraer fotogramas de mis videos de pantalla y redactar el documento de verificación. Restricciones: registrar solo lo observado, no agregar funciones y no cerrar el #10 sin revisión independiente.
- **Resultado:** Una matriz de casos, fotogramas recortados de dos videos (27/10 y 29/10) y el borrador de `docs/qa/verificacion_flujo_m1.md`.
- **Aceptado:** La matriz de 11 casos y la estructura del documento (versión, comandos, casos, observaciones, límites). Los fotogramas recortados al área del navegador. La comparación de `73a7826` con `41388e5` por el hash del árbol de archivos, que muestra que lo probado el 27/10 es el mismo código que hoy está en `main`. Esa comparación no sustituye la repetición de hoy.
- **Rechazado / corregido durante el trabajo:**
  - El primer borrador de textos y rama fue para el Feed. Quedó obsoleto cuando mi pareja de S14 resultó ser Detalle (con Ricardo), y se reemplazó.
  - Comandos que corrí dentro de la carpeta del ZIP en OneDrive, que no es un repositorio, dieron errores y no se usaron. Se repitieron en `C:/dev/pdm2026d-equipo-04-competihub`.
  - Se descartaron capturas con una notificación de la Herramienta Recortes encima, con texto de otra ventana al fondo, de la pestaña Elements de DevTools y duplicadas.
  - No se afirmó "sin errores" en la consola hasta abrir el panel Issues. Allí había un aviso de función obsoleta del SDK de Dart y un mensaje informativo del navegador, y los dos quedaron en el documento.
  - La primera extracción de fotogramas del video de hoy salió desfasada en el tiempo y varias capturas no mostraban el paso que decían. Se descartó y se eligieron de nuevo viendo todos los fotogramas, uno cada 0,2 s.
  - El caso 10 con Todas solo se había visto a mano el 27/10, sin captura. Quedó con captura al repetirlo hoy.
  - Tras la revisión de Ricardo (cambios solicitados) se pidieron tres ajustes al PR #24: sincronizar la rama con `main` y resolver el conflicto de esta bitácora conservando las entradas de todos, agregar al documento la nota del PR #23 integrado (`5b57c08`) y no marcar la prueba en dispositivo o emulador, porque solo se probó en Chrome web. Se hicieron los tres.
- **Verificación:** Comandos que ejecuté el 29/10/2026 sobre `main` en `41388e5`: formato sin cambios en 7 archivos, `flutter analyze` sin observaciones y `flutter test` con 21 pruebas aprobadas. Recorrido manual en Chrome grabado en video (casos 1 a 10). El hash del árbol de `73a7826` y el de `41388e5` es el mismo, comprobado con `git rev-parse` en un clon de solo lectura que usó el asistente, no yo. Se puede repetir con los comandos del documento. No se repitieron sobre `main` la pantalla estrecha ni la consola. El resultado del CI de este PR se ve en el propio PR.
- **Commit / PR:** PR de documentación del Issue #10 (este PR). Issue #10: https://github.com/Casttle22/pdm2026d-equipo-04-competihub/issues/10.
- **Actualización 2026-11-04:** tras integrar el PR #24 (`b8d49a4`), se repitieron los casos 1, 3, 5, 6, 9 y 10 sobre `main` y se documentaron en una sección nueva de `docs/qa/verificacion_flujo_m1.md`. Se pidió a Claude revisar tres videos de pantalla, extraer los fotogramas de cada caso y redactar la sección. Se descartó la primera captura del caso 1 porque la ventana de OBS y un ícono de cámara tachada tapaban el Feed, y se usó el arranque de un segundo video. El primer video probaba el caso 10 solo con Esports, así que se grabó un tercero con los cinco filtros. Cada captura se eligió viendo el filtro seleccionado y el contador, y la recarga en un detalle, que vuelve al Feed, se anotó como observación sin corregirla. Verificación: comandos del 04/11/2026 sobre `b8d49a4`: formato sin cambios en 12 archivos, `flutter analyze` sin observaciones y `flutter test` con 28 pruebas aprobadas. El resultado del CI se ve en el PR.

---

## 2026-10-29 · @ALECARRIUMES — Actualización del PR #23 (Feed, Issue #21) tras integrar el PR #20

- **Herramienta:** Claude Code (Claude Opus 5.5), con instrucciones preparadas por Alejandro.
- **Especificación:** "Incorporar el `main` actual (`41388e5`, PR #20 integrado con *Squash and merge*) en `feat/21-estados-feed` mediante un merge normal, sin rebase, rama nueva ni *force push*; conservar íntegras las entradas de Ricardo y nuestra en la bitácora; actualizar la sección 14 de la estrategia de datos y las referencias ya superadas; verificar 28 pruebas y publicar en el PR #23 sin integrarlo. No modificar el Detalle ni implementar el Issue #22."
- **Resultado:** merge de `origin/main` en la rama sin conflictos (la fusión automática ubicó la entrada de Ricardo y la nuestra en bloques distintos de la bitácora). Se incorporaron el contenido ampliado de `CompetitionDetailScreen`, `test/competition_detail_content_test.dart` (3 pruebas) y el registro de @Pabloricalderon del Issue #9.
- **Aceptado:** commit de merge separado del commit documental. La entrada de Ricardo se conserva íntegra y la nuestra del 2026-10-26 solo recibe actualizaciones fechadas; el orden queda del más reciente al más antiguo. En `docs/architecture/estrategia_estado_datos.md` la sección 14.4 pasa a "ratificado" (Wesley, Ricardo y Alex) y se agrega el historial en lugar de borrar la redacción del 26/10.
- **Rechazado / corregido:**
  - No se usó rebase: los seis commits del Feed ya estaban publicados en el PR #23.
  - No se tocó `lib/screens/competition_detail_screen.dart` más allá de lo que trae `main`: el constructor (`competitionId` + `competitions`) no cambió y el Feed sigue llamándolo igual.
  - Las frases históricas de la entrada del 2026-10-26 se mantienen y se completan con actualizaciones fechadas, sin reescribir lo que era cierto en ese momento.
- **Verificación (local, árbol fusionado):** `flutter pub get` exit 0; `dart format --output=none --set-exit-if-changed lib test` exit 0 (12 archivos, 0 cambios); `flutter analyze` exit 0, sin observaciones; `flutter test --reporter expanded` exit 0, **28 pruebas aprobadas** (18 de M1, 7 de Arquitectura y Feed, 3 del Issue #9); `git diff --check` sin observaciones. Revisión de código: `competenciasProvider` y `competenciaPorIdProvider` conservan `retry: (_, _) => null`; el Feed sigue observando `competenciasProvider` con `skipLoadingOnRefresh: false`. El resultado de GitHub Actions de esta actualización queda registrado en la descripción del PR #23.
- **Commit / PR:** merge `8b72b99` y el commit documental que agrega esta entrada, en `feat/21-estados-feed`. PR #23: https://github.com/Casttle22/pdm2026d-equipo-04-competihub/pull/23. Issue #21: https://github.com/Casttle22/pdm2026d-equipo-04-competihub/issues/21.

---
## 2026-10-25 y 2026-10-27 · @Pabloricalderon — Issue #9: Detalle informativo de competencias

- **Herramienta:** ChatGPT.
- **Especificación:** Se solicitó analizar el estado existente del repositorio CompetiHub, los documentos del proyecto y los criterios del Issue #9 para preparar un patch que completara la información de la pantalla de detalle. Se indicó conservar el modelo `Competencia`, reutilizar los datos ficticios de M1, respetar la navegación implementada en el Issue #8 y evitar nuevas dependencias o funcionalidades fuera del MVP.
- **Resultado:** Se propuso un patch para ampliar `lib/screens/competition_detail_screen.dart` y agregar `test/competition_detail_content_test.dart`, con información general, requisitos, reglas, costo, instrucciones de participación y campos opcionales.
- **Aceptado:** Se incorporó la presentación de la información de cada competencia utilizando su identificador y los datos del modelo existente. Se mantuvo la separación entre información general e información para participar, el diseño de tarjetas y el uso de datos ficticios. Se agregaron tres pruebas de widget para comprobar contenido, selección de competencias y campos opcionales.
- **Rechazado / corregido durante el trabajo:**
  - Se mantuvo fuera del alcance la inscripción interna, autenticación, pagos, APIs externas y nuevas arquitecturas.
  - El commit inicial `44e1b28` se realizó en la rama del Issue #8. Se corrigió creando `issue-9-detalle-informativo` desde `origin/main` y trasladando únicamente ese commit mediante `cherry-pick`, generando `a4f0fdd`.
  - Se incorporaron posteriormente los cambios recientes de `main` mediante un merge sin conflictos, conservando la implementación del Issue #9.
  - El formato pendiente de `test/navigation_test.dart` se resolvió al integrar la corrección que ya había sido preparada en el PR #19, sin introducir cambios ajenos al Issue #9.
  - No se realizó una reescritura completa de la aplicación ni se sustituyeron las decisiones técnicas de M1.
- **Verificación:** Después de incorporar `main`, se ejecutaron localmente:
  - `dart format --output=none --set-exit-if-changed lib test`: 7 archivos verificados, 0 cambios.
  - `flutter analyze`: sin problemas detectados.
  - `flutter test`: 21 pruebas aprobadas.
  - GitHub Actions sobre el commit `2ce074b`: ejecución completada satisfactoriamente, incluyendo formato, análisis y pruebas.
  - Las pruebas automatizadas comprueban el uso de diferentes competencias y la presentación de campos opcionales. La revisión técnica de Alejandro no identificó problemas funcionales.
- **Commit / PR:** Commit inicial `a4f0fdd`; actualización de rama `2ce074b`. PR #20: https://github.com/Casttle22/pdm2026d-equipo-04-competihub/pull/20. Issue #9: https://github.com/Casttle22/pdm2026d-equipo-04-competihub/issues/9.
---

## 2026-10-26 · @ALECARRIUMES — Repositorio compartido, providers y estados del Feed (S14 Parte B)

- **Herramienta:** ChatGPT, como asistente de planificación técnica de Alejandro, y Claude Code (Claude Opus 5.5) para auditar el paquete de coordinación S14 v2.1 y el estado de GitHub, implementar los cambios, ejecutar las comprobaciones y hacer los commits locales.
- **Planificación con ChatGPT (propuestas, no decisiones del equipo):** ayudó a definir los límites de implementación (solo Arquitectura y Feed, sin push ni PR), la secuencia de trabajo por commits pequeños, el contrato propuesto de repositorio y providers, la preservación temporal del constructor de `CompetitionDetailScreen`, las pruebas con repositorio falso por override y las precauciones de integración con el PR #20. Esas propuestas se convirtieron en instrucciones para Claude Code; en ese momento el contrato seguía pendiente de ratificación por ambas parejas (ratificado el 2026-10-27, ver actualización al final de esta entrada).
- **Especificación:** "Implementar localmente un repositorio asíncrono único sobre `competenciasMock`, providers Riverpod 3 para lista y detalle por id con `retry: (_, _) => null`, el Feed con cargando/error con Reintentar/vacío con acción/datos usando `AsyncValue.when`, y pruebas con repositorio falso por override. Nivel intermedio como `inkash_d` tag `s14-02-leer-async`; sin interfaces abstractas, generadores, API ni SQLite. No cambiar el constructor de `CompetitionDetailScreen` ni archivos del Detalle (#9, PR #20). Conservar las 18 pruebas existentes. No publicar."
- **Resultado:** `lib/repositories/competencias_repository.dart`, `lib/providers/competencias_providers.dart`, `HomeScreen` como `ConsumerStatefulWidget` con cuatro estados, `test/fakes/fake_competencias_repository.dart`, `test/feed_states_test.dart` (4 pruebas), `test/competencias_repository_test.dart` (3 pruebas) y la sección 14 de `docs/architecture/estrategia_estado_datos.md`.
- **Aceptado:** Clase concreta de repositorio y falso que la extiende con contador de llamadas (mismo patrón que la referencia docente). Categoría seleccionada como estado local. Feed que pasa la lista cargada al constructor actual del Detalle. Montaje de las pruebas de M1 con `ProviderScope` y falso, sin quitar verificaciones (41 y 20 `expect` antes y después en `widget_test.dart` y `navigation_test.dart`).
- **Rechazado / corregido:**
  - Se revisó el código fuente de Riverpod 3.4.3 instalado: `when` usa `skipLoadingOnRefresh: true` por defecto, lo que mantendría visible el error anterior al reintentar. Se usa `skipLoadingOnRefresh: false` y la prueba comprueba que, tras Reintentar, aparece la carga y desaparece el error.
  - No se creó una interfaz abstracta para el repositorio: no hay una segunda implementación real.
  - Los commits "integración del Feed" y "adaptación de pruebas" se unieron en uno: por separado, la suite no compilaba (`HomeScreen(competitions: ...)` dejó de existir).
  - El vacío por filtro no puede provocarse solo con los chips (se derivan de los datos cargados); la prueba lo produce recargando el provider con otros datos.
- **Verificación:** Línea base en `main` (`e363382`): `flutter analyze` sin observaciones, `flutter test` 18/18. Tras los cambios: `dart format --output=none --set-exit-if-changed lib test` exit 0, `flutter analyze` sin observaciones, `flutter test` 25/25, `git diff --check` sin observaciones. Prueba de mutación local: al quitar temporalmente `retry: (_, _) => null` de `competenciasProvider`, la prueba de error falló (11 consultas en lugar de 1); se restauró el archivo. Fusión de prueba local con la rama del PR #20 en un worktree temporal: sin conflictos, 28/28 pruebas.
- **Verificación manual (2026-10-26):** compilación web release de `lib/main.dart` sin cambios, ejecutada en Microsoft Edge 156 (headless, controlado por DevTools, ventana de 412×860): carga de las 6 competencias, filtro Esports (2 resultados), apertura del detalle de `mock-esports-01`, regreso con el filtro Esports conservado y vuelta a Todas. Para cargando, error y vacío se usó un *entrypoint* temporal fuera del repositorio que monta `CompetihubApp` con un repositorio de demostración por override (sin cambiar el repositorio normal): se observaron el indicador de carga, el error con Reintentar (al pulsarlo aparece la carga y luego los datos) y el vacío con Volver a cargar (al pulsarlo aparecen los datos). Capturas conservadas fuera de Git. No verificado visualmente: el vacío por filtro con Ver todas, que la interfaz no produce con datos fijos (lo cubre una prueba widget).
- **Commit / PR:** Commits locales en la rama `feat/s14-estados-feed-preparacion`: `37cff9b`, `0303937`, `89a94e2`, `b40ee00`, `9ece438` y el commit documental que agrega esta actualización. PR: pendiente hasta ratificar el contrato y acordar el Issue real con Wesley.
- **Actualización 2026-10-27:** el contrato fue ratificado por Wesley (@Casttle22), Ricardo (@Pabloricalderon) y Alex (@AlexDLG1). Se creó el Issue #21 (Feed) y el Issue #22 (Detalle por id). La rama se publicó como `feat/21-estados-feed` y se abrió el PR #23 (https://github.com/Casttle22/pdm2026d-equipo-04-competihub/pull/23), con el check "Formato, análisis y pruebas" en verde (25 pruebas) y @Pabloricalderon solicitado como revisor.
- **Actualización 2026-10-29:** el PR #20 se integró en `main` (`41388e5`). Wesley revisó el PR #23 sin hallar problemas funcionales bloqueantes y pidió incorporar ese `main`; ver la entrada del 2026-10-29.

---

## 2026-10-24 · @ALECARRIUMES — Sincronización local y preparación CI (S14 Parte A)

- **Herramienta:** OpenCode (asistente de código) y ChatGPT (consultas puntuales) para la preparación inicial; Claude Code para la verificación de formato, la corrección de la bitácora, los commits y la apertura del PR.
- **Especificación:** "Actualizar la copia local de CompetiHub desde origin/main de forma segura (fast-forward), verificar que no hay cambios locales en riesgo, y preparar localmente los archivos de CI (workflow, PR template, CODEOWNERS, bitácora) adaptados del proyecto docente inkash_d tag s14-06-ci, sin copiar reglas de dinero, SQLite ni migraciones."
- **Resultado:** main actualizado a 4f6eaef (coincide con origin/main). Creados `.github/workflows/ci.yml`, `.github/pull_request_template.md`, `.github/CODEOWNERS`, `docs/bitacora-ia.md`. CI simplificado: solo formato, análisis y pruebas (sin APK ni SQLite).
- **Aceptado:** Estructura del workflow del docente (Flutter 3.44.8, job "Formato, análisis y pruebas", concurrencia, checkout, dependencias). Plantilla de PR adaptada a CompetiHub (sin referencias a SQL, dinero en centavos, migraciones). CODEOWNERS con @ALECARRIUMES y @Pabloricalderon propuestos (pendiente confirmación del equipo). Bitácora iniciada con esta entrada.
- **Rechazado / corregido durante el trabajo:**
  - Se descartó el job `apk` del docente: el laboratorio S14 solo exige formato, análisis y pruebas; el APK debug se verá en S17.
  - Se eliminaron referencias a `libsqlite3-dev`, dinero en centavos, `occurredOn`/`createdAtMs`, y migraciones de BD: CompetiHub no usa SQLite ni base de datos.
  - No se ejecutó `git stash` ni `git checkout --` destructivo: la actualización fue fast-forward limpio sin cambios locales en main.
  - Los archivos `pr_body.md` y `pr_body_5.md` sin seguimiento se mantuvieron intactos.
- **Verificación:** La primera corrida de `dart format --output=none --set-exit-if-changed lib test` terminó con **exit 1** (`lib/screens/competition_detail_screen.dart` y `test/navigation_test.dart` sin formato): el CI habría fallado. En `chore/ci` se aplicó `dart format` solo a esos dos archivos (cambios exclusivamente de formato, sin lógica). Después: formato exit 0, `flutter analyze` exit 0 (sin observaciones), `flutter test` exit 0 (18 pruebas pasadas).
- **Commit / PR:** Pendiente - rama `chore/ci` creada localmente; commit y PR tras confirmar CODEOWNERS con el coordinador (resuelto: ver la actualización siguiente).
- **Actualización 2026-10-26:** integrado en `main` mediante el PR #19 (https://github.com/Casttle22/pdm2026d-equipo-04-competihub/pull/19), aprobado por @Pabloricalderon. Check "Formato, análisis y pruebas" en verde en el PR y en `main` (18 pruebas). Se integró con *merge commit*, no con *Squash and merge* como indica el laboratorio; se deja constancia y no se reescribe el historial de `main`.
