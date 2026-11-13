# CompetiHub

**Proyecto del curso:** Programación de Dispositivos Móviles  
**Carrera:** Ingeniería en Sistemas, Informática y Ciencias de la Computación  
**Sección:** D  
**Equipo:** 04

## Descripción del proyecto

CompetiHub es un proyecto de aplicación móvil desarrollado como parte del curso de Programación de Dispositivos Móviles.

**Propuesta de valor:**

> Ayudamos a personas que buscan competencias a encontrarlas y comprender en qué consisten y cómo participar mediante una plataforma que reúne su información en un solo lugar.

## Usuario principal

Persona que busca y/o quiere participar en competencias.

## Problema observable

Las personas interesadas en participar en competencias pueden necesitar consultar distintas fuentes y revisar publicaciones por separado para enterarse a tiempo de su existencia y reunir la información necesaria para comprender en qué consisten y cómo participar.

## Flujo principal

El usuario puede seguir el siguiente flujo:

**Explorar competencias (buscar y filtrar) → Seleccionar una competencia → Consultar su detalle → Comprender en qué consiste y cómo participar → Guardarla, ver cómo llegar o compartirla.**

La app tiene una barra inferior con tres secciones: **Inicio**, **Mapa** y **Mis eventos**. Cada una conserva su estado al cambiar de pestaña. El detalle de una competencia se abre encima de la barra. El recorrido completo está en [docs/flujo_navegacion_mvp.md](docs/flujo_navegacion_mvp.md).

## Alcance

### Funcionalidades incluidas

**Inicio**
- Búsqueda por título, ubicación y descripción, sin distinguir mayúsculas ni tildes.
- Filtros de categoría con ícono (Esports, Académica, Deportiva, Otras).
- «Destacados»: las tres competencias próximas más cercanas, en tarjetas horizontales con imagen o con el ícono de la categoría.
- «Próximos» con el resto y «Finalizadas» al final.
- En cada tarjeta: cuánto falta («Faltan N días», «Hoy», «Finalizada»), estado de la inscripción, fecha, lugar y costo.
- Estados de carga, error con Reintentar, lista vacía y búsqueda sin resultados.

**Detalle de una competencia**
- Resumen arriba (cuándo, dónde y costo) y acciones: **Guardar**, **Cómo llegar** (presenciales e híbridas) y **Compartir**.
- Estado de la inscripción («Inscripciones abiertas», «Cierra en N días», «Cierra hoy», «Inscripciones cerradas») con su fecha límite.
- Portada (imagen local o URL), «Fotos y videos» en las de ejemplo, información general, mapa pequeño con la ubicación, cronograma con la etapa actual resaltada, información para participar y la sección «Formato y premios» (individual o por equipos, tamaño de equipo, premios y organizador).
- En pantallas de 600 dp o más, dos columnas.

**Crear, editar y eliminar competencias**
- Formulario con validación, que lleva al primer campo con error y pide confirmar antes de descartar cambios.
- Campos opcionales: fecha de fin, límite de inscripción (no puede ser posterior al inicio), formato y tamaño de equipo, premios, organizador, etapas (agregar, editar, reordenar y quitar), punto en el mapa (se elige tocando un mapa), enlaces de inscripción e imagen, y contacto.

**Mapa**
- Mapa de OpenStreetMap con las competencias presenciales e híbridas que tienen un punto. Al tocar un marcador aparece una tarjeta breve que lleva al detalle.
- Atribución visible «© OpenStreetMap contributors» y estado claro sin conexión.

**Mis eventos**
- Competencias guardadas en el teléfono, con las próximas primero.

**Accesibilidad**
- Tema azul en modo claro y oscuro (sigue al sistema o se elige en el Inicio), con contraste AA comprobado en pruebas en los dos modos.
- Probado a 360 dp de ancho con el texto del sistema al doble de tamaño.
- Tarjetas y botones con descripciones para lector de pantalla.

### Pendiente

- **Modo de color recordado:** la elección Sistema/Claro/Oscuro vuelve a «Sistema» al cerrar la app; guardarla está pendiente de decidir.
- **Fotos y videos:** por ahora solo las competencias de ejemplo tienen galería (definida en `lib/data/mock_competencias.dart`). Falta guardarla en SQLite y poder agregarla al crear o editar una competencia.

### Datos de ejemplo

La app incluye seis competencias **ficticias**, rotuladas como tales en la lista, el detalle, el mapa y el texto que se comparte. Sus fechas se calculan respecto al día de instalación (o de la migración), y una queda finalizada a propósito. Sus ubicaciones en el mapa son puntos ficticios alrededor del centro de Quetzaltenango, no lugares de eventos reales.

### Persistencia

Los datos se guardan en el teléfono con SQLite (`sqflite`). La base va en la versión 7. Cada versión tiene su migración, y ninguna borra ni modifica las competencias creadas en la app. Las migraciones se prueban con `sqflite_common_ffi` partiendo de una base de la versión anterior.

### Funcionalidades fuera de alcance

- Registro, autenticación y administración de cuentas.
- Inscripción y pagos dentro de la aplicación.
- Sincronización entre dispositivos: las competencias y los guardados viven solo en el teléfono.
- Funcionalidades avanzadas para organizadores, como gestión de equipos inscritos.
- Sistemas de brackets y round-robin.
- Moderación automática.
- SDK de mapas nativos (por ejemplo, Google Maps SDK). El mapa usa OpenStreetMap con `flutter_map`, y «Cómo llegar» abre la app de mapas del teléfono.

La aplicación presenta instrucciones o medios externos para participar en una competencia, sin gestionar directamente su inscripción.

## Dependencias

| Paquete | Versión | Para qué |
|---|---|---|
| `flutter_riverpod` | 3.4.3 | Estado y providers |
| `sqflite` | 2.4.5 | Base de datos local |
| `url_launcher` | 6.3.3 | «Cómo llegar» y la página de atribución de OpenStreetMap |
| `flutter_map` | 8.3.2 | Mapa con teselas de OpenStreetMap |
| `latlong2` | 0.10.1 | Coordenadas para `flutter_map` |
| `share_plus` | 13.3.1 | Compartir una competencia |
| `sqflite_common_ffi` | 2.4.7 | SQLite en escritorio (Windows) y en las pruebas de migración |

El mapa necesita internet; el permiso `INTERNET` está en `android/app/src/main/AndroidManifest.xml`, junto con las `<queries>` para abrir la app de mapas.

## Cómo ejecutar y probar

Requisitos: Flutter 3.44.8 (canal estable) y un emulador o teléfono Android.

```bash
flutter pub get
flutter run                      # en el emulador o teléfono conectado
flutter run -d windows           # vista rápida en Windows (requiere el Modo de desarrollador)
```

En escritorio, `lib/main.dart` activa la variante FFI de SQLite; «Cómo llegar» y «Compartir» dependen de las apps del sistema y se revisan en Android.

Comprobaciones (las mismas que corre el CI):

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Las pruebas no necesitan internet ni dispositivo. El mapa usa teselas falsas, y la base de datos usa SQLite de la computadora mediante `sqflite_common_ffi`.

## Equipo de desarrollo

| Integrante | Usuario de GitHub | Rol actual |
|---|---|---|
| Wesley | @Casttle22 | Product / PM |
| Alejandro | @ALECARRIUMES | Arquitectura |
| Alex | @AlexDLG1 | UX / Research |
| Ricardo | @Pabloricalderon | Release |
| José | @QuijiTS | QA |

Los roles corresponden a la iteración actual, podrán rotar posteriormente y todos los integrantes participarán en el desarrollo del proyecto.

## Metodología de trabajo

El equipo utilizará Git y GitHub para organizar y desarrollar las tareas del proyecto.

El flujo de trabajo establecido es:

**Issue → Rama → Cambios y commit → Push → Pull Request → Revisión → Merge.**

Cada tarea se gestionará mediante un Issue y una rama de trabajo. Los cambios deberán presentarse mediante un Pull Request, revisado por un integrante distinto al autor antes de integrarse a la rama principal.

No se realizarán cambios directamente en `main` como flujo normal de trabajo.
