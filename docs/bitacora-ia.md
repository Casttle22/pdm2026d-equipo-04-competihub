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
