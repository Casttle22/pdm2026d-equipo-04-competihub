# Verificación del flujo principal de M1 (Issue #10)

Autor: Alex (@AlexDLG1). Fecha de la verificación: 29/10/2026.

Este documento registra lo que se probó y lo que se vio, con la versión exacta del código. No agrega funciones ni corrige defectos. No reemplaza la revisión independiente, y el Issue #10 sigue abierto hasta que exista.

## Versión probada y entorno

| Dato | Valor |
| --- | --- |
| Rama y commit | `main` en `41388e5` (PR #20, detalle informativo, integrado con squash) |
| Sistema | Windows, un solo verificador |
| Navegador | Chrome (web), con `flutter run -d chrome`, en `localhost` |
| Ventana | Chrome en ventana ancha (escritorio) |
| Flutter | 3.44.8, según `flutter --version` del 27/10/2026. Es la versión que usa el CI |
| Evidencia | Fotogramas de un video de 34 s grabado el 29/10/2026 a las 08:41, recortados al área del navegador |

El video original lo conserva Alex y no se sube al repositorio.

## Comprobaciones automáticas

Ejecutadas por Alex el 29/10/2026 en su clon, con `main` en `41388e5`:

| Comando | Salida |
| --- | --- |
| `git log -1 --oneline` | `41388e5 (HEAD -> main, origin/main, origin/HEAD) feat: completar detalle informativo de competencias (#20)` |
| `dart format --output=none --set-exit-if-changed .` | `Formatted 7 files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test` | `All tests passed!` con 21 pruebas (`+21`) |

## Casos manuales sobre main

Las capturas están en `evidencias/issue-10/main_41388e5/`.

| Caso | Pasos | Esperado | Observado | Captura | Cumple |
| --- | --- | --- | --- | --- | --- |
| 1. Abrir la app | Ejecutar la app | Aparece el Feed | Feed con Todas seleccionado, "6 competencias disponibles" y el aviso de datos ficticios | [01](evidencias/issue-10/main_41388e5/01_caso01_abrir-app_feed-todas.png) | Sí |
| 2. Tarjetas | Mirar la lista y bajar | Se ven las competencias con sus datos | Seis tarjetas con categoría, modalidad, fecha, hora y ubicación: Copa, Reto, Carrera, Olimpiada, Desafío y Liga | [02a](evidencias/issue-10/main_41388e5/02a_caso02_tarjetas-parte-superior.png), [02b](evidencias/issue-10/main_41388e5/02b_caso02_tarjetas-parte-inferior.png) | Sí |
| 3. Filtrar por Esports | Elegir Esports | Solo esa categoría y contador coherente | "2 competencias disponibles": Copa y Liga | [03](evidencias/issue-10/main_41388e5/03_caso03_filtro-esports.png) | Sí |
| 4. Filtrar por Académica | Elegir Académica | Solo esa categoría y contador coherente | "2 competencias disponibles": Reto y Olimpiada | [04](evidencias/issue-10/main_41388e5/04_caso04_filtro-academica.png) | Sí |
| 5. Volver a Todas | Elegir Todas tras filtrar | Vuelven todas las tarjetas | "6 competencias disponibles" con Todas seleccionado | [05](evidencias/issue-10/main_41388e5/05_caso05_volver-a-todas.png) | Sí |
| 6. Abrir una competencia | Tocar una tarjeta | Detalle de esa competencia | Detalle de "Copa ficticia de arena digital" (`mock-esports-01`) | [06](evidencias/issue-10/main_41388e5/06_caso06_detalle-esports-01.png) | Sí |
| 7. Abrir otras competencias | Regresar y tocar otra | El detalle corresponde a la segunda, no a la primera | Cada tarjeta abre su propio detalle: Reto (`mock-academic-01`), Desafío (`mock-other-01`) y Carrera (`mock-sports-01`) | [07a](evidencias/issue-10/main_41388e5/07a_caso07_detalle-academic-01.png), [07b](evidencias/issue-10/main_41388e5/07b_caso07_detalle-otras.png), [07c](evidencias/issue-10/main_41388e5/07c_caso07_detalle-sports-01.png) | Sí |
| 8. Contenido del detalle | Bajar hasta "Información para participar" | Información correcta para ese id | En `mock-academic-01` se ven los requisitos y reglas, el costo, cómo participar y el aviso de datos ficticios | [08](evidencias/issue-10/main_41388e5/08_caso08_info-participar-academic-01.png) | Sí |
| 9. Regreso | Usar la flecha de regreso | Vuelve al Feed | La flecha vuelve al Feed. Su letrero dice "Back" | [09](evidencias/issue-10/main_41388e5/09_caso09_flecha-regreso.png) | Sí |
| 10. Filtro conservado | Filtrar, abrir un detalle, regresar | El filtro sigue aplicado | Al regresar siguen seleccionados el mismo filtro y el mismo contador, con las cinco opciones: Esports (2), Académica (2), Deportiva (1), Otras (1) y Todas (6) | Esports: [10a](evidencias/issue-10/main_41388e5/10a_caso10_esports_detalle.png), [10b](evidencias/issue-10/main_41388e5/10b_caso10_esports_feed-conservado.png). Académica: [10c](evidencias/issue-10/main_41388e5/10c_caso10_academica_detalle.png), [10d](evidencias/issue-10/main_41388e5/10d_caso10_academica_feed-conservado.png). Deportiva: [10e](evidencias/issue-10/main_41388e5/10e_caso10_deportiva_detalle.png), [10f](evidencias/issue-10/main_41388e5/10f_caso10_deportiva_feed-conservado.png). Otras: [10g](evidencias/issue-10/main_41388e5/10g_caso10_otras_detalle.png), [10h](evidencias/issue-10/main_41388e5/10h_caso10_otras_feed-conservado.png). Todas: [10i](evidencias/issue-10/main_41388e5/10i_caso10_todas_detalle.png), [10j](evidencias/issue-10/main_41388e5/10j_caso10_todas_feed-conservado.png) | Sí |
| 11. Estabilidad | Repetir con pantalla estrecha y mirar la consola | Sin desbordes ni excepciones | En esta pasada, con ventana ancha, no se ve ningún desborde. La pantalla estrecha y la consola no se repitieron sobre `main`: ver la sección siguiente | Ninguna de esta pasada | Parcial |

Capturas extra de esta pasada: filtros Otras ([12a](evidencias/issue-10/main_41388e5/12a_extra_filtro-otras.png)) y Deportiva ([12b](evidencias/issue-10/main_41388e5/12b_extra_filtro-deportiva.png)), cada uno con "1 competencia disponible".

## Verificación previa del 27/10/2026 sobre 73a7826

El 27/10/2026 Alex probó `73a7826`, la cabeza del PR #20, antes de que se integrara. El commit `41388e5` es el squash de ese PR, y los archivos de los dos commits son idénticos: el árbol de archivos tiene el mismo hash (`9c8a01d5a5b944231cb2d54bdc624611e9ab4b64`). Se puede comprobar con:

```
git fetch origin pull/20/head
git rev-parse "73a7826^{tree}" "41388e5^{tree}"
```

En esa pasada, con el mismo código, se registró lo que no se repitió hoy:

- **Pantalla estrecha (400 px):** el Feed con Académica seleccionada ([11a](evidencias/issue-10/previa_73a7826/11a_caso11_feed-400px.png)) y el detalle ([11b](evidencias/issue-10/previa_73a7826/11b_caso11_detalle-400px.png)) se ven sin desbordes.
- **Consola de Chrome DevTools (modo debug):** 0 errores y 0 advertencias en la pestaña Console ([13a](evidencias/issue-10/previa_73a7826/13a_consola_sin-errores-ni-advertencias.png)), y 32 mensajes verbose de rendimiento del navegador (`[Violation] ... handler took N ms`).
- **Panel Issues** ([13b](evidencias/issue-10/previa_73a7826/13b_consola_panel-issues.png)): 1 aviso de función obsoleta del entorno web de Dart (`Intl.v8BreakIterator`, en `dart_sdk.js`) y 1 mensaje informativo del navegador sobre el historial de sesión. Ninguno apunta a código del proyecto.
- **Pruebas:** 21 aprobadas, análisis sin observaciones y formato sin cambios, igual que hoy.

No se probó texto ampliado.

## Observaciones

Son cosas que se ven en las capturas. Ninguna se corrigió aquí y ninguna impide el flujo.

1. En ventana ancha el trofeo del encabezado del detalle queda hacia el centro y no junto al borde ([06](evidencias/issue-10/main_41388e5/06_caso06_detalle-esports-01.png)).
2. El letrero del botón de regreso dice "Back", en inglés, aunque la app está en español ([09](evidencias/issue-10/main_41388e5/09_caso09_flecha-regreso.png)).
3. Las tarjetas siguen el orden de los datos de prueba, no el cronológico ([02a](evidencias/issue-10/main_41388e5/02a_caso02_tarjetas-parte-superior.png), [02b](evidencias/issue-10/main_41388e5/02b_caso02_tarjetas-parte-inferior.png)).
4. Varias fechas de los datos de prueba ya pasaron: por ejemplo 20/10/2026 ([06](evidencias/issue-10/main_41388e5/06_caso06_detalle-esports-01.png)) y 24/10/2026 ([07a](evidencias/issue-10/main_41388e5/07a_caso07_detalle-academic-01.png)).

## Límites

- Solo Chrome en web, con una persona verificando. No se probó en un dispositivo real ni con texto ampliado.
- Los datos son ficticios. Esta verificación no demuestra utilidad para usuarios.
- Esta pasada es de M1. `main` todavía no incluye los estados de carga, error y vacío del Feed (S14, PR #23).
- Los casos 11 (pantalla estrecha) y la consola se registraron sobre `73a7826`, no sobre `41388e5`.

## Pendiente

- Repetir los casos 1, 3, 5, 6, 9 y 10 sobre el `main` que resulte después de integrar el PR #23, con su SHA, porque cambia el flujo del Feed.
- Revisión independiente de este documento, a cargo de alguien que no sea su autor. El Issue #10 no se cierra antes.
