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
- **Verificación:** Comandos que ejecuté el 29/10/2026 sobre `main` en `41388e5`: formato sin cambios en 7 archivos, `flutter analyze` sin observaciones y `flutter test` con 21 pruebas aprobadas. Recorrido manual en Chrome grabado en video (casos 1 a 10). El hash del árbol de `73a7826` y el de `41388e5` es el mismo, comprobado con `git rev-parse` en un clon de solo lectura que usó el asistente, no yo. Se puede repetir con los comandos del documento. No se repitieron sobre `main` la pantalla estrecha ni la consola. El resultado del CI de este PR se ve en el propio PR.
- **Commit / PR:** PR de documentación del Issue #10 (este PR). Issue #10: https://github.com/Casttle22/pdm2026d-equipo-04-competihub/issues/10.

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
- **Commit / PR:** Pendiente - rama `chore/ci` creada localmente; commit y PR tras confirmar CODEOWNERS con el coordinador.
