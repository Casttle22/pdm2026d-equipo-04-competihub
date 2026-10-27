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
