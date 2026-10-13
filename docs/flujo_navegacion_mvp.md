\# Flujo de Navegación Principal del MVP



Este documento define la navegación central que el equipo de Arquitectura (#4) y Desarrollo (#8) utilizarán para construir el MVP de CompetiHub.



\## 1. Flujo Aprobado

El recorrido principal del usuario es el siguiente:

\*\*Explorar competencias → filtrar opciones → seleccionar una competencia → consultar detalle → comprender de qué trata → saber cómo participar.\*\*



\## 2. Vistas y Transiciones

Para cumplir con este flujo, la aplicación requerirá el siguiente mapa de pantallas:



\### Vista A: Feed de Competencias (Pantalla Principal)

\- \*\*Propósito:\*\* Mostrar la lista de competencias disponibles (exploración).

\- \*\*Interacciones y Transiciones:\*\*

&#x20; - \*\*Filtro por categoría:\*\* Actualiza la vista actual para mostrar solo coincidencias (o estado vacío si no hay resultados). Permite volver a "Todas".

&#x20; - \*\*Selección:\*\* Al tocar una competencia de la lista, el usuario navega a la \*Vista B\*.



\### Vista B: Detalle de la Competencia

\- \*\*Propósito:\*\* Mostrar información clave (fecha, hora, ubicación, reglas, costo, modalidad) y las instrucciones sobre cómo participar.

\- \*\*Interacciones y Transiciones:\*\*

&#x20; - \*\*Regreso:\*\* Un botón para volver al Feed de Competencias (\*Vista A\*).



\## 3. Límites del Alcance (Fuera del MVP)

Para mantener la simplicidad y alcance del MVP, este flujo de navegación explícitamente \*\*NO INCLUYE\*\*:

\- Pantallas de Splash o Onboarding.

\- Flujos de login, registro o cuentas de usuario.

\- Inscripción o pagos internos dentro de la aplicación.

\- Flujos avanzados para organizadores (brackets, round-robin, moderación).

\- Pantallas de mapas nativos interactivos.

