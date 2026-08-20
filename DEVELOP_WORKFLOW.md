# Develop Workflow — Functional Specification

## 1. Objetivo

`Develop Workflow` es un módulo interno destinado a gestionar y dar seguimiento a problemas, consultas, ideas y mejoras relacionadas con:

* aplicaciones;
* indicadores;
* combinaciones entre indicadores y aplicaciones;
* funcionalidades solicitadas por clientes;
* problemas detectados por técnicos o vendedores;
* mejoras propuestas por usuarios;
* consultas técnicas que requieran intervención de un desarrollador.

La aplicación reemplaza el uso de Discord como mecanismo informal para registrar y seguir estas situaciones.

Discord puede seguir utilizándose para comunicación informal, pero `Develop Workflow` debe permitir:

* registrar una situación;
* conservar toda la información;
* mantener una conversación;
* solicitar información adicional;
* adjuntar archivos;
* asignar responsables;
* realizar seguimiento;
* cambiar el estado;
* documentar la resolución;
* mantener un historial;
* consultar posteriormente lo ocurrido.

---

# 2. Concepto principal

La unidad principal de trabajo es una:

```text
Discussion
```

Una Discussion funciona conceptualmente como una combinación de:

```text
Tarjeta Kanban
+
Conversación tipo Discord
+
Historial
```

No debe tratarse como un formulario tradicional de seguimiento.

La tarjeta contiene información estructural mínima y la información adicional se incorpora mediante una conversación.

---

# 3. Usuarios

Existen dos grupos principales relacionados con este módulo.

## 3.1 Usuarios solicitantes

Incluye principalmente:

* técnicos;
* vendedores;
* otros usuarios autorizados.

Pueden:

* crear Discussions;
* ver Discussions a las que tengan acceso;
* participar en las Discussions;
* agregar información;
* responder mensajes;
* agregar imágenes;
* agregar audios;
* agregar videos;
* agregar archivos;
* consultar el historial.

No pueden:

* asignarse Discussions;
* asignarlas a otros usuarios;
* mover Discussions entre estados;
* resolver Discussions.

---

# 3.2 Developers

Los Developers tienen permisos adicionales.

Pueden:

* hacer todo lo que puede hacer un usuario solicitante;
* asignarse una Discussion;
* asignar una Discussion a otros Developers;
* asignar una Discussion a varios Developers;
* quitar asignaciones;
* mover Discussions entre estados;
* resolver Discussions;
* agregar la explicación de la solución mediante la conversación;
* crear Applications;
* crear Indicators;
* asociar Applications e Indicators a una Discussion cuando corresponda.

---

# 4. Asignaciones

Una Discussion puede tener uno o varios Developers asignados.

Ejemplo:

```text
Discussion:
"El indicador ST456 y la aplicación Remoto tienen problemas
con el orden de los trabajos."

Asignados:

- Sebastián
- Facu
```

Esto permite que una misma Discussion pueda involucrar diferentes desarrolladores.

Por ejemplo:

```text
Sebastián → aplicación Remoto
Facu      → indicador ST456
```

No existe necesariamente un único responsable.

La asignación debe comportarse conceptualmente de manera similar a los Issues de GitHub.

Un Developer puede:

```text
Asignarse a sí mismo
```

o:

```text
Asignar a otro Developer
```

o:

```text
Asignarse a sí mismo y a otros Developers
```

Los usuarios que no sean Developers no pueden modificar las asignaciones.

---

# 5. Estados

La vista principal utiliza un flujo tipo Kanban.

Estados definidos actualmente:

```text
Entrada
Revisión
Trabajando
Resuelto
```

Los nombres pueden representarse internamente mediante identificadores técnicos, pero la interfaz debe utilizar nombres claros para los usuarios.

## Entrada

Discussion recién creada.

Todavía no fue tomada por un Developer.

## Revisión

Discussion que está siendo analizada.

Puede utilizarse para Discussions que necesitan evaluación antes de comenzar el trabajo.

## Trabajando

Una o más personas están trabajando sobre la Discussion.

## Resuelto

El problema fue resuelto, la consulta fue respondida o la mejora fue procesada.

---

# 6. Discussion no se cierra

Una Discussion en estado `Resuelto` **no debe considerarse cerrada definitivamente**.

Puede seguir abierta para continuar agregando información.

Por ejemplo:

```text
Resuelto
    ↓
nuevo comentario
    ↓
nueva información
```

La Discussion conserva toda su conversación e historial.

No eliminar ni ocultar la conversación al pasar a `Resuelto`.

---

# 7. Quién puede cambiar estados

Solamente los Developers pueden mover una Discussion entre estados.

Un técnico o vendedor puede:

* crearla;
* participar;
* agregar información;

pero no puede moverla a:

* Revisión;
* Trabajando;
* Resuelto.

---

# 8. Tipos de Discussion

Los tipos iniciales son:

```text
Error
Idea
Mejora
Consulta
```

Estos tipos sirven principalmente para clasificar y filtrar las Discussions.

Ejemplos:

```text
Error
"ST456 muestra los trabajos desordenados."

Idea
"Agregar una opción para exportar los trabajos."

Mejora
"Modificar la pantalla de selección de lotes."

Consulta
"¿Cómo se configura el indicador para trabajar con Remoto?"
```

La arquitectura debe permitir agregar nuevos tipos posteriormente.

---

# 9. Applications

Una Discussion puede estar relacionada con:

```text
ninguna Application
una Application
varias Applications
```

Ejemplo:

```text
Remoto
```

o:

```text
Remoto
+
Carga
```

Las Applications se seleccionan desde el catálogo existente.

---

# 10. Indicators

Una Discussion puede estar relacionada con:

```text
ningún Indicator
un Indicator
varios Indicators
```

Ejemplo:

```text
ST456
```

La Discussion puede relacionar simultáneamente Applications e Indicators.

Ejemplo:

```text
Application:
Remoto

Indicator:
ST456
```

---

# 11. Application o Indicator inexistente

Puede ocurrir que un usuario cree una Discussion mencionando una Application o Indicator que todavía no existe en el catálogo.

No impedir la creación de la Discussion.

Ejemplo:

El técnico escribe:

```text
"El problema ocurre en la aplicación NuevaApp
con el indicador ST789."
```

aunque esos elementos todavía no estén registrados.

El texto de la Discussion conserva esa información.

Posteriormente un Developer puede:

1. crear la Application o Indicator;
2. asociarlo a la Discussion.

De esta manera la Discussion podrá posteriormente filtrarse correctamente.

Los usuarios normales no necesitan tener permisos para crear Applications o Indicators.

---

# 12. Creación de una Discussion

La creación debe ser extremadamente sencilla, especialmente desde celulares.

La idea es que un técnico pueda registrar una situación rápidamente.

La estructura inicial debe ser:

```text
Tipo
↓
Application(s)
↓
Indicator(s)
↓
Título
↓
Contenido de la conversación
↓
Crear Discussion
```

---

# 13. Tipo

El usuario selecciona:

```text
Error
Idea
Mejora
Consulta
```

Este dato es obligatorio.

---

# 14. Application e Indicator

Después del tipo se pueden seleccionar:

* una o varias Applications;
* uno o varios Indicators.

No necesariamente deben ser obligatorios.

La selección debe permitir buscar rápidamente dentro de los catálogos.

---

# 15. Título

El título es obligatorio.

Máximo:

```text
150 caracteres
```

Debe ser suficientemente descriptivo para identificar la Discussion desde el Kanban.

Ejemplo:

```text
ST456 muestra los trabajos desordenados en Remoto
```

---

# 16. Contenido inicial

Después del título comienza la conversación.

No queremos un formulario tradicional con:

```text
Descripción
Resolución
Observaciones
Comentarios
```

La conversación debe funcionar como un chat.

El usuario debe poder escribir directamente y agregar archivos.

---

# 17. Conversación tipo Discord

La Discussion debe comportarse conceptualmente como una conversación de Discord.

Cada elemento agregado debe formar parte de una única secuencia cronológica.

Ejemplo:

```text
Técnico:
"El cliente informa que los trabajos aparecen desordenados."

Técnico:
[AUDIO]

Técnico:
[IMAGEN]

Developer:
"¿A qué empresa pertenece el indicador?"

Developer:
"Necesito también la versión de firmware."

Técnico:
"Pertenece a Empresa X."

Técnico:
[IMAGEN DEL INDICADOR]

Developer:
"Después de la prueba encontramos que..."
```

Todo debe mantenerse en ese orden.

---

# 18. Mensajes

La conversación utiliza:

```text
DiscussionMessage
```

No utilizar el módulo `Message` existente del sistema de chat con bots.

Son conceptos diferentes.

```text
Message
→ Chat con bots

DiscussionMessage
→ Conversación de Develop Workflow
```

---

# 19. Tipos de contenido

Una Discussion puede contener diferentes tipos de contenido.

Inicialmente:

```text
Texto
```

Posteriormente:

```text
Imagen
Audio
Video
Archivo
```

La arquitectura debe permitir mezclar todos estos tipos.

Ejemplo:

```text
Texto
Audio
Imagen
Texto
Video
Texto
```

El orden debe conservarse.

---

# 20. Adjuntos

Los archivos deben estar asociados al mensaje correspondiente.

No deben quedar simplemente asociados a la Discussion sin contexto.

Ejemplo:

```text
DiscussionMessage #15
    texto
    imagen
    audio
```

El sistema debe conservar la relación entre el contenido y el mensaje.

---

# 21. Cloudinary

Los archivos multimedia se almacenarán mediante Cloudinary.

El backend debe almacenar únicamente la información necesaria para recuperar el recurso.

No almacenar grandes archivos directamente en PostgreSQL.

El almacenamiento físico de:

* imágenes;
* audios;
* videos;
* documentos;

corresponderá al servicio de almacenamiento.

---

# 22. Edición de información

La Discussion debe poder enriquecerse a medida que avanza.

No se debe obligar al usuario a completar toda la información inicialmente.

Ejemplo:

### Inicialmente

```text
Error:
ST456 muestra trabajos desordenados.
```

### Developer

```text
¿A qué empresa pertenece el indicador?
Necesito también la versión del firmware.
```

### Técnico

Agrega:

```text
Empresa: X
```

y posteriormente:

```text
[imagen]
```

y:

```text
Versión de firmware: 2.14
```

Toda esta información queda dentro de la conversación.

---

# 23. Historial

La conversación funciona también como historial.

Debe poder saberse qué ocurrió cronológicamente.

Ejemplo:

```text
10:32 — Técnico creó la Discussion
10:40 — Developer Sebastián respondió
10:42 — Sebastián solicitó información
11:15 — Técnico agregó información
12:10 — Sebastián agregó una prueba
13:00 — Sebastián informó la solución
13:05 — Discussion pasó a Resuelto
```

No sobrescribir información histórica.

La conversación debe conservar el contexto.

---

# 24. Resolución

No debe existir un formulario especial obligatorio de resolución.

Cuando un Developer considera que la Discussion está resuelta:

1. agrega dentro de la conversación la explicación correspondiente;
2. puede agregar imágenes, archivos u otra información;
3. cambia el estado a `Resuelto`.

Ejemplo:

```text
Después de realizar la prueba se determinó que
el firmware del ST456 estaba desactualizado.

Se actualizó la placa a la versión correspondiente
y el problema quedó solucionado.
```

Ese mensaje forma parte de la conversación normal.

---

# 25. Notificaciones

Todos los usuarios relacionados con el módulo deben recibir notificaciones de cambios relevantes.

Inicialmente se consideran relevantes:

* nueva Discussion;
* nuevo mensaje;
* nueva información;
* cambio de estado;
* asignación;
* modificación de asignación.

La arquitectura no debe limitar las notificaciones únicamente al Developer asignado.

El objetivo es que todos los usuarios sepan que hubo actividad.

---

# 26. Estado no leído

Cada usuario debe poder saber qué Discussions todavía no vio.

El estado de lectura es:

```text
por usuario
```

No es una propiedad global de la Discussion.

Ejemplo:

```text
Discussion X

Sebastián → leída
Facu      → no leída
Técnico   → leída
```

Una misma Discussion puede estar leída para un usuario y no leída para otro.

---

# 27. Vista principal — Web

La vista principal en Web será tipo Kanban.

Conceptualmente:

```text
┌─────────────┬─────────────┬─────────────┬─────────────┐
│   ENTRADA   │   REVISIÓN  │  TRABAJANDO │  RESUELTO   │
├─────────────┼─────────────┼─────────────┼─────────────┤
│ Discussion  │ Discussion  │ Discussion  │ Discussion  │
│ Discussion  │ Discussion  │             │ Discussion  │
│ Discussion  │             │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

Los Developers podrán mover las Discussions entre columnas.

Los demás usuarios podrán consultar y participar, pero no moverlas.

---

# 28. Tarjeta Kanban

La tarjeta debe ser compacta.

No mostrar toda la conversación.

Debe permitir identificar rápidamente:

* tipo;
* título;
* Applications;
* Indicators;
* creador;
* estado no leído;
* Developers asignados;
* fecha/actividad reciente.

Ejemplo conceptual:

```text
┌──────────────────────────────┐
│ ERROR                        │
│                              │
│ ST456 muestra trabajos       │
│ desordenados                 │
│                              │
│ [Remoto] [ST456]             │
│                              │
│ 👤 Técnico                   │
│ 👨‍💻 Sebastián  👨‍💻 Facu      │
│                              │
│ ● No leído                   │
└──────────────────────────────┘
```

El diseño visual definitivo se decidirá durante la implementación.

---

# 29. Discussion en Web

Al seleccionar una tarjeta en Web, el detalle debe aparecer preferentemente de manera lateral.

Conceptualmente:

```text
┌───────────────────────┬───────────────────────────────┐
│                       │                               │
│      KANBAN           │       DISCUSSION              │
│                       │                               │
│  Entrada              │  Título                      │
│                       │  Tipo                         │
│  Revisión             │  Applications                │
│                       │  Indicators                  │
│                       │                               │
│  Trabajando           │  ──────────────────────────  │
│                       │                               │
│  Resuelto             │  conversación                │
│                       │                               │
│                       │  [ escribir mensaje... ]     │
└───────────────────────┴───────────────────────────────┘
```

El objetivo es poder consultar la conversación sin perder completamente el contexto del Kanban.

---

# 30. Discussion en Mobile

En celulares no intentar reproducir exactamente la interfaz de escritorio.

La experiencia debe estar diseñada para teléfono.

Flujo:

```text
Lista / Kanban adaptado
        ↓
seleccionar Discussion
        ↓
detalle a pantalla completa
```

El detalle debe mostrar la conversación completa y disponer de un input cómodo para:

* texto;
* imágenes;
* audio;
* archivos.

La creación debe ser especialmente rápida.

---

# 31. Experiencia Mobile

La aplicación será utilizada principalmente por:

* técnicos;
* vendedores.

Por lo tanto, la prioridad en Mobile es:

```text
rapidez
+
simplicidad
+
pocos campos obligatorios
+
entrada directa de información
```

Un técnico debería poder crear una Discussion desde el teléfono en pocos pasos.

No convertir la creación en un formulario largo.

---

# 32. Menús y filtros

La gran cantidad de Discussions hace necesario poder filtrarlas.

Se debe poder filtrar por lo menos por:

* tipo;
* Application;
* Indicator;
* estado;
* creador;
* Developer asignado;
* no leídas.

Los filtros deben poder evolucionar posteriormente.

---

# 33. Vistas personales

Debe existir una forma rápida de acceder a:

### Creadas por mí

Para todos los usuarios.

Muestra las Discussions creadas por el usuario actual.

### Asignadas a mí

Principalmente importante para Developers.

Muestra las Discussions en las que el Developer actual está asignado.

No debe existir una sección genérica de "Mis Discussions" que mezcle conceptos diferentes.

---

# 34. Información que NO pertenece a la Discussion

No utilizar este módulo para:

* solicitar firmware;
* pedir formalmente una nueva versión de firmware;
* gestionar pedidos de firmware;
* reemplazar llamadas telefónicas;
* reemplazar WhatsApp para solicitudes operativas.

Esas situaciones continúan manejándose por los canales correspondientes.

La Discussion sirve para registrar:

```text
problema
+
contexto
+
investigación
+
discusión
+
solución
+
historial
```

---

# 35. Ejemplo completo

Un vendedor crea:

```text
Tipo:
Error

Application:
Remoto

Indicator:
ST456

Título:
Trabajos aparecen desordenados
```

Luego escribe:

```text
El cliente informa que los trabajos aparecen
desordenados en la aplicación Remoto.
```

Adjunta:

```text
imagen
```

La Discussion aparece en:

```text
ENTRADA
```

Un Developer la abre.

Se asigna a sí mismo y a otro Developer.

La mueve a:

```text
TRABAJANDO
```

Responde:

```text
¿A qué empresa pertenece el indicador?
Necesito también la versión de firmware.
```

El técnico responde:

```text
Empresa X.

La versión es la que aparece en esta imagen.
```

Adjunta una imagen.

El Developer realiza las pruebas.

Luego responde:

```text
Se determinó que el firmware estaba desactualizado.

Se actualizó la placa y el problema quedó solucionado.
```

Finalmente mueve la Discussion a:

```text
RESUELTO
```

La Discussion conserva absolutamente toda la conversación.

---

# 36. Objetivo final

Develop Workflow debe convertirse en el lugar donde el equipo pueda pasar de:

```text
"Alguien comentó un problema en Discord"
```

a:

```text
"Existe una Discussion registrada,
con contexto, responsable, conversación,
evidencias, seguimiento y resolución."
```

El sistema debe permitir que una Discussion evolucione naturalmente:

```text
Creación
   ↓
Información inicial
   ↓
Revisión
   ↓
Asignación
   ↓
Investigación
   ↓
Solicitud de información
   ↓
Nuevos datos
   ↓
Pruebas
   ↓
Solución
   ↓
Resuelto
```

Sin perder nunca el historial.

---

# 37. Principio de diseño fundamental

La aplicación **no debe sentirse como un sistema de tickets tradicional**.

Debe sentirse como:

```text
Discord
+
Kanban
+
seguimiento estructurado
```

La conversación es el centro de la Discussion.

La información estructural permite organizar, filtrar y administrar las Discussions.

La conversación permite entender qué ocurrió y cómo se llegó a la solución.
