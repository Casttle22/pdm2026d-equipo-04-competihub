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
## 2026-11-12 · @AlexDLG1 — Imágenes de portada de las competencias de ejemplo

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Imágenes LOCALES en assets/imagenes/, declaradas en pubspec.yaml; una por competencia acorde a su categoría (esports, programación, carrera, lógica, ilustración y estrategia). Registra en docs/ la fuente y la licencia de cada imagen. Adapta imagen_competencia.dart para aceptar un asset local o una URL, con el fondo de categoría como respaldo. Que se vean bien en el carrusel, en las tarjetas y en el encabezado del Detalle."
- **Resultado:** 9 fotos de Wikimedia Commons (6 portadas y 3 de galería para el siguiente cambio) en `assets/imagenes/`, reducidas a 1000 px y sin metadatos (~880 KB en total); `docs/creditos_imagenes.md` con autor, licencia y enlace de cada una; `lib/data/creditos_imagenes.dart`; `ImagenCompetencia` con `Image.asset` para «assets/…», `Image.network` para http(s) y el fondo de categoría para todo lo demás o si falla; portada en el cuadro de 64 dp de las filas; foto de 190 dp en el Detalle con su crédito debajo; migración v8 solo de datos.
- **Aceptado:**
  - Fuente: Wikimedia Commons, porque su API devuelve autor y licencia verificables de cada archivo (Unsplash y Pexels no los exponen sin clave). Solo dominio público, CC0 o CC BY; ninguna «compartir igual». Dos fotos son CC BY 4.0: la app muestra el crédito visible bajo la imagen, como pide esa licencia.
  - Migración v8 (sin cambio de esquema): pone la portada a las filas de ejemplo que no tengan imagen; no pisa una imagen elegida al editar un ejemplo ni toca las competencias creadas en la app.
  - El campo «Enlace de imagen» del formulario acepta también «assets/imagenes/…»: sin eso, no se podía guardar un ejemplo editado.
  - En el carrusel, el velo oscurece desde antes de la mitad para que el título blanco se lea también sobre fotos claras.
- **Rechazado / corregido:**
  - Se revisó cada foto antes de usarla. Se descartaron: un control con la marca M-TECH y otros de marcas conocidas (para no sugerir patrocinio), una foto de código que mostraba en pantalla un texto poco apropiado, dibujos de un artista real (darían a entender que participó en el concurso ficticio) y fichas antiguas de go que no se reconocen como juego.
  - Pruebas ajustadas porque los ejemplos ahora tienen portada, verificando lo mismo: «limpiar opcionales» también vacía el campo de imagen (`competition_form_screen_test`); la prueba de «sin imagen» usa una competencia propia sin imagen (`inicio_nuevo_test`); la foto empuja «Información general» y la prueba se desplaza hasta ella (`navigation_test`).
- **Verificación:** `test/imagenes_test.dart` (10 pruebas: cada ejemplo con portada local existente, distinta y con crédito; cada imagen incluida en los créditos y en docs; assets declarados; migración v7→v8 que respeta una imagen elegida y no toca a la persona; asset vs. URL vs. fuente inválida; crédito en el Detalle; portada en el cuadro de 64 dp; el formulario guarda un ejemplo con portada local; 360 dp con texto 2.0). Capturas generadas en pruebas del carrusel, las filas y el Detalle. Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 290/290.
- **Commit / PR:** commit «feat: portadas locales para las competencias de ejemplo» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Filtro de modalidad en el Inicio

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "En FiltroUbicacion y la píldora del Inicio, cambia las opciones a «Todas las modalidades», «Presencial», «Virtual» e «Híbrida». Cada opción muestra solo las competencias de esa modalidad; la híbrida ya no aparece en Presencial ni en Virtual. Íconos: public, place_outlined, laptop y sync_alt. Quita la mención a Quetzaltenango de la píldora; la ciudad sigue en los datos de ejemplo y en el mapa."
- **Resultado:** `FiltroUbicacion` con cuatro opciones y la modalidad exacta que deja pasar; `coincideConUbicacion` compara la modalidad sin casos especiales; la píldora muestra «Todas», «Presencial», «Virtual» o «Híbrida» y el menú «Todas las modalidades» y las tres modalidades.
- **Aceptado:** La píldora sigue mostrando un texto corto («Todas») y el menú el texto completo («Todas las modalidades»), para que quepa en el encabezado a 360 dp.
- **Rechazado / corregido:**
  - Se reemplaza la decisión anterior (Quetzaltenango = presencial e híbrida; Online = virtual e híbrida) por la nueva indicación de Alex. Las dos pruebas que verificaban la regla vieja ahora verifican la nueva: cada opción deja solo su modalidad (`test/busqueda_test.dart`, `test/inicio_rediseno_test.dart`).
  - No se renombró `FiltroUbicacion` a «FiltroModalidad» para no tocar más archivos de los pedidos; queda anotado como posible limpieza.
- **Verificación:** Prueba unitaria con las tres modalidades contra cada opción; prueba de widget que elige cada opción y comprueba el conteo, que todas las filas son de esa modalidad, que Destacados se oculta y que no aparece «Quetzaltenango». La prueba de 360 dp con texto 2.0 abre el menú sin desbordes. Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 280/280.
- **Commit / PR:** commit «feat: filtro de modalidad en el Inicio» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Rediseño 5/5: formulario

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Campos con borde redondeado, agrupados bajo subtítulos en gris («Información general», «Participación», «Ubicación»…). «Fecha y hora» en un solo campo con ícono de calendario, que abra la fecha y luego la hora. Botón «Guardar cambios» (o «Crear competencia») azul, de ancho completo, fijo abajo."
- **Resultado:** `lib/widgets/decoracion_campo.dart` (`decoracionCampo` con radio 12 y fondo blanco, y `CampoConEtiqueta`), formulario reorganizado en «Información general», «Fecha y hora», «Ubicación», «Participación», «Formato y premios» y «Etapas y cronograma», campos de fecha renombrados a «Fecha y hora de inicio *» y «Fecha y hora de fin (opcional)» con la sugerencia «Elegir fecha y hora», y botón fijo de 52 dp en una barra blanca con sombra. El diálogo de etapas usa la misma decoración.
- **Aceptado:**
  - La etiqueta de cada campo va encima del borde, como texto que puede ocupar varias líneas, unida al campo con `MergeSemantics` para que el lector de pantalla los anuncie juntos.
  - La decoración se define en un helper y no solo en el tema, porque las pruebas montan el formulario sin el tema de la app.
- **Rechazado / corregido:**
  - Con las etiquetas dentro del borde, a 360 dp y texto 2.0 «Fecha y hora de…» se cortaba con «…» y no se sabía si era el inicio o el fin. Se probó una etiqueta de varias líneas dentro del borde: se salía del campo y se encimaba con el de arriba. Se descartó y la etiqueta pasó encima del campo.
  - Las pruebas existentes del formulario pasaron sin cambios (buscan los campos por su clave).
- **Verificación:** `test/formulario_rediseno_test.dart` (5 pruebas: subtítulos grises, «Crear competencia»/«Guardar cambios» de ancho completo, campo de fecha y hora con calendario que abre fecha y luego hora, borde redondeado y fondo blanco, y etiquetas completas a 360 dp con texto 2.0). Capturas generadas en pruebas a 400 dp y a 360 dp con texto 2.0, sin desbordes. Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 280/280.
- **Commit / PR:** commit «feat: formulario rediseñado según las maquetas» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Rediseño 4/5: Detalle

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Cabecera en tarjeta con degradado azul: etiqueta de categoría arriba a la izquierda, ícono grande a la derecha, título en blanco grande y debajo «Competencia ficticia de prueba», solo en las de ejemplo. Secciones «Información general» e «Información para participar». Tarjetas blancas en dos columnas, con el ícono dentro de un círculo azul claro, la etiqueta en negrita y el valor debajo; una tarjeta ocupa el ancho completo si su texto es largo. Conservar el resumen, Guardar, Cómo llegar, Compartir, Copiar, el mapa pequeño, las etapas y el estado de inscripción, con el mismo estilo. El título de la barra debe caber."
- **Resultado:** `_Cabecera` con degradado azul, `_DetailInfoCard` como `TarjetaBlanca` con círculo azul claro, `_Rejilla` (dos tarjetas cortas por fila con la misma altura), `_TituloSeccion`, resumen como tarjeta blanca y cronograma dentro de una tarjeta. Se quitó el ícono pintado de fondo de la cabecera anterior.
- **Aceptado:**
  - Regla de la rejilla: una tarjeta es corta si su valor tiene hasta 24 caracteres, una sola línea y no tiene botón. Dos cortas seguidas comparten fila; el resto va a ancho completo.
  - Con texto del sistema de 1,6× o más, todas las tarjetas van en una columna: dos columnas de 150 dp no alcanzan para texto a 2.0.
  - El ícono de las tarjetas pasa al azul de la marca (antes usaba el color de la categoría); el color de la categoría queda en su etiqueta de la cabecera.
  - Se conservan las dos columnas de página desde 600 dp, el «Identificador» de los ejemplos (lo usan las pruebas de navegación) y el título «Detalle».
- **Rechazado / corregido:**
  - Las pruebas existentes del Detalle pasaron sin cambios: se conservaron los textos de cada etiqueta y valor.
  - Revisión con capturas generadas en pruebas (Roboto, 400 dp y 360 dp con texto 2.0) en lugar de la ventana de Windows, por la misma razón que en el commit anterior; sin desbordes.
- **Verificación:** `test/detalle_rediseno_test.dart` (6 pruebas: rótulo de ficticia solo en ejemplos, títulos de sección, tarjetas cortas en la misma fila y largas a ancho completo, una columna con texto 2.0, círculo azul claro del ícono, y 360 dp con texto 2.0 recorriendo todo el Detalle). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 275/275.
- **Commit / PR:** commit «feat: Detalle rediseñado según las maquetas» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Rediseño 3/5: barra inferior con Explorar

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Íconos con su texto y el activo en azul. Las secciones son Inicio, Explorar (búsqueda con todos los filtros), Mapa y Mis eventos. No agregues «Perfil»: la app no tiene cuentas."
- **Resultado:** `PantallaPrincipal` con cuatro pestañas; `lib/screens/explorar_screen.dart` con buscador, filtros de categoría, modalidad, formato, «Inscripción abierta» e «Incluir finalizadas», conteo, «Quitar filtros» y estado vacío; `FiltrosExplorar` y `aplicarFiltros` en `lib/utils/busqueda.dart`; `PildoraFiltro` extraída a `lib/widgets/pildora_filtro.dart` para compartirla con el Inicio.
- **Aceptado:**
  - Lógica de filtros como función pura, probada sin interfaz. Explorar muestra por defecto solo lo que todavía se puede aprovechar; las finalizadas se incluyen con su filtro.
  - «Ver todos >» del Inicio y «Explorar competencias» de Mis eventos llevan a la pestaña Explorar. Cada pestaña conserva sus filtros al cambiar de sección.
- **Rechazado / corregido:**
  - A 360 dp con texto 2.0, «Mis eventos» se partía en dos líneas con cuatro pestañas: el límite de escala de los rótulos de la barra bajó de 1,3× a 1,1× (los íconos y el resto de la app siguen la escala del sistema).
  - No se pudo revisar Explorar en la ventana de Windows: Flutter no redibuja una ventana tapada y traerla al frente con foco habría interrumpido el trabajo de Alex. Se revisó con capturas generadas en pruebas (Roboto, 400 dp con texto normal y 360 dp con texto 2.0; sin desbordes).
  - Pruebas ajustadas, verificando lo mismo: con Explorar, el filtro «Esports»/«Académica» existe en dos pestañas y la búsqueda se limita al Inicio (`navigation_test`, `barra_inferior_test`); «Explorar competencias» de Mis eventos ahora lleva a Explorar (`mis_eventos_test`); la barra tiene cuatro pestañas (`barra_inferior_test`).
- **Verificación:** `test/explorar_test.dart` (11 pruebas: finalizadas fuera por defecto, cada filtro, inscripción abierta, combinación con búsqueda y orden, `hayFiltros`, grupos y conteo, «Quitar filtros», incluir finalizadas, sin resultados, abrir el Detalle y 360 dp con texto 2.0) y `test/barra_inferior_test.dart` (cuatro pestañas sin «Perfil», Explorar en el recorrido, «Ver todos» con filtros conservados). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 269/269.
- **Commit / PR:** commit «feat: barra inferior con Explorar» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Rediseño 2/5: Inicio

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Encabezado con ícono de calendario azul y «CompetiHub» en negrita; a la derecha, un selector de ubicación en píldora («Quetzaltenango / Online») que filtre entre presencial y virtual. Buscador grande redondeado («Buscar torneos, hackathons, organizadores…»). Filtros en una fila con desplazamiento horizontal, píldoras con ícono; la seleccionada azul rellena con texto blanco. «Eventos destacados» con «Ver todos >»: carrusel de tarjetas grandes (~200 px) con imagen o degradado de la categoría con su ícono; encima título, subtítulo, organizador, fecha y modalidad con lugar, en blanco sobre un velo oscuro; puntos indicadores. «Próximos eventos» con «Ver todos >»: filas con cuadro de 64 px, título, fecha y lugar, etiquetas Individual/Equipos y Presencial/Virtual y botón azul «Detalles». Fechas «14 de nov, 2026» o «12 - 14 de nov, 2026»."
- **Resultado:** `lib/screens/inicio_screen.dart` reescrito (encabezado, `_PildoraUbicacion`, buscador, `_PildoraFiltro`, `CarruselDestacados` con puntos, secciones con «Ver todos»), `lib/widgets/tarjeta_competencia.dart` (fila nueva con `CuadroDeCategoria` y tarjeta destacada grande), `formatearFechaCorta` y `formatearRangoCorto` en `lib/utils/fechas.dart`, y `FiltroUbicacion` en `lib/utils/busqueda.dart`.
- **Aceptado (decisiones con Alex):**
  - Píldora con 3 opciones: «Todas», «Quetzaltenango» (presenciales e híbridas) y «Online» (virtuales e híbridas).
  - El buscador y los filtros filtran en el Inicio; «Ver todos >» llevará a Explorar (siguiente commit) y solo aparece si hay a dónde ir.
  - Subtítulo de las destacadas: la primera línea de la descripción (no hay campo propio).
  - La búsqueda ahora también mira el organizador, porque el texto del buscador lo promete.
- **Rechazado / corregido (revisando en `flutter run -d windows`):**
  - La ventana de «400 px» medía en realidad 252 dp: Windows está escalado a 1,5×. Se revisó con una ventana de 616 px físicos (≈410 dp), como un teléfono.
  - El carrusel recortaba primero el título; ahora el bloque de texto va abajo y, si algo no cabe, se recorta por abajo. Las etiquetas de arriba ocupaban dos líneas y escondían la fecha y la modalidad: pasaron al bloque de texto («15 de nov, 2026 · Faltan 3 días» y la inscripción en la línea siguiente). Alto de ~240 dp, que crece con el texto del sistema.
  - Con Guardar en la esquina de la fila, el título quedaba tan angosto que partía palabras («ilustració-n»): Guardar pasó a la fila de abajo, junto a «Detalles».
  - El botón flotante «+» tapaba «Detalles»: «Nueva competencia» pasó al encabezado, junto a la píldora.
  - La fila mostraba solo el ícono de la categoría; se agregó su nombre encima del título, porque el ícono solo es ambiguo.
  - Pruebas ajustadas, verificando lo mismo: la marca ya no está en una `AppBar` (`widget_test`, `tema_test`); «Destacados»/«Próximos» pasan a «Eventos destacados»/«Próximos eventos» y las destacadas se leen de la lista del carrusel, que solo construye las páginas visibles (`inicio_nuevo_test`); la fila muestra «fecha · lugar» en una línea (`widget_test`, `feed_pulido_test`, que ahora filtra por categoría para verificar la fila en vez del carrusel); los filtros pueden quedar fuera de pantalla al volver del Detalle (`navigation_test`); el tiempo restante del carrusel va junto a la fecha (`ejemplos_vigentes_test`).
  - Durante la revisión, la primera versión del script de captura mandaba rueda del ratón y capturaba la pantalla; con otra ventana delante, capturó y desplazó esa ventana. Las capturas se borraron y el script pasó a `PrintWindow` sin entradas de ratón.
- **Verificación:** `test/inicio_rediseno_test.dart` (10 pruebas: encabezado, píldora con sus 3 opciones y conteos, píldora de categoría azul con texto blanco, puntos del carrusel al deslizar, datos de la tarjeta grande, etiquetas y «Detalles» de la fila, rango de fechas, «Ver todos» y 360 dp con texto 2.0), 5 casos de `formatearRangoCorto` en `test/fechas_test.dart` y 2 de búsqueda en `test/busqueda_test.dart`. Windows a ≈410 dp: revisado. Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 257/257.
- **Commit / PR:** commit «feat: Inicio rediseñado según las maquetas» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Rediseño 1/5: estilo general

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Fondo gris azulado muy claro. Tarjetas blancas con radio de 16 y sombra suave. Azul principal #1565C0 o similar, manteniendo contraste AA (test/categoria_estilo_test.dart debe seguir pasando). Tipografía en negrita."
- **Resultado:** `lib/tema.dart` con `fondoApp` (#F3F6FB), `radioTarjeta` (16), `sombraSuave`, `TarjetaBlanca`, campos redondeados con fondo blanco, botones de 48 dp, títulos en negrita y barra inferior blanca con el activo en azul. `lib/widgets/etiquetas_ficha.dart` con los colores de las etiquetas de las maquetas: Individual lila, Equipos azul, Presencial verde, Virtual rojo e Híbrida naranja.
- **Aceptado:**
  - `TarjetaBlanca` dibuja su fondo, radio y sombra sin depender del tema, porque varias pruebas montan pantallas sueltas sin el tema de la app.
  - La superficie del esquema pasa a blanco puro; el fondo de las pantallas es el gris azulado.
- **Rechazado / corregido:**
  - Antes de revisar en Windows se borró la caché de teselas de flutter_map (`%LOCALAPPDATA%\com.example\competihub\fm_cache`, 581 imágenes): guardaba las respuestas «Access blocked» de cuando el identificador era `com.example`. Con la caché limpia, el mapa carga teselas reales con `gt.edu.umes.competihub`.
- **Verificación:** `test/tema_test.dart` suma 8 pares de contraste AA (texto, texto secundario y azul sobre el fondo, y las cinco etiquetas). `flutter run -d windows` con la ventana a 400 px: fondo, tarjetas y negritas correctos, y el mapa con teselas. Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 241/241.
- **Commit / PR:** commit «style: estilo general de las maquetas» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Ejecutar en Windows e identificador propio ante OpenStreetMap

- **Herramienta:** cambios hechos por Alex fuera de esta sesión (para correr `flutter run -d windows`), integrados y verificados con Claude Code (Claude Opus 5.5).
- **Especificación:** "Poder revisar la app en Windows con `flutter run -d windows`."
- **Resultado:** `lib/main.dart` activa la variante FFI de SQLite en escritorio; `sqflite_common_ffi` pasa de dependencia de desarrollo a dependencia normal; `idDeLaApp` cambia de `com.example.competihub` a `gt.edu.umes.competihub`.
- **Aceptado:**
  - Al correr en Windows se vio que OpenStreetMap responde 403 «Access blocked» a los identificadores `com.example.*`: el mapa habría quedado en blanco también en Android. Las pruebas no lo detectaban porque usan teselas falsas.
  - La variante FFI solo se activa en Windows, Linux y macOS; en Android sigue el plugin nativo.
- **Rechazado / corregido:**
  - La prueba «el userAgentPackageName coincide con el id de la app» exigía que fuera igual a `applicationId` (`com.example.competihub`), justo lo que OpenStreetMap bloquea. Ahora verifica el requisito real: un identificador propio, con formato de paquete, que no empiece con `com.example`.
  - El README decía que `sqflite_common_ffi` era solo de desarrollo; se corrigió y se agregó cómo correr en Windows.
  - Queda pendiente decidir un `applicationId` propio para Android (hoy `com.example.competihub`): conviene que coincida con `idDeLaApp`, pero cambiarlo crea otra app en el teléfono y depende de cómo se vaya a publicar.
- **Verificación:** `flutter analyze` sin observaciones, `flutter test` 233/233.
- **Commit / PR:** commit «chore: ejecutar en Windows e identificador propio ante OpenStreetMap» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 12: documentación del alcance nuevo

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Actualiza el README con el alcance nuevo (ya incluye mapa y guardados), la lista de funciones, las dependencias nuevas y cómo probar. Actualiza docs/flujo_navegacion_mvp.md con la barra inferior y las pantallas nuevas."
- **Resultado:** README con flujo principal, funciones por sección, datos de ejemplo, persistencia, fuera de alcance, tabla de dependencias y cómo ejecutar y probar. `docs/flujo_navegacion_mvp.md` con un esquema de la navegación y las vistas A–F (Inicio, Mapa, Mis eventos, Detalle, Formulario y Elegir ubicación).
- **Aceptado:**
  - «Mapas nativos» deja de estar fuera de alcance tal cual: se aclara que lo que sigue fuera es un SDK de mapas nativo, porque el mapa usa OpenStreetMap con `flutter_map` y «Cómo llegar» abre la app de mapas del teléfono.
  - Se agregó la sincronización entre dispositivos como fuera de alcance: los guardados viven solo en el teléfono.
- **Rechazado / corregido:**
  - No se tocaron las secciones «Equipo de desarrollo» ni «Metodología de trabajo». La metodología del README todavía describe Pull Requests, aunque el equipo integra ramas directamente; es una decisión del equipo y queda señalada para revisarla.
- **Verificación:** Revisión de los enlaces y de que las versiones de la tabla coincidan con `pubspec.lock`. Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 233/233.
- **Commit / PR:** commit «docs: README y flujo de navegación con el alcance nuevo» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 11: compartir

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Botón en el Detalle con share_plus. Comparte un texto con título, fecha, lugar, costo, cómo participar y enlace si lo hay. En las de ejemplo, el texto dice que es ficticia."
- **Resultado:** dependencia `share_plus` 13.3.1, `lib/servicios/compartir.dart` (`textoParaCompartir` y `Compartidor` con su provider) y `lib/widgets/boton_compartir.dart` en la fila de acciones del Detalle.
- **Aceptado:**
  - El texto se arma en una función pura y se prueba completo, línea por línea.
  - En los datos de ejemplo, la primera línea es «Competencia FICTICIA de ejemplo (no es un evento real).»: es lo que se ve en la vista previa de un chat, y así el texto no circula como si fuera real.
  - El título va como asunto (lo usan las apps de correo). Si compartir falla, se avisa.
  - Compartir está en todas las modalidades, a diferencia de «Cómo llegar».
- **Rechazado / corregido:**
  - `test/navigation_test.dart` («El detalle utiliza tarjetas visuales…») esperaba ver la tarjeta de Modalidad sin desplazarse en 430×960. Con tres botones la fila de acciones ocupa dos líneas y la empuja; ahora se desplaza hasta ella, igual que ya hacía con Ubicación. Verifica lo mismo.
- **Verificación:** `test/compartir_test.dart` (7 pruebas: texto completo, sin enlace, primera línea en los ejemplos y no en las propias, botón con texto y asunto, botón en virtuales, error, y 360 dp con texto 2.0 con los tres botones). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 233/233. Pendiente en el emulador: que se abra la hoja de compartir de Android.
- **Commit / PR:** commit «feat: compartir competencias con share_plus» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 10: mapa interactivo con OpenStreetMap (base v7)

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "flutter_map con teselas de OpenStreetMap, userAgentPackageName con el id de la app y atribución visible «© OpenStreetMap contributors». Permiso INTERNET en el AndroidManifest principal. Campos opcionales latitud y longitud. En el formulario, elegir el punto tocando un mapa. En el Detalle, un mapa pequeño con el marcador. En la pestaña Mapa, todas las presenciales con coordenadas; al tocar un marcador, una tarjeta breve que lleve al Detalle. Coordenadas ficticias alrededor del centro de Quetzaltenango (14.8347, -91.5181) y un aviso de que son ficticias. Sin conexión, un estado claro en vez de un mapa en blanco."
- **Resultado:** dependencias `flutter_map` 8.3.2 y `latlong2` 0.10.1; columnas `latitud` y `longitud` (migración v7); `lib/widgets/mapa_base.dart` (teselas, atribución, aviso de ficticias y estado sin conexión); pestaña Mapa completa; `SelectorUbicacionScreen`; mapa pequeño en el Detalle; sección «Punto en el mapa» en el formulario; permiso `INTERNET` en el manifiesto principal. «Cómo llegar» ahora usa las coordenadas si existen.
- **Aceptado:**
  - Un solo widget de mapa para los tres usos, así la identificación ante OpenStreetMap (`userAgentPackageName: com.example.competihub`) y la atribución no se pueden olvidar en ninguno. La atribución abre la página de derechos de OpenStreetMap.
  - Sin conexión: tras 3 teselas fallidas se reemplaza el mapa por un mensaje y «Reintentar», que vuelve a pedir las teselas. Con un solo fallo, un error aislado del servidor ocultaría todo el mapa.
  - El origen de las teselas va en un provider: las pruebas usan imágenes en memoria o teselas que fallan, sin internet.
  - El mapa del Detalle no se arrastra, para no pelear con el desplazamiento de la pantalla.
  - Coordenadas ficticias para los cuatro ejemplos con lugar físico, a menos de 0,02° del centro de Quetzaltenango; el mapa, el Detalle y «Cómo llegar» avisan que son ficticias.
- **Rechazado / corregido:**
  - La pestaña Mapa también muestra las competencias **híbridas** con coordenadas, no solo las presenciales: tienen un lugar físico y «Cómo llegar» ya las incluía. Así el ejemplo híbrido con punto no queda fuera del mapa. Si el equipo prefiere solo presenciales, es cambiar `competenciasEnMapa`.
  - No se usó `SimpleAttributionWidget` de flutter_map porque antepone «flutter_map |»; se escribió una atribución propia con el texto pedido.
  - Se corrigió la entrada del módulo 9, a la que le faltaba la versión de `url_launcher` (6.3.3).
- **Verificación:** `test/mapa_test.dart` (17 pruebas: coordenadas de los ejemplos, filtro de ubicables, migración v6→v7 sin tocar a la persona ni sus guardados, guardar y quitar el punto, `userAgentPackageName` igual al `applicationId`, permiso `INTERNET`, marcadores con aviso y atribución, tarjeta breve hasta el Detalle, sin conexión con reintento, mapa vacío, sin aviso con datos propios, selección conservada al cambiar de pestaña, mapa pequeño en el Detalle, sin mapa en virtuales, elegir el punto tocando el mapa, quitarlo, y 360 dp con texto 2.0). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 226/226. Pendiente en el emulador: que las teselas reales carguen y que el estado sin conexión aparezca en modo avión.
- **Commit / PR:** commit «feat: mapa interactivo con OpenStreetMap (base v7)» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 9: Cómo llegar

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Botón en el Detalle de las competencias presenciales e híbridas. Abre la app de mapas con la ubicación usando url_launcher (geo: o el URL de Google Maps como respaldo). Configura las <queries> de Android. Si no se puede abrir, muestra un mensaje y ofrece copiar la dirección."
- **Resultado:** dependencia `url_launcher` 6.3.3, `lib/servicios/abridor_de_mapas.dart` (enlaces y apertura, con su provider), `lib/widgets/boton_como_llegar.dart` en la fila de acciones del Detalle y `<queries>` para `geo:` y `https:` en el `AndroidManifest.xml`.
- **Aceptado:**
  - Primero `geo:` (lo atiende cualquier app de mapas) y, si no hay ninguna, el enlace web de Google Maps. La función que arma los enlaces ya acepta coordenadas para el módulo 10.
  - La apertura va detrás de un provider (`abridorDeMapasProvider`): las pruebas la reemplazan y verifican qué se intentó abrir sin abrir nada.
  - Si no se pudo abrir, un mensaje con la acción «Copiar dirección».
- **Rechazado / corregido:**
  - En las competencias de ejemplo, antes de abrir el mapa se avisa que la ubicación es ficticia y se pide confirmar. Abrir una búsqueda de «Circuito imaginario del Parque Nube» sin aviso podría parecer un error de la app o hacer creer que el lugar existe.
  - No se usó `canLaunchUrl` antes de abrir: con `launchUrl` basta saber si se abrió, y se evita una segunda consulta al sistema.
- **Verificación:** `test/como_llegar_test.dart` (11 pruebas: enlaces con y sin coordenadas, respaldo web, fallo total, modalidades, `<queries>` en el manifiesto, apertura desde el Detalle, botón en híbridas y no en virtuales, mensaje con copia de la dirección, aviso en ejemplos y 360 dp con texto 2.0, donde los botones pasan a otra línea). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 209/209. Pendiente de revisar en el emulador: que se abra la app de mapas de verdad.
- **Commit / PR:** commit «feat: Cómo llegar con url_launcher» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 8: Mis eventos (base v6)

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Guardar o quitar una competencia con un botón en la tarjeta y en el Detalle, con descripción para lector de pantalla. Tabla local de guardados. Pestaña «Mis eventos» con las guardadas, próximas primero, y un estado vacío que explique cómo guardar."
- **Resultado:** tabla `guardados` (migración v6) con borrado en cascada, métodos en la fuente de datos y el repositorio, `guardadosProvider` y `alternarGuardado`, `lib/widgets/boton_guardar.dart` y la pestaña `MisEventosScreen` completa.
- **Aceptado:**
  - El botón dice qué hará y con qué competencia («Guardar «Copa…» en Mis eventos» / «Quitar … de Mis eventos») y se anuncia como seleccionado. En la tarjeta va fuera del resumen agrupado para que el lector lo ofrezca como un control aparte.
  - Mensaje al guardar, al quitar y si falla; mientras se guarda, el botón espera para no mandar dos cambios.
  - Estado vacío con instrucciones y un botón «Explorar competencias» que lleva a la pestaña Inicio.
  - Si se borra una competencia guardada, la base borra el guardado y la pestaña se actualiza.
- **Rechazado / corregido:**
  - Primero se puso Guardar en la barra superior del Detalle; la prueba del módulo 0 detectó que con tres botones el título «Detalle» se volvía a cortar a 360 dp con texto 2.0. Se movió a una fila de acciones bajo el resumen, como botón con texto; ahí también irán «Cómo llegar» y «Compartir».
  - Para no dejar a medias la interfaz de datos, los métodos de guardados se agregaron a `CompetenciasDataSource`; el doble de prueba en memoria de `test/competencias_repository_test.dart` los implementa (solo se agregaron métodos, sin tocar sus verificaciones). El repositorio falso guarda en memoria y puede simular un fallo.
- **Verificación:** `test/mis_eventos_test.dart` (10 pruebas: migración v5→v6 sin tocar datos, guardar, duplicado, quitar y cascada en SQLite, estado vacío con salida al Inicio, orden próximas primero, error con reintento, guardar desde la tarjeta, guardar y quitar desde el Detalle con la pestaña actualizada, fallo al guardar, anuncios para lector de pantalla, y 360 dp con texto 2.0). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 198/198.
- **Commit / PR:** commit «feat: Mis eventos con competencias guardadas (base v6)» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 7: barra inferior

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Barra inferior con tres secciones: Inicio, Mapa y Mis eventos. Conserva el estado de cada pestaña al cambiar."
- **Resultado:** `lib/screens/pantalla_principal.dart` (`NavigationBar` con un `IndexedStack`), `lib/widgets/estado_vacio.dart` y pantallas iniciales de Mapa y Mis eventos, que se completan en los módulos 10 y 8.
- **Aceptado:**
  - `IndexedStack`: las pestañas no se destruyen al cambiar, así que conservan búsqueda, filtro, posición de la lista y, después, el mapa.
  - El Detalle y el formulario se abren con el navegador principal, encima de la barra. Así el botón Atrás del sistema funciona igual que antes y no hace falta manejar una pila por pestaña.
  - Los rótulos de la barra se limitan a 1,3× con texto grande para que quepan los tres a 360 dp; el resto de la app sigue la escala del sistema.
- **Rechazado / corregido:**
  - No se usó un navegador anidado por pestaña (estilo de otras apps que dejan la barra visible en el Detalle): obligaría a interceptar el botón Atrás y el Detalle a 360 dp perdería 80 dp de alto.
  - Las pantallas de Mapa y Mis eventos de este módulo solo dicen qué mostrarán, sin prometer fechas.
  - `test/navigation_test.dart` se ajustó: después de desplazarse hasta una tarjeta ahora redibuja antes de tocarla. Es la misma causa que se encontró en `0cde13c` (`ensureVisible` no redibuja); con la barra la lista es más baja y el toque caía sobre la barra. Verifica lo mismo.
- **Verificación:** `test/barra_inferior_test.dart` (5 pruebas: tres secciones con Inicio al empezar, cambio de pestaña, Inicio conserva búsqueda, filtro y posición, Detalle sobre la barra y regreso a la misma pestaña, y 360 dp con texto 2.0 en las tres). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 188/188.
- **Commit / PR:** commit «feat: barra inferior con Inicio, Mapa y Mis eventos» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 6: etapas y cronograma (base v5)

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Tabla etapas: id, competenciaId, nombre, fechaHora, descripcion y orden. Al borrar una competencia se borran sus etapas. En el Detalle, una línea de tiempo vertical con la etapa actual resaltada. En el formulario, agregar, editar, reordenar y quitar etapas."
- **Resultado:** `lib/data/etapa.dart` (modelo y `estadosDeEtapas`), tabla `etapas` con `ON DELETE CASCADE` (migración v5), `lib/widgets/linea_de_tiempo.dart` y `lib/widgets/editor_etapas.dart`.
- **Aceptado:**
  - `PRAGMA foreign_keys = ON` en `onConfigure`: SQLite no aplica las llaves foráneas si no se le pide en cada conexión, y sin eso la cascada no borraba nada.
  - Competencia y etapas se guardan en una sola transacción; al editar se reemplaza el cronograma completo en el orden del formulario.
  - Etapa actual = la última que ya empezó, si la competencia no ha finalizado; antes del evento no se resalta ninguna y, al finalizar, todas quedan completadas. El estado también va en texto («Etapa actual», «Completada», «Próxima») para el lector de pantalla.
  - Reordenar con botones Subir y Bajar, con descripción («Subir «Final»»), en lugar de arrastrar: arrastrar no funciona bien con lector de pantalla ni con texto grande.
  - Cronogramas de ejemplo (copa y olimpiada) definidos como distancia desde su inicio, para que sigan siendo coherentes si las fechas se recalculan.
- **Rechazado / corregido:**
  - La lista del Inicio no carga las etapas (no las muestra); solo la consulta por id del Detalle. Se documentó en el modelo.
  - El orden es el que elige quien crea la competencia, no el de la fecha: así se respeta lo que la persona arma en el editor.
- **Verificación:** `test/etapas_test.dart` (16 pruebas: estados antes, durante y después; etapas de ejemplo; migración v4→v5 con una fila de usuario intacta; guardar, reordenar, reemplazar y borrar en cascada en SQLite; cascada en un ejemplo sin afectar a otro; línea de tiempo con la etapa actual; anuncios para lector de pantalla; sin resaltado antes del evento; sección oculta sin etapas; editor: agregar con validación, reordenar, editar y quitar, aviso de cambios sin guardar; y 360 dp con texto 2.0 en Detalle, editor y diálogo). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 183/183.
- **Commit / PR:** commit «feat: etapas y cronograma (base v5)» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 5: ficha de torneo (base v4)

- **Herramienta:** Claude Code (Claude Opus 5.5).
- **Especificación:** "Formato: individual o por equipos. Tamaño de equipo (mínimo y máximo, solo si es por equipos). Premios (texto opcional). Organizador (texto opcional). Mostrarlo en una sección «Formato y premios» del Detalle y agregarlo al formulario."
- **Resultado:** `FormatoCompetencia` y `describirTamanoEquipo` en `lib/data/competencia.dart`, cinco columnas nuevas (migración v4), sección «Formato y premios» en el Detalle y sección del mismo nombre en el formulario.
- **Aceptado:**
  - Todo opcional, incluido el formato («Sin especificar»): las competencias que ya existían quedan sin ficha en lugar de suponer un formato.
  - El tamaño de equipo solo se pide y se guarda con «Por equipos»; si se cambia a individual, no se guarda aunque los campos tuvieran valor.
  - En el Detalle solo aparecen las filas con dato, y la sección completa se oculta si no hay ninguno.
  - Mínimo y máximo van uno debajo del otro: lado a lado no caben a 360 dp con texto grande.
- **Rechazado / corregido:**
  - La ficha de los ejemplos no se inventó: formato y tamaño salen de sus propias reglas («Equipos de tres personas», «Parejas», «Participación individual»). La carrera queda sin ficha porque sus reglas no lo dicen. Premios y organizador de ejemplo dicen «ficticio».
  - Una prueba del módulo 4 abría la base en v3 y usaba la capa de datos actual, que ya escribe las columnas de la v4. Se corrigió para abrir siempre en `versionEsquema`: las bases antiguas solo se usan para probar migraciones.
- **Verificación:** `test/ficha_torneo_test.dart` (14 pruebas: descripción del tamaño, lectura del formato, ficha de los ejemplos, migración v3→v4 con una fila de usuario que solo gana columnas vacías, guardar y leer en SQLite, sección del Detalle completa, individual sin tamaño, sección oculta sin datos, formulario: aparición del tamaño, cambio a individual, validaciones y «Sin especificar», y 360 dp con texto 2.0 en Detalle y formulario). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 167/167.
- **Commit / PR:** commit «feat: ficha de torneo (base v4)» en `feat/fases-2-3` (sin PR).

---
## 2026-11-12 · @AlexDLG1 — Módulo 4: fecha límite de inscripción (base v3)

- **Herramienta:** Claude Code (Claude Fable 5.2 y Claude Opus 5.5).
- **Especificación:** "Campo opcional fechaLimiteInscripcion. Estado visible en la tarjeta y en el Detalle: «Inscripciones abiertas», «Cierra en N días», «Cierra hoy» o «Inscripciones cerradas». Validación: el límite no puede ser posterior al inicio. Campo nuevo en el formulario. Sube la versión de la base y prueba la migración partiendo de la versión anterior con una competencia creada por el usuario."
- **Resultado:** columna `fecha_limite_inscripcion` (migración v3), `estadoInscripcion` y `etiquetaInscripcion` en `lib/utils/fechas.dart`, `EtiquetaDeInscripcion` en las tarjetas y el Detalle, ficha «Inscripción» con la fecha exacta y campo nuevo en el formulario.
- **Aceptado:**
  - Sin fecha límite no se muestra ningún estado: la app no afirma que las inscripciones estén abiertas si no lo sabe.
  - «Cierra en N días» solo en la última semana (`diasDeAvisoDeCierre = 7`); antes, «Inscripciones abiertas». Una competencia finalizada siempre aparece con la inscripción cerrada, aunque el dato diga otra cosa.
  - Cada estado tiene su ícono además del color, para no depender solo del color.
  - Los ejemplos reciben fechas límite que muestran los cuatro estados; uno queda sin límite.
  - `Competencia.desdeBorrador` y `aBorrador()` evitan repetir la lista de 14 campos en la base de datos cada vez que se agrega uno.
- **Rechazado / corregido:**
  - El estado de inscripción no reemplaza a la etiqueta de tiempo («Faltan N días»): responden preguntas distintas (cuándo es y si todavía me puedo anotar).
  - Una prueba propia buscaba la palabra «inscripción» para comprobar que no había estado, pero el título de la competencia de prueba la contenía. Se cambió para buscar los cuatro textos de estado.
- **Verificación:** `test/inscripcion_test.dart` (16 pruebas: los cuatro estados y sus bordes, ejemplos, migración v2→v3 con una fila de usuario que solo gana la columna nueva vacía, guardar y quitar el límite en SQLite, tarjeta, Detalle, resumen para lector de pantalla, validación y selectores del formulario, y 360 dp con texto 2.0). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 153/153.
- **Commit / PR:** commit «feat: fecha límite de inscripción con estado (base v3)» en `feat/fases-2-3` (sin PR).

---
## 2026-11-11 · @AlexDLG1 — Módulo 3: Inicio nuevo (búsqueda, filtros con ícono, Destacados y Próximos)

- **Herramienta:** Claude Code (Claude Fable 5.2).
- **Especificación:** "Campo de búsqueda por título, ubicación y descripción, sin distinguir mayúsculas ni tildes. Filtros de categoría con ícono. Sección «Destacados» con las 3 próximas más cercanas en tarjetas horizontales. Sección «Próximos» con el resto y las finalizadas al final. Estado vacío para una búsqueda sin resultados. Si imagenUrl tiene valor, mostrar la imagen en Destacados y en el Detalle, con un marcador de posición si falla; si no, un fondo con el ícono de la categoría."
- **Resultado:** `lib/screens/inicio_screen.dart` (el Inicio sale de `main.dart`), `lib/utils/busqueda.dart`, `lib/widgets/tarjeta_competencia.dart` (tarjeta de lista y tarjeta destacada), `lib/widgets/imagen_competencia.dart`, `lib/widgets/fila_info.dart` y dos archivos de pruebas.
- **Aceptado:**
  - Búsqueda como función pura (`coincideConBusqueda`): cada palabra debe aparecer en título, ubicación o descripción, ya normalizados.
  - Destacados solo al explorar. Con una búsqueda o un filtro activo, la persona ya pidió algo concreto y ve la lista completa; así los resultados no se reparten entre dos secciones.
  - La tarjeta destacada muestra los mismos datos clave que la de la lista (cuánto falta, fecha, lugar y costo), con el mismo resumen para lector de pantalla.
  - Tres estados vacíos con salidas distintas: borrar la búsqueda, ver todas las categorías o volver a cargar.
  - La imagen es decorativa (`excludeFromSemantics`); si no carga, queda el fondo de la categoría con un ícono pequeño de imagen rota.
- **Rechazado / corregido:**
  - Una primera versión ordenaba la lista dentro de la pantalla. Se quitó: el orden ya lo da la base de datos y ordenar dos veces rompía tres pruebas que entregan los datos en otro orden. La pantalla solo ordena para elegir las destacadas.
  - En el Detalle sin imagen no se agregó un bloque nuevo: la cabecera de color ya era el fondo de la categoría, y ahora lleva su ícono dibujado detrás del texto sin cambiar de tamaño. Con imagen sí aparece una franja arriba.
  - La búsqueda no mira reglas, costo ni instrucciones: no se pidió y daría resultados difíciles de explicar (hay una prueba que lo fija).
  - Pruebas existentes ajustadas, sin quitar verificaciones: (1) `widget_test.dart` y `navigation_test.dart` indican qué área desplazar (`listaDeInicio`), porque el campo de búsqueda y la fila de Destacados también son desplazables y `scrollUntilVisible` exige una sola; (2) `feed_pulido_test.dart` se desplaza hasta el rótulo «Finalizadas», que ahora queda debajo de Destacados; (3) `conRepositorio` fija la hora en el 1 de diciembre de 2026: antes esas pruebas usaban la hora real y su resultado habría cambiado según el día (con el Inicio nuevo, una competencia próxima pasa a Destacados).
- **Verificación:** `test/busqueda_test.dart` (6 pruebas) y `test/inicio_nuevo_test.dart` (15 pruebas: búsqueda por título, lugar y descripción, combinada con categoría, sin resultados y borrado; ícono de cada filtro; composición de Destacados y Próximos; finalizadas al final; Destacados oculto al filtrar; navegación desde una destacada; imagen con y sin URL en Inicio y Detalle; y 360 dp con texto 2.0). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 137/137. No se probó una descarga de imagen exitosa: en las pruebas no hay red.
- **Commit / PR:** commit «feat: Inicio con búsqueda, Destacados y Próximos» en `feat/fases-2-3` (sin PR).

---
## 2026-11-11 · @AlexDLG1 — Módulo 2: tema azul y Detalle en dos columnas

- **Herramienta:** Claude Code (Claude Fable 5.2).
- **Especificación:** "ColorScheme a partir de un azul (#1565C0 o similar) que mantenga contraste AA; test/categoria_estilo_test.dart debe seguir pasando. En el Detalle, dos columnas en pantallas de 600 dp o más."
- **Resultado:** `lib/tema.dart` (esquema de color, tema y el ancho de corte), Detalle armado en tres bloques que se acomodan en una o dos columnas, y `test/tema_test.dart`.
- **Aceptado:**
  - `ColorScheme.fromSeed` con el azul #1565C0 fijado como color principal: `fromSeed` solo lo suaviza y se perdía el azul de marca.
  - En dos columnas: a la izquierda cabecera, resumen e información general; a la derecha lo necesario para participar. Ancho máximo de 1100 dp.
- **Rechazado / corregido:**
  - Esports usaba el color principal del tema; con el tema azul quedaba casi igual a Académica. Ahora tiene un violeta propio (#6A1B9A) y hay una prueba de que las cuatro categorías usan colores distintos.
  - `test/categoria_estilo_test.dart` construía su propio esquema morado («mismo esquema que usa la app»). Ahora importa el esquema real de `lib/tema.dart`: verifica lo mismo, pero ya no puede quedar desfasado del tema.
- **Verificación:** `test/tema_test.dart` (15 pruebas: 9 pares texto/fondo con contraste AA, tema aplicado en la app, dos columnas a 900 dp, una columna a 360 dp, Detalle a 360 dp con texto 2.0 y dos columnas en el límite de 600 dp con texto 2.0). Las pruebas existentes del Detalle a 600 y 800 dp pasan sin cambios con el diseño de dos columnas. Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 116/116.
- **Commit / PR:** commit «feat: tema azul y Detalle en dos columnas» en `feat/fases-2-3` (sin PR).

---
## 2026-11-11 · @AlexDLG1 — Módulo 1 (Issue 9): datos de ejemplo vigentes (base v2)

- **Herramienta:** Claude Code (Claude Fable 5.2).
- **Especificación:** "Migración que recalcule las fechas solo de las filas con id «mock-», relativas al día de la migración. Que una quede finalizada a propósito. En instalaciones nuevas, siembra con fechas relativas al día de creación. Nunca borres datos creados por el usuario. Prueba la migración con sqflite_common_ffi, solo como dependencia de desarrollo, partiendo de una base de la versión anterior con una competencia creada por el usuario."
- **Resultado:** `abrirBaseCompetihub` (versión 2, `onUpgrade` encadenado), `fechasDeEjemplo` y `competenciasDeEjemplo` en `lib/data/mock_competencias.dart`, y pruebas con una base SQLite real.
- **Aceptado:**
  - Un solo camino: una instalación nueva crea el esquema v1 y recorre las mismas migraciones que una existente. No hay un `onCreate` aparte que se pueda desincronizar.
  - Los ejemplos empiezan a 3, 7, 12, 18 y 25 días de hoy; `mock-esports-02` queda 20 días atrás, a propósito, para poder ver «Finalizada». Se conservan la hora del día y la duración de cada ejemplo.
  - La fábrica de la base y la hora son parámetros, así las pruebas usan `sqflite_common_ffi` y una fecha fija.
- **Rechazado / corregido:**
  - No se cambiaron las fechas fijas de `competenciasMock`: 30 pruebas existentes dependen de ellas. Quedan como base y la app usa las relativas.
  - La migración no vuelve a crear un ejemplo que la persona haya eliminado (hay una prueba para eso).
  - `sqflite_common_ffi` va en `dev_dependencies`; no entra en la app.
- **Verificación:** `test/migracion_v2_test.dart` (5 pruebas: fechas relativas, instalación nueva, v1→v2 con una fila de usuario que queda idéntica columna por columna y un ejemplo eliminado que no se repone, y orden del Feed tras migrar) y `test/ejemplos_vigentes_test.dart` (Inicio a 360 dp y texto 2.0: «5 por venir · 1 ya finalizó»). Formato sin cambios, `flutter analyze` sin observaciones, `flutter test` 100/100.
- **Commit / PR:** commit «feat: datos de ejemplo con fechas vigentes (base v2)» en `feat/fases-2-3` (sin PR).

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
