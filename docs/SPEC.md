# Spec del MVP: Porotos

App iOS en español para anotar partidas de **Truco**, **Generala** y **Burako** en la mesa. Esta spec junta todas las decisiones del mapa [Mapa: app iOS anotador de juegos de mesa](https://github.com/facundocapua/scores-app/issues/1) y alcanza para empezar a construir. Si algo de acá contradice otro documento, manda esta spec.

**Documentos que acompañan esta spec:**

- [`GLOSSARY.md`](../GLOSSARY.md): el lenguaje del dominio. Los términos con mayúscula (Partida, Participante, Anotación…) son los del glosario, y el código los usa tal cual.
- [`DESIGN.md`](../DESIGN.md): la identidad visual, con los tokens, las tipografías y el mundo de cada Juego.
- [`PRODUCT.md`](../PRODUCT.md): los usuarios, el propósito y los principios.
- [ADR 0001](adr/0001-anotaciones-y-puntaje-calculado.md): las Partidas guardan Anotaciones y el puntaje se calcula.
- Prototipo visual (referencia, no se mergea): rama `prototype/identidad-visual`, `prototypes/identidad-visual/index.html`.

---

## 1. Producto y alcance

**Porotos** reemplaza el papel y la birome para llevar la cuenta. Lo usa un **anotador**: alguien de la mesa que tiene el teléfono, anota entre jugada y jugada, muchas veces con poca luz, y vuelve a la conversación.

**Entra en el MVP:**

- Partidas de Truco, Generala y Burako, con la Variante estándar argentina de cada uno y pocas opciones.
- Varias Partidas En curso a la vez.
- Historial de las Partidas Terminadas.
- Jugadores guardados y reutilizables.

**Queda fuera del MVP:**

- Estadísticas (quién gana más, rachas).
- Sincronización con iCloud o entre dispositivos.
- iPad, Apple Watch y otras plataformas.
- Otros Juegos (el modelo tiene que permitir agregarlos; ver [§3.6](#36-agregar-un-juego)).
- Series de varias Partidas (por ejemplo, Truco al mejor de 3).
- Conteo automático de fichas de Burako a partir de una foto.
- Ajustes o preferencias de la app.
- Una variante propia para Aumentar contraste.

## 2. Plataforma y restricciones

- **Stack:** SwiftUI y SwiftData, **iOS 17+**, solo iPhone, **solo vertical**.
- **Offline:** sin backend, sin cuentas, sin red. No hay SDKs de terceros ni analíticas.
- **Precio:** gratis, sin anuncios y sin compras dentro de la app.
- **Idioma:** toda la app en español rioplatense (voseo, tono cálido). No hay otras localizaciones.
- **Nombre:** Porotos. Bundle ID: `com.facundocapua.porotos`.
- **Distribución:** el MVP se distribuye por TestFlight, y más adelante se publica en la App Store (ver [§9](#9-publicación)).
- **Persistencia:** cada cambio se guarda al instante en SwiftData. Cerrar la app, o que iOS la mate, nunca hace perder una Partida.

## 3. Modelo de dominio

Las definiciones están en `GLOSSARY.md`. Esta sección fija cómo se relacionan los conceptos.

### 3.1 Partida

Es común a todos los Juegos y tiene:

- **Juego** y **Variante** (las opciones propias del Juego).
- **Participantes** en orden.
- **Anotaciones** en orden, más el historial de cambios que usa Deshacer (ver [§3.4](#34-anotaciones-y-cálculo)).
- **Estado:** En curso o Terminada. No hay más estados: una Partida que no se quiere terminar se descarta, es decir, se borra.
- La marca **Terminada antes**, si se terminó a pedido antes del fin que marcan las reglas.
- **Fecha de inicio**, **fecha de fin** y **fecha de la última Anotación** (para ordenar el Inicio).
- **Ganadores** (uno o más). Se calculan, no se guardan.
- Para Burako, el **borrador** de la Mano que está a medio cargar, si lo hay.

Puede haber varias Partidas En curso, incluso del mismo Juego. El Historial muestra solo las Terminadas.

### 3.2 Participante

Es quien suma puntos y puede ganar. Tiene un **nombre** y **cero o más Jugadores**.

| Juego | Participantes |
|---|---|
| Truco | Siempre 2 Equipos. Los Jugadores son opcionales y se asignan libremente (cualquier cantidad por Equipo, incluso desparejos o todos en uno). |
| Generala | De 2 a 6 Jugadores, uno por Participante. Sin Equipos. |
| Burako individual | De 2 a 4 Jugadores, uno por Participante. |
| Burako en parejas | 2 Equipos de exactamente 2 Jugadores cada uno. |

### 3.3 Jugador y Equipo

- **Jugador:** solo tiene un **nombre**, que no se repite. Se compara sin distinguir mayúsculas, tildes ni espacios a los costados, y tiene hasta **20 caracteres**. No hay invitados: un nombre nuevo al crear una Partida queda guardado como Jugador. Aparece como máximo una vez por Partida.
- **Equipo:** es un Participante que vive solo dentro de su Partida y no se reutiliza.
  - Su nombre tiene hasta **30 caracteres** y nunca queda vacío: si se borra, vuelve al nombre por defecto.
  - Los dos Equipos de una Partida pueden llamarse igual.
  - **Nombre por defecto:**
    - **Truco:** "Nosotros" y "Ellos".
    - **Burako:** se arma con los nombres de los Jugadores ("Facu y Caro") y es editable. Si cambia la pareja, vuelve al automático.
- **Renombrar un Jugador** cambia el nombre en todos lados, también en el Historial.
- **Borrar un Jugador** está permitido aunque tenga Partidas, incluso alguna En curso. Las Partidas conservan el último nombre que tenía, así que al borrarlo se copia su nombre a cada Partida donde jugó.

### 3.4 Anotaciones y cálculo

Detalle en el [ADR 0001](adr/0001-anotaciones-y-puntaje-calculado.md).

- **Anotación por Juego:**
  - **Truco:** un tanto de +1 o −1 para un Equipo.
  - **Generala:** una celda de la Planilla (Jugador, categoría, valor o Tachado, y si fue servida).
  - **Burako:** una Mano, con los campos de la calculadora para cada Participante.
- Los **puntajes, el fin de la Partida y los Ganadores se calculan siempre** a partir de las Anotaciones. Nunca se guardan totales.
- **Deshacer** revierte **el último cambio**, sin límite mientras la Partida está En curso:
  - si se agregó una Anotación, la saca;
  - si se editó una (una celda de Generala o una Mano de Burako), restaura el valor anterior.

  El historial de cambios se guarda con la Partida, así que Deshacer funciona igual después de reabrir la app.

### 3.5 Recordar la última configuración

Al crear una Partida, cada Juego precarga la Variante y los Participantes de **su última Partida que todavía existe**, esté En curso o Terminada. Si un Jugador de esa Partida fue borrado, su lugar queda vacío. La primera vez se usan los valores estándar de cada Juego (ver [§5.2](#52-crear-partida)).

### 3.6 Agregar un Juego

Un Juego nuevo define:

- sus opciones de Variante y sus valores estándar;
- sus reglas de Participantes (cantidad, si van en Equipos, mínimo para empezar);
- su tipo de Anotación y cómo se calculan los puntajes;
- su regla de fin y de Ganadores;
- su pantalla de Partida, con un mundo propio (fondo, paleta, tipografía de display y un gesto distintivo; ver `DESIGN.md`).

El resto (Inicio, Historial, Jugadores, Deshacer, terminar y descartar) es común y no cambia.

## 4. Reglas por Juego

La app es un **anotador, no un árbitro**: solo hace cumplir las reglas que se nombran acá.

### 4.1 Truco

- **Variante:** solo el puntaje, **a 15 o a 30** (por defecto, **30**). No hay opción de flor ni de formato (1 vs 1, 2 vs 2, 3 vs 3). El envido, la flor y los demás cantos son tantos que el anotador suma a mano. No se registra cada canto ni hay Manos.
- **Anotar:** +1 o −1 tanto por Equipo. El −1 se deshabilita cuando el Equipo tiene 0.
- **Malas y Buenas:**
  - **A 30:** de 0 a 15 son las malas y de 15 a 30 las buenas.
  - **A 15:** no se divide (un solo bloque de tres grupos de fósforos).
  - El número grande muestra el **total corrido** (por ejemplo, 18), no "3 buenas". La división se ve solo en los fósforos y en la raya punteada.
- **Fin:** cuando un Equipo llega al puntaje, gana y la Partida termina sola. No se puede pasar del puntaje.
- **Empates:** no hay, salvo en una Partida Terminada antes.

### 4.2 Generala

- **Variante:** una sola opción, **"Generala servida gana"**, activada por defecto.
- **Jugadores:** de 2 a 6, uno por columna, en el orden de los Turnos.
- **Planilla:** 11 categorías por Jugador.

| Categoría | Valores | Servido |
|---|---|---|
| 1 a 6 | Suma de los dados de esa cara: de 1 a 5 veces la cara. Sin bonus de sección. | No aplica |
| Escalera | 20 | 25 |
| Full | 30 | 35 |
| Póker | 40 | 45 |
| Generala | 50 | Gana la Partida (con la opción activada) o vale 55 (con la opción desactivada) |
| Doble Generala | 100 | 100 |

- **Tachar** anota 0 en cualquier categoría.
- **Generala servida (con la opción activada):** el Jugador gana en el acto y la Partida termina.
- **Doble Generala:** solo se anota con puntos si el Jugador ya tiene la Generala con puntos (50, o 55 servida con la opción desactivada). Si la Generala está vacía o tachada, en Doble solo se puede Tachar.
  - La app lo hace cumplir también al corregir: si un Jugador tiene la Doble con puntos, no se puede tachar ni vaciar su Generala. La app lo rechaza con un aviso, y hay que tachar o vaciar primero la Doble.
- **Turnos:** el Turno pasa solo al siguiente Jugador que tenga categorías libres, en el orden de la Partida, cuando el que tira anota. También se puede anotar en la columna de otro Jugador: el Turno es una guía, no una traba.
- **Fin:** cuando todos llenaron sus 11 categorías (con puntos o tachadas), o con una Generala servida si la opción está activada.
- **Ganadores:** el mayor total. Si hay empate en el primer puesto, es un empate compartido, sin desempate.

### 4.3 Burako

- **Modalidad:** individual de 2 a 4 Jugadores, o 2 parejas (2 vs 2). No se juega con 3 parejas. Se anota por Participante.
- **Variante:**
  - **Meta:** 3000 por defecto, con atajos de 2000, 2500 y 3000, o un valor libre.
  - **Muerto:** tres opciones.

    | Opción | Tomarlo | No tomarlo |
    |---|---|---|
    | **Suma y resta** (por defecto) | +100 | −100 |
    | **Solo resta** | 0 | −100 |
    | **Solo suma** | +100 | 0 |

  - Los demás valores son fijos.
- **Calculadora por Mano**, para cada Participante:

  | Campo | Control | Valor |
  |---|---|---|
  | Canastas limpias | stepper | × 200 |
  | Canastas sucias | stepper | × 100 |
  | Fichas en mesa | número sumado a mano | suma |
  | Fichas en mano | número sumado a mano | resta |
  | Cerró | switch | +100. Lo marca como máximo un Participante por Mano, o ninguno |
  | Tomó el muerto | switch | según la opción Muerto de la Variante |

  - En parejas se carga un solo número de fichas en mesa y uno de fichas en mano por Equipo (la suma de los dos compañeros).
  - Junto a los campos de fichas se muestran como ayuda los valores: comodín 50, 2 = 20, 1 = 15, de 8 a 13 = 10 y de 3 a 7 = 5. La app no cuenta ficha por ficha.
  - **Resultado de la Mano:** limpias × 200 + sucias × 100 + fichas en mesa − fichas en mano + Cerró + Muerto.
  - **Sin validación de reglas:** por ejemplo, deja marcar Cerró sin canastas. Los totales negativos se permiten.
- **Fin:** al terminar una Mano en la que algún Participante llegó a la Meta o la pasó, gana el total más alto. Si hay empate arriba, la Partida sigue y se juega otra Mano para desempatar.

### 4.4 Terminada antes

En cualquier Juego, "Terminar con este resultado" (ver [§6.3](#63-terminar-descartar-y-borrar)) termina la Partida en el acto. Ganan los que van primeros, con Ganadores compartidos si hay empate, y la Partida queda marcada como **Terminada antes**.

## 5. Pantallas y navegación

Estructura: shell iOS nativo con tab bar **Jugar · Historial · Jugadores**. La pantalla de Partida va a pantalla completa, con el mundo de su Juego.

### 5.1 Inicio (tab Jugar)

- Al abrir la app se llega siempre al Inicio. Si iOS la mantuvo en memoria, vuelve donde estaba.
- **Sin Partidas En curso:** el wordmark "Porotos" y las tres tarjetas de Juego (Nueva partida). No hay onboarding.
- **Con Partidas En curso:**
  - Arriba, una fila por Partida (Juego, Participantes, puntaje y "Seguir"), la última anotada primero.
  - Se ven hasta 3. "Ver todas" abre la lista completa.
  - En las filas y en "Ver todas", **swipe para borrar**, con confirmación. Es lo mismo que Descartar.
  - Debajo, las tarjetas de Juego.
- Un ícono abre **"Acerca de Porotos"**, con la política de privacidad, el contacto (correo) y la versión. No hay preferencias.

### 5.2 Crear Partida

- Una sola pantalla por Juego, en un sheet a pantalla completa:
  - los Participantes arriba;
  - la Variante siempre a la vista, abajo;
  - "Empezar" fijo al pie, deshabilitado hasta cumplir el mínimo del Juego.
- **Precarga** la última configuración de ese Juego (ver [§3.5](#35-recordar-la-última-configuración)): repetir una Partida son dos toques. Si ya hay una Partida En curso de ese Juego, crea otra sin avisar.
- **Primera vez de cada Juego:**
  - **Truco:** "Nosotros" contra "Ellos", a 30.
  - **Generala:** lista vacía, con "Generala servida gana" activada.
  - **Burako:** Parejas con los lugares vacíos, Meta 3000 y Muerto "Suma y resta".
- **Controles de la Variante:**
  - **Truco:** segmented 15 / 30.
  - **Generala:** un switch.
  - **Burako:** Meta (2000 / 2500 / 3000 / Otra) y Muerto (tres opciones).
- **Selector de Jugadores:**
  - Tiene buscador y muestra primero a los que jugaron hace menos.
  - Si se escribe un nombre nuevo, aparece "Agregar «Nombre»", que lo crea y lo elige. Si el nombre ya existe (con la comparación de [§3.3](#33-jugador-y-equipo)), se ofrece el existente.
  - Los que ya están en la Partida desaparecen del selector. Para pasar a alguien a otro Equipo, primero se lo saca del suyo.
- **Generala y Burako individual:** el orden se arrastra. En Generala es el orden de los Turnos. No hay sorteo.
- **Burako:**
  - Un segmented elige **Individual** o **Parejas**. En Parejas hay dos bloques de dos lugares, y los Jugadores se intercambian arrastrando.
  - Al cambiar de modo se conservan los elegidos: las parejas se arman 1 y 2 contra 3 y 4.
- **Truco:** los dos nombres de Equipo y "Agregar Jugadores" como acción secundaria.
- **Mínimos para Empezar:**
  - **Truco:** siempre se puede.
  - **Generala:** 2 Jugadores.
  - **Burako:** 2 Jugadores en individual, o los 4 lugares completos en Parejas.

### 5.3 Pantalla de Partida

- A pantalla completa, sin tab bar, en el mundo del Juego (ver `DESIGN.md`).
- **Navegación:**
  - **"Inicio"** arriba a la izquierda sale sin confirmación, y la Partida queda En curso.
  - **Arriba a la derecha:** Deshacer y un menú "⋯".
  - **El menú "⋯"** tiene los detalles (Variante y Participantes), la edición de la Variante y de los nombres de Equipo (ver [§6.4](#64-cambios-a-mitad-de-partida)) y, en Generala y Burako, "Terminar partida".
  - **Truco:** "Terminar partida" va aislado al pie.
- **Truco:** tocar la columna de un Equipo o su botón +1 suma un tanto. El − está al costado.
- **Generala:** tocar una celda abre un sheet nativo con los valores posibles de la categoría, la opción servida (si aplica) y Tachar. Una celda ya anotada abre el mismo sheet, para cambiar el valor, tacharla o vaciarla.
- **Burako:**
  - La pantalla muestra la carrera hacia la Meta: un atril por Participante con el total en fichas y "faltan N", y debajo las Manos jugadas como chips.
  - El botón principal "Anotar mano N" abre la calculadora, con un segmented por Participante.
  - Tocar el chip de una Mano la abre en la calculadora para corregirla.
- **Pantalla encendida** mientras la Partida está abierta en primer plano.

### 5.4 Fin de Partida

- Es igual en los tres Juegos, en el mundo de cada uno. Muestra:
  - los Ganadores (con "Empate" si son varios);
  - los puntajes finales de todos, con posiciones si hay más de dos Participantes;
  - los botones **Revancha** (principal) e **Inicio**.
- En Truco, la pantalla se invierte con "¡Ganaron …!".
- Se puede ver la Planilla o las Manos (solo lectura). **Deshacer** sigue visible y reabre la Partida (ver [§6.2](#62-deshacer-el-final)).
- **Revancha** empieza directo con los mismos Participantes, orden y Variante.
  - Si falta un Jugador borrado y el resto cumple el mínimo del Juego, empieza sin él.
  - Si no lo cumple (o si en Burako en Parejas queda una pareja incompleta), abre Crear Partida con lo demás cargado.

### 5.5 Historial

- **Lista:**
  - Solo Partidas Terminadas, agrupadas por mes, la más nueva primero.
  - Cada fila muestra el Juego, los Ganadores destacados, los puntajes y la fecha. Las etiquetas "Empate" y "Terminada antes" aparecen cuando corresponde.
  - Filtro por Juego, sin búsqueda.
  - Swipe para borrar, con confirmación y sin papelera.
- **Detalle:**
  - Es de solo lectura, con la fecha, la duración (de la fecha de inicio a la de fin), la Variante, los Participantes con sus Jugadores y el resultado completo en el mundo del Juego.
  - En un empate, las posiciones compartidas muestran el "1.º" repetido.
  - Tiene **"Jugar de nuevo"** (funciona como Revancha) y Borrar.
- **Vacío:** "Todavía no terminaron ninguna partida", con el botón "Empezar una".

### 5.6 Jugadores

- Lista alfabética con "+".
- Tocar un Jugador abre un sheet para **renombrarlo** o **borrarlo** (con confirmación).
  - Al renombrar con un nombre que ya existe, un aviso en línea no deja guardar.
  - Si está en una Partida En curso, la confirmación de borrado dice "Está jugando una partida en curso".
- No hay ficha del Jugador ni contadores.
- **Vacío:** "Acá va a estar la barra", con el botón "Agregar jugador".

## 6. Casos borde

### 6.1 Corregir

- **Deshacer:** revierte el último cambio, sin límite mientras la Partida está En curso (ver [§3.4](#34-anotaciones-y-cálculo)).
- **Generala:** se edita en el lugar (ver [§5.3](#53-pantalla-de-partida)), con la regla de la Doble Generala de [§4.2](#42-generala).
- **Burako:** se corrige una Mano en la calculadora. Si la corrección hace que alguien llegue a la Meta en una Mano anterior a la última, la app la rechaza con un aviso, para que no queden Manos después del fin.
- **Truco:** no se edita. Se corrige con Deshacer o con −1.

### 6.2 Deshacer el final

- Una Partida Terminada se reabre solo con Deshacer desde la pantalla de fin.
- Al salir de ahí, con Revancha, con Inicio o porque se cerró la app, el final queda firme.
- El detalle del Historial es siempre de solo lectura.

### 6.3 Terminar, descartar y borrar

- **"Terminar partida"** ofrece dos opciones:
  - **"Terminar con este resultado":** la Partida queda Terminada antes (ver [§4.4](#44-terminada-antes)).
  - **"Descartar partida":** con confirmación, la Partida se borra.
- **Borrar:** con swipe y confirmación, sin papelera. Vale para las Partidas Terminadas (en la lista y en el detalle del Historial) y para las En curso (en las filas del Inicio y en "Ver todas").

### 6.4 Cambios a mitad de Partida

- **Variante:** se puede cambiar desde "⋯" mientras la Partida está En curso. Se deshabilitan las opciones que la terminarían en el acto:
  - Truco a 15 cuando algún Equipo tiene 15 o más;
  - una Meta igual o menor que algún total de Burako;
  - activar "Generala servida gana" si ya hubo una Generala servida.
- **Nombres de Equipo:** se editan desde "⋯", con las reglas de [§3.3](#33-jugador-y-equipo).
- **Participantes:** quedan fijos una vez empezada la Partida, incluido el orden de los Turnos de Generala.
- **Jugadores:** se pueden renombrar o borrar en cualquier momento (ver [§3.3](#33-jugador-y-equipo) y [§5.6](#56-jugadores)).

### 6.5 Cierre de la app

- Cada cambio se guarda al instante.
- La Mano de Burako a medio cargar se guarda como borrador de su Partida y se restaura al volver, aunque iOS haya matado la app.
- Un valor de Generala sin confirmar en el sheet se pierde.

## 7. Identidad visual

Todo el detalle está en [`DESIGN.md`](../DESIGN.md). En resumen:

- **Shell:** iOS nativo con colores semánticos del sistema, tint poroto colorado `#8E2A23` y el wordmark en Shrikhand. Sigue el modo claro u oscuro del sistema.
- **Mundos de Juego, siempre oscuros:**
  - **Truco:** fósforos sobre una mesa de noche, con Bevan.
  - **Generala:** paño de casino con latón, con Abril Fatface.
  - **Burako:** fichas marfil sobre una mesa verde petróleo, con Alfa Slab One.
- Las fuentes de display van incluidas en la app y solo se usan en momentos de display. El resto del texto usa SF con Dynamic Type.
- **Ícono:** "Puñado de porotos".

## 8. Accesibilidad y uso en la mesa

Detalle en la sección "Accesibilidad y uso en la mesa" de `DESIGN.md`.

- **Contraste:** WCAG AA. El tachado de Generala es un "✕" en el color del texto. La ficha amarilla de Burako es `#946409`. El latón va solo en texto grande y bordes.
- **Dynamic Type:**
  - El shell y las pantallas de texto escalan sin límite.
  - Los números de display de los mundos no escalan.
  - La Planilla de Generala escala hasta xxxLarge. Desde AX1, la columna de categorías queda fija y las columnas de Jugadores se desplazan en horizontal.
- **VoiceOver:** soporte completo.
  - Los fósforos se leen como "Nosotros, 17, buenas 2" y son ajustables: deslizar arriba o abajo suma o resta un tanto.
  - Las celdas se leen como "Ana, Full, 30, servido".
  - Los totales en fichas se leen como número ("1.240, faltan 1.760").
  - La calculadora usa controles nativos con etiquetas.
- **Una mano:** las acciones frecuentes van en los dos tercios de abajo, con objetivos de al menos 44 pt. No hay gestos ocultos.
- **Hápticos:**
  - un toque liviano por cada tanto o celda anotada;
  - uno de éxito al terminar la Partida;
  - uno de advertencia al deshacer.

  Respetan el ajuste del sistema.
- **Reducir movimiento:** las animaciones pasan a ser fundidos cortos.

## 9. Publicación

Fuente: [Requisitos de la App Store para una app gratis y offline](https://github.com/facundocapua/scores-app/issues/7).

**Antes de construir:**

1. **Renovar la membresía del Apple Developer Program** (99 USD por año). Venció el 2026-08-22, y la renovación está pendiente con el soporte de Apple. Hace falta incluso para TestFlight.
2. **Crear el registro en App Store Connect** para reservar el nombre:
   - nombre **Porotos**;
   - subtítulo **"Anotador de juegos de mesa"**;
   - bundle ID `com.facundocapua.porotos`;
   - idioma principal Spanish (Mexico), porque App Store Connect no tiene una variante rioplatense.

**Requisitos de la build y de la ficha:**

- **Etiqueta de privacidad:** "Data Not Collected". Para que siga valiendo, no se agregan SDKs de terceros ni analíticas.
- **Política de privacidad y soporte:**
  - Dos páginas estáticas en **GitHub Pages** del repo: la política de privacidad (la app no recopila datos) y el soporte, con un correo de contacto que se define al construir.
  - Las dos URLs se cargan en App Store Connect.
  - "Acerca de Porotos" enlaza las dos páginas y muestra el correo (guideline 5.1.1).
- **Ícono:** 1024 × 1024, sin canal alfa.
- **Capturas:** se necesitan cuando se publique en la App Store, no para TestFlight. De 1 a 10 capturas de iPhone en 1290 × 2796, que cubren los dos tamaños requeridos.
- **TestFlight:** hasta 100 testers internos sin revisión, y externos con una Beta App Review del primer build. Los builds duran 90 días.
- **Rating:** 4+ esperable. Un anotador no es gambling. Evitar mencionar apuestas con dinero.
- **Países:** la disponibilidad por país se elige al publicar en la App Store, después del MVP.

## 10. Criterios de aceptación del MVP

- [ ] Se crea, se juega y se termina una Partida de cada Juego, y aparece en el Historial con los Ganadores correctos.
- [ ] Repetir la última Partida de un Juego toma dos toques desde el Inicio.
- [ ] Truco a 15 y a 30: los fósforos se agrupan de a cinco, se ven las malas y las buenas a 30, y la Partida termina sola al llegar al puntaje.
- [ ] Generala: cumple la tabla de puntos, el servido, la Generala servida (con la opción activada y desactivada), la regla de la Doble (también al corregir), los Turnos y el empate compartido.
- [ ] Burako: la calculadora da el resultado de [§4.3](#43-burako) con las tres opciones de Muerto, en individual y en parejas, y desempata con otra Mano.
- [ ] Deshacer revierte agregados y ediciones en orden, también después de reabrir la app, y reabre una Partida desde la pantalla de fin.
- [ ] Matar la app a mitad de una Partida, o de una Mano de Burako, no pierde nada.
- [ ] Borrar un Jugador conserva su nombre en el Historial y en las Partidas En curso.
- [ ] Pasa una revisión de VoiceOver y de Dynamic Type (hasta AX5) en las tres pantallas de Partida.
- [ ] La build no hace ninguna solicitud de red.
