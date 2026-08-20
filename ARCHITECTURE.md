# Develop Workflow — Frontend Architecture

## 1. Objetivo

Este proyecto es el frontend de **Develop Workflow**, un módulo destinado a gestionar discusiones relacionadas con:

* errores;
* ideas;
* mejoras;
* consultas.

Las discusiones son utilizadas por técnicos, vendedores y desarrolladores.

El frontend debe funcionar desde:

* Web;
* Android;
* iOS.

Se utilizará **un único proyecto Flutter** para las tres plataformas.

---

# 2. Principios generales

Antes de implementar cualquier funcionalidad:

1. Leer este archivo `ARCHITECTURE.md`.
2. Respetar las decisiones arquitectónicas definidas aquí.
3. No introducir patrones o dependencias diferentes sin una razón concreta.
4. No modificar decisiones arquitectónicas existentes simplemente para resolver una funcionalidad puntual.
5. Mantener las responsabilidades claramente separadas.
6. No colocar lógica de negocio dentro de Widgets.
7. Evitar código duplicado.
8. Evitar clases gigantes con demasiadas responsabilidades.
9. Preferir soluciones simples y consistentes.

Si una implementación requiere modificar alguna decisión de este documento, primero analizar el impacto sobre la arquitectura existente.

---

# 3. Stack principal

## Frontend

* Flutter
* Dart

## Plataformas

* Android
* iOS
* Web

## Arquitectura

* DDD
* Feature-first
* `data / domain / presentation`

## State Management

Utilizar:

```text
flutter_bloc
```

### Regla obligatoria

Utilizar **Bloc**.

No utilizar `Cubit`.

No utilizar otros gestores de estado.

No utilizar:

* Riverpod
* Provider
* GetX
* Redux
* MobX
* otros gestores de estado.

---

# 4. HTTP

El cliente HTTP utilizado por la aplicación es:

```text
package:http/http.dart
```

No utilizar Dio.

No agregar otro cliente HTTP salvo que exista una necesidad arquitectónica real y se modifique previamente esta decisión.

Todas las comunicaciones REST con el backend deben utilizar la infraestructura HTTP centralizada.

---

# 5. Arquitectura por Features

La aplicación utiliza arquitectura DDD organizada por Features.

Estructura general:

```text
lib/
│
├── core/
│
└── features/
    ├── discussions/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── discussion_messages/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── applications/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    └── indicators/
        ├── data/
        ├── domain/
        └── presentation/
```

Cada Feature debe mantener separadas las capas:

```text
data
domain
presentation
```

No mezclar responsabilidades entre ellas.

---

# 6. Domain

La capa `domain` representa las reglas y conceptos del negocio.

Debe ser independiente de:

* Flutter;
* HTTP;
* JSON;
* widgets;
* infraestructura;
* APIs concretas.

Dentro de `domain` se ubican principalmente:

```text
entities/
repositories/
usecases/
```

según la necesidad de cada Feature.

---

# 7. Entities

Las Entities representan conceptos del dominio.

Ejemplos actuales:

```text
Application
Indicator
Discussion
DiscussionMessage
```

Una Entity de Domain no debe conocer:

* JSON;
* HTTP;
* `http.Response`;
* APIs REST;
* Flutter.

Por ejemplo, evitar:

```dart
class Application {
  factory Application.fromJson(...) { ... }
}
```

El parseo JSON pertenece a los Models de Data.

---

# 8. Data

La capa `data` es responsable de la comunicación con infraestructura externa.

Principalmente:

```text
models/
datasources/
repositories/
```

El flujo esperado es:

```text
HTTP
 ↓
RemoteDataSource
 ↓
Model
 ↓
Repository
 ↓
Entity
 ↓
UseCase
 ↓
Bloc
 ↓
UI
```

---

# 9. Models y JSON

## REGLA ARQUITECTÓNICA OBLIGATORIA

**Todo JSON recibido desde el backend debe ser parseado mediante un Model.**

Nunca realizar parseo manual de JSON directamente dentro de una función de DataSource, Repository, Bloc o Widget.

### Incorrecto

```dart
final json = jsonDecode(response.body);

final id = json['id'];
final name = json['name'];
```

### Correcto

```dart
final json = jsonDecode(response.body);

final model = ApplicationModel.fromJson(json);
```

El Model es responsable de conocer la estructura JSON de la API.

---

# 10. Model

Cada entidad que se comunica con el backend debe tener un Model correspondiente cuando sea necesario.

Ejemplos:

```text
ApplicationModel
IndicatorModel
DiscussionModel
DiscussionMessageModel
```

Los Models deben encargarse de:

```text
JSON → Model
Model → JSON
Model → Entity
Entity → Model
```

Ejemplo conceptual:

```dart
ApplicationModel.fromJson(...)
ApplicationModel.toJson(...)
ApplicationModel.toEntity()
ApplicationModel.fromEntity(...)
```

No es obligatorio implementar todos estos métodos si una operación concreta no los necesita, pero el principio de separación debe mantenerse.

---

# 11. Conversión Model ↔ Entity

La conversión entre infraestructura y dominio debe quedar centralizada en los Models.

Flujo de lectura:

```text
JSON
 ↓
Model.fromJson()
 ↓
Model
 ↓
Entity
```

Flujo de escritura:

```text
Entity
 ↓
Model.fromEntity()
 ↓
Model.toJson()
 ↓
JSON
```

No realizar conversiones manuales campo por campo en:

* Bloc;
* Widget;
* UseCase;
* Controller de presentación;
* funciones arbitrarias.

---

# 12. RemoteDataSource

Los `RemoteDataSource` son responsables de comunicarse con el backend.

Ejemplos:

```text
ApplicationRemoteDataSource
IndicatorRemoteDataSource
DiscussionRemoteDataSource
DiscussionMessageRemoteDataSource
```

Responsabilidades:

* realizar requests HTTP;
* utilizar la infraestructura HTTP centralizada;
* enviar parámetros;
* enviar JSON utilizando Models;
* recibir JSON;
* convertir JSON utilizando `Model.fromJson()`;
* lanzar excepciones de infraestructura cuando corresponda.

No deben contener lógica de negocio.

No deben transformar manualmente JSON campo por campo.

---

# 13. Repository

Los Repositories pertenecen a la capa Domain como contratos.

Ejemplo:

```text
ApplicationRepository
IndicatorRepository
DiscussionRepository
DiscussionMessageRepository
```

Las implementaciones concretas pertenecen a Data:

```text
ApplicationRepositoryImpl
IndicatorRepositoryImpl
DiscussionRepositoryImpl
DiscussionMessageRepositoryImpl
```

Flujo:

```text
Bloc
 ↓
UseCase
 ↓
Repository interface
 ↓
RepositoryImpl
 ↓
RemoteDataSource
 ↓
HTTP
```

El Domain no debe conocer la implementación concreta.

---

# 14. Use Cases

Cada Use Case debe representar una acción concreta del negocio.

Ejemplos:

```text
GetApplications
GetApplication
CreateApplication
UpdateApplication

GetIndicators
GetIndicator
CreateIndicator
UpdateIndicator
```

Posteriormente:

```text
CreateDiscussion
GetDiscussions
GetDiscussion
UpdateDiscussion

CreateDiscussionMessage
GetDiscussionMessages
UpdateDiscussionMessage
```

Cada Use Case debe tener una responsabilidad clara.

No colocar llamadas HTTP directamente dentro de los Blocs.

---

# 15. Presentation

La capa Presentation contiene:

* Pages;
* Widgets;
* Bloc;
* Events;
* States.

Los Widgets son exclusivamente responsables de la presentación.

No deben contener:

* llamadas HTTP;
* acceso directo a Repository;
* acceso directo a DataSource;
* lógica de negocio;
* parseo JSON;
* transformación de Models;
* reglas de dominio.

---

# 16. Bloc

La aplicación utiliza `flutter_bloc`.

### Regla obligatoria

Usar siempre:

```text
Bloc
```

No utilizar:

```text
Cubit
```

Incluso cuando una funcionalidad parezca suficientemente simple para Cubit, mantener Bloc para tener un único patrón de gestión de estado en toda la aplicación.

---

# 17. Flujo de Bloc

El flujo esperado es:

```text
Widget
 ↓
Bloc Event
 ↓
Bloc
 ↓
UseCase
 ↓
Repository
 ↓
RemoteDataSource
 ↓
HTTP
 ↓
Backend
```

El Bloc:

* recibe Events;
* ejecuta UseCases;
* transforma resultados en States;
* maneja estados de presentación.

El Bloc NO debe:

* realizar HTTP directamente;
* parsear JSON;
* acceder a Models de infraestructura innecesariamente;
* acceder directamente a DataSources.

---

# 18. Bloc Events

Los Events representan acciones realizadas por el usuario o por el sistema.

Ejemplo:

```text
LoadApplications
LoadApplication
CreateApplication
UpdateApplication
```

No colocar lógica dentro de los Events.

---

# 19. Bloc States

Los States representan el estado actual de la interfaz.

Como mínimo pueden contemplarse estados equivalentes a:

```text
initial
loading
success
error
```

La estructura concreta puede variar según la Feature.

Los States deben ser inmutables.

---

# 20. Error Handling

La aplicación debe separar los errores de infraestructura de los errores que necesita manejar Presentation.

Flujo conceptual:

```text
HTTP / Exception
 ↓
RemoteDataSource
 ↓
Repository
 ↓
Failure
 ↓
UseCase
 ↓
Bloc
 ↓
UI
```

No mostrar directamente en pantalla errores técnicos como:

```text
SocketException
FormatException
HttpException
```

La UI debe recibir información apropiada para presentación.

---

# 21. Dependency Injection

Utilizar la infraestructura de Dependency Injection definida en el proyecto.

Si se utiliza `get_it`, mantenerlo centralizado.

Registrar las dependencias respetando el flujo:

```text
DataSource
 ↓
Repository
 ↓
UseCase
 ↓
Bloc
```

No crear instancias manualmente dentro de Widgets.

No crear instancias de Repository dentro de Pages.

---

# 22. HTTP Configuration

La configuración HTTP debe estar centralizada.

No hardcodear URLs dentro de:

* Widgets;
* Blocs;
* UseCases;
* Repositories;
* DataSources.

La infraestructura debe centralizar:

* Base URL;
* headers;
* autenticación;
* configuración común de requests.

---

# 23. Core

La carpeta `core` contiene infraestructura compartida entre Features.

Estructura actual:

```text
core/
├── constants/
├── error/
├── network/
├── router/
├── theme/
├── utils/
└── widgets/
```

---

# 24. Core Widgets

`core/widgets` solamente contiene widgets reutilizables globalmente.

Un Widget específico de una Feature debe permanecer dentro de esa Feature.

Ejemplo:

```text
features/discussions/presentation/widgets/
```

No colocar allí widgets que solamente tienen sentido para Discussions dentro de `core`.

---

# 25. Theme

El Theme debe estar centralizado.

No colocar colores, tamaños o estilos globales directamente dentro de Widgets.

Utilizar el Theme para mantener una apariencia consistente.

El diseño visual definitivo de Develop Workflow todavía no está establecido.

---

# 26. Router

La navegación debe estar centralizada.

No realizar navegación compleja directamente desde múltiples Widgets sin utilizar el sistema de Router definido.

Las rutas futuras incluirán funcionalidades como:

```text
/login
/
/discussions
/discussions/:id
```

La estructura exacta se definirá durante la implementación de cada Feature.

---

# 27. Plataformas

El proyecto es multiplataforma.

Se utilizará:

```text
Flutter
 ├── Web
 ├── Android
 └── iOS
```

No crear proyectos Flutter separados para cada plataforma.

Es el mismo código fuente con adaptaciones de UI cuando sea necesario.

---

# 28. Responsive Design

La aplicación deberá adaptarse a:

### Web

Vista orientada a escritorio.

La pantalla principal utilizará posteriormente una vista Kanban.

Al seleccionar una Discussion, podrá abrirse el detalle lateralmente.

### Mobile

Vista optimizada para teléfono.

Al seleccionar una Discussion, se navegará al detalle completo.

La lógica de negocio debe permanecer compartida.

No duplicar Features por plataforma.

---

# 29. Develop Workflow — Concepto

Una `Discussion` representa una conversación de trabajo.

Tipos actuales:

```text
ERROR
IDEA
IMPROVEMENT
QUESTION
```

Estados actuales:

```text
NEW
REVIEW
IN_PROGRESS
RESOLVED
```

Una Discussion puede estar relacionada con:

* ninguna Application;
* una Application;
* varias Applications;
* ningún Indicator;
* un Indicator;
* varios Indicators;
* Tags.

---

# 30. Discussion

La Discussion representa la tarjeta que aparece en el Kanban.

Contiene información estructural como:

```text
id
type
title
status
createdBy
createdAt
updatedAt
applications
indicators
tags
```

El contenido de la conversación NO debe almacenarse directamente dentro de `Discussion`.

La conversación se representa mediante:

```text
DiscussionMessage
```

---

# 31. DiscussionMessage

`DiscussionMessage` pertenece exclusivamente a `Develop Workflow`.

No utilizar ni modificar el módulo `Message` existente que corresponde al chat con los bots.

Conceptualmente:

```text
Message
→ Chat con bots

DiscussionMessage
→ Conversación dentro de una Discussion
```

---

# 32. Conversación tipo Discord

La conversación de una Discussion debe comportarse conceptualmente como Discord.

Cada elemento agregado debe conservar su posición cronológica.

Ejemplo:

```text
Técnico
"El indicador presenta este problema."

Técnico
[AUDIO]

Técnico
[IMAGEN]

Developer
"¿Qué versión del indicador están utilizando?"

Developer
[IMAGEN]
```

No agrupar posteriormente:

```text
todos los textos
todos los audios
todas las imágenes
```

Todo debe formar una única secuencia cronológica.

---

# 33. DiscussionMessage Types

Actualmente el primer tipo implementado es:

```text
TEXT
```

La arquitectura debe permitir posteriormente:

```text
IMAGE
AUDIO
VIDEO
FILE
```

sin tener que rediseñar completamente `DiscussionMessage`.

Los archivos multimedia se implementarán posteriormente.

---

# 34. Multimedia

Los siguientes tipos se incorporarán posteriormente:

* imágenes;
* audios;
* videos;
* documentos/archivos.

Se utilizará Cloudinary para almacenamiento de estos recursos.

No implementar Cloudinary fuera de la Feature/fase correspondiente.

Los archivos deben conservar el orden dentro de la conversación.

---

# 35. Applications

`Application` representa una aplicación que puede estar relacionada con una Discussion.

Una Discussion puede tener:

```text
0..N Applications
```

Applications pertenece a su propia Feature:

```text
features/applications/
```

---

# 36. Indicators

`Indicator` representa un indicador que puede estar relacionado con una Discussion.

Una Discussion puede tener:

```text
0..N Indicators
```

Indicators pertenece a:

```text
features/indicators/
```

---

# 37. Contexto de Discussion

Una Discussion puede mencionar una Application o Indicator que todavía no exista en el catálogo.

No crear automáticamente entidades a partir del texto.

El usuario puede crear la Discussion igualmente.

Posteriormente un Developer podrá crear la Application o Indicator correspondiente y asociarlo.

---

# 38. Fases de implementación

El proyecto se desarrolla incrementalmente.

### Frontend Fase 1

Estructura inicial:

* Flutter;
* DDD;
* Features;
* Core;
* Bloc;
* HTTP;
* Router;
* Theme;
* Dependency Injection.

### Frontend Fase 2

Applications + Indicators:

* Entities;
* Models;
* Repositories;
* DataSources;
* UseCases;
* Blocs;
* integración REST.

### Frontend Fase 3

Discussions:

* Discussion Entity;
* Discussion Model;
* Repository;
* DataSource;
* UseCases;
* Bloc;
* listado;
* creación;
* consulta;
* actualización;
* filtros;
* contexto Applications/Indicators/Tags.

### Fases posteriores

Se implementarán progresivamente:

* DiscussionMessages;
* Attachments;
* Cloudinary;
* Kanban;
* Assignments;
* Read States;
* Notifications;
* Push Notifications;
* workflow;
* responsive UI.

No implementar funcionalidades de fases futuras anticipadamente.

---

# 39. Regla para Copilot

Antes de implementar cualquier nueva Feature o modificación:

1. Leer `ARCHITECTURE.md`.
2. Revisar la estructura existente del proyecto.
3. Revisar las implementaciones existentes relacionadas.
4. Reutilizar abstracciones existentes.
5. No crear una segunda implementación de algo que ya existe.
6. Mantener las capas `data`, `domain` y `presentation`.
7. Mantener `Bloc` como único gestor de estado.
8. Utilizar `http` para REST.
9. Parsear JSON siempre mediante Models.
10. Mantener los Widgets libres de lógica de negocio.
11. No modificar Features existentes innecesariamente.
12. No agregar dependencias sin justificación.

---

# 40. Regla de cambios

Cuando una nueva Feature requiera modificar una Feature existente:

* analizar primero la dependencia;
* modificar solamente lo necesario;
* evitar refactors globales;
* no cambiar APIs existentes sin necesidad;
* no duplicar entidades;
* no duplicar Models;
* no duplicar servicios;
* mantener compatibilidad con las funcionalidades existentes.

---

# 41. Regla fundamental

La arquitectura debe priorizar:

```text
claridad
+
separación de responsabilidades
+
mantenibilidad
+
consistencia
```

sobre crear una arquitectura excesivamente compleja.

No introducir abstracciones únicamente por cumplir una regla teórica de DDD.

Cada clase debe tener una responsabilidad clara y justificable.

---

# 42. Regla para nuevas decisiones

Si durante una implementación aparece una decisión que contradice este documento, no asumir automáticamente una nueva arquitectura.

Primero analizar:

* si realmente es necesario;
* si existe una solución compatible con la arquitectura actual;
* qué impacto tendría sobre Features existentes.

Si la decisión cambia una regla arquitectónica importante, actualizar `ARCHITECTURE.md` para que las siguientes fases utilicen la nueva decisión.
