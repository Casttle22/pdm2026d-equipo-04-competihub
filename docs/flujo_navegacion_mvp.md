# Flujo de navegación

Este documento define la navegación central de CompetiHub. Se amplió con la fase 2 y la fase 3 (barra inferior, mapa y guardados); la versión original del MVP está en el historial de Git.

## 1. Flujo principal
El recorrido principal del usuario es el siguiente:
**Explorar competencias (buscar y filtrar) → seleccionar una competencia → consultar detalle → comprender de qué trata → saber cómo participar → guardarla, ver cómo llegar o compartirla.**

## 2. Estructura

```text
PantallaPrincipal (barra inferior)
├── Inicio ─────────┐
├── Mapa ───────────┼──► Detalle de la competencia ──► Formulario de edición
└── Mis eventos ────┘          │                          └──► Elegir ubicación (mapa)
                               ├──► Cómo llegar (app de mapas externa)
                               └──► Compartir (hoja del sistema)
Inicio ──► Formulario de creación ──► Elegir ubicación (mapa)
```

- La **barra inferior** tiene tres secciones: Inicio, Mapa y Mis eventos. Cambiar de pestaña no reinicia ninguna: cada una conserva su búsqueda, filtro, posición o selección.
- El **Detalle** y el **Formulario** se abren encima de toda la pantalla, sin la barra. El botón Atrás (de la app o del sistema) vuelve a la pestaña desde la que se abrieron.

## 3. Vistas y transiciones

### Vista A: Inicio (pestaña 1)
- **Propósito:** explorar y encontrar competencias.
- **Contenido:** campo de búsqueda; filtros de categoría con ícono; contador de disponibles; aviso de datos ficticios; «Destacados» (las tres próximas más cercanas, en fila horizontal); «Próximos»; «Finalizadas».
- **Interacciones y transiciones:**
  - **Buscar o filtrar:** actualiza la lista. Con una búsqueda o un filtro activo se oculta «Destacados». Sin resultados aparece un estado vacío con «Borrar búsqueda» o «Ver todas».
  - **Tocar una tarjeta (o una destacada):** abre la *Vista D*.
  - **Ícono de marcador en la tarjeta:** guarda o quita la competencia de Mis eventos, sin salir de la lista.
  - **Botón +:** abre el formulario de creación (*Vista E*).

### Vista B: Mapa (pestaña 2)
- **Propósito:** ver dónde son las competencias presenciales e híbridas que tienen un punto en el mapa.
- **Interacciones y transiciones:**
  - **Tocar un marcador:** muestra una tarjeta breve (título, estado, fecha, lugar).
  - **«Ver detalle» en la tarjeta:** abre la *Vista D*.
  - **Tocar el mapa o «Cerrar»:** oculta la tarjeta.
  - **Sin conexión:** en lugar de un mapa en blanco, un mensaje con «Reintentar».
  - Si se muestran ejemplos, un aviso indica que sus ubicaciones son ficticias.

### Vista C: Mis eventos (pestaña 3)
- **Propósito:** tener a mano las competencias guardadas.
- **Interacciones y transiciones:**
  - **Tocar una tarjeta:** abre la *Vista D*.
  - **Sin guardadas:** un estado vacío que explica cómo guardar, con «Explorar competencias», que lleva a la *Vista A*.

### Vista D: Detalle de la competencia
- **Propósito:** mostrar la información clave y cómo participar.
- **Contenido:** cabecera con categoría, tiempo restante e inscripción; resumen (cuándo, dónde, costo); acciones; información general con mapa pequeño y cronograma; información para participar; formato y premios. Desde 600 dp de ancho, en dos columnas.
- **Interacciones y transiciones:**
  - **Guardar / Guardada:** agrega o quita la competencia de Mis eventos.
  - **Cómo llegar** (presenciales e híbridas): abre la app de mapas del teléfono. En los ejemplos, primero avisa que la ubicación es ficticia. Si no se puede abrir, ofrece copiar la dirección.
  - **Compartir:** abre la hoja de compartir del sistema con un resumen en texto.
  - **Editar:** abre el formulario de edición (*Vista E*).
  - **Más opciones → Eliminar:** pide confirmación y vuelve a la pestaña anterior.
  - **Regreso:** vuelve a la pestaña desde la que se abrió.

### Vista E: Formulario de competencia (crear o editar)
- **Propósito:** registrar o corregir una competencia.
- **Interacciones y transiciones:**
  - **Elegir en el mapa:** abre la *Vista F*.
  - **Agregar o editar etapa:** abre un diálogo; las etapas se reordenan con Subir y Bajar.
  - **Guardar:** valida, lleva al primer campo con error si lo hay y, si todo está bien, vuelve a la vista anterior con un mensaje.
  - **Regreso con cambios sin guardar:** pregunta «¿Descartar cambios?».

### Vista F: Elegir ubicación
- **Propósito:** marcar el punto de la competencia.
- **Interacciones y transiciones:**
  - **Tocar el mapa:** marca o mueve el punto.
  - **«Usar este punto»:** vuelve al formulario con el punto elegido.
  - **Regreso:** vuelve al formulario sin cambiar el punto.

## 4. Límites del alcance
Este flujo de navegación **no incluye**:
- Pantallas de Splash o Onboarding.
- Flujos de login, registro o cuentas de usuario.
- Inscripción o pagos internos dentro de la aplicación.
- Flujos avanzados para organizadores (brackets, round-robin, moderación).
- Navegación paso a paso dentro de la app: «Cómo llegar» la delega a la app de mapas del teléfono.
