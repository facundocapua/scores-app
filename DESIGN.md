# Design

Identidad visual de **Porotos**. Decidida en el ticket [Identidad visual con impeccable](https://github.com/facundocapua/scores-app/issues/3). El prototipo de referencia está en la rama `prototype/identidad-visual` (`prototypes/identidad-visual/index.html`).

## Principio

**Un shell común y un mundo por Juego.** La app (Inicio, Historial, Jugadores y "Acerca de Porotos") es iOS nativo con el color de la marca. Al entrar a una Partida, la pantalla de anotación adopta el mundo propio de su Juego. El mundo aporta fondo, paleta, tipografía de display y un gesto distintivo. La navegación y los controles son siempre los nativos de iOS (barra de navegación, sheets, steppers, switches y segmented control).

Agregar un Juego nuevo significa definir su mundo con estos mismos cuatro elementos.

## Shell (Porotos)

- **Marca:** poroto colorado `#8E2A23` como tint, con texto `#FFF6EE` sobre él.
- **Fondo y superficies:** colores semánticos del sistema (`systemGroupedBackground` y `secondarySystemGroupedBackground`). Modo claro y oscuro automáticos.
- **Wordmark:** "Porotos" en **Shrikhand**, solo en el título del inicio. Todo lo demás usa SF Pro con Dynamic Type.
- **Inicio = selector de juego:** arriba, una fila por Partida En curso con el botón Seguir (hasta 3, más "Ver todas"); debajo, "Nueva partida" con una tarjeta grande por Juego que anticipa su mundo (fósforos, dados sobre paño y fichas). El flujo completo está en `docs/SPEC.md`.
- **Tab bar:** Jugar · Historial · Jugadores.

## Truco: fósforos

- **Fondo:** mesa de noche, de `#221A15` a `#17120F`. Siempre oscuro.
- **Fósforos:** palo `#E8CF9C` con borde `#B99560` y cabeza `#C23B22`. Cada grupo de cinco forma un cuadrado (izquierda, arriba, derecha, abajo) más la diagonal.
- **Layout:** dos columnas (Nosotros | Ellos). Cada una muestra el nombre, el número de tantos, los fósforos de las malas, una raya punteada y los de las buenas.
- **Jerarquía:** el Equipo que va ganando se ve más grande y en ámbar `#F2B33D`; el otro, más chico y atenuado `#A8998A`.
- **Display:** **Bevan** para nombres, números y el botón +1.
- **Interacción:** tocar la columna o el +1 suma un tanto. El − está al costado. Deshacer va en la barra de navegación. Terminar partida queda aislado al pie, en `#E8826F`.
- **Fin:** al llegar al máximo, la pantalla se invierte (fondo claro `#F3E9D8`, texto oscuro) con "¡Ganaron …!" y el botón Revancha.

## Generala: paño de casino

- **Fondo:** paño verde con luz cenital, de `#127049` a `#0D5A3B` y `#083D28`.
- **Acentos:** latón `#D8B45A` para el título, el marco de la planilla, los totales y el Jugador que tira. Texto `#F4F0E2`. El latón solo va en texto grande y bordes, nunca en texto chico.
- **Planilla:** las categorías van en filas (1 a 6 con caras de dado, Escalera, Full, Póker, Generala, Doble Generala y Total) y los Jugadores en columnas. Una línea separa la sección de números de la de juegos.
- **Turno:** la columna del Jugador que tira se resalta con un velo de latón y el rótulo "Tira".
- **Celdas:** vacías, con un punto tenue; Servido con una "S" en superíndice latón; Tachado como un "✕" en el color del texto `#F4F0E2` (no depende solo del color).
- **Display:** **Abril Fatface** para el título y los totales. Los números de las celdas van en SF Rounded tabular.
- **Interacción:** tocar una celda abre un sheet nativo con los valores posibles, la opción servida y Tachar. Al anotar, el turno pasa al Jugador siguiente. Terminar partida va en el menú "⋯".

## Burako: fichas sobre la mesa

- **Fondo:** mesa verde petróleo, de `#123B40` a `#0C2C30`. Texto `#EAF2F0`, secundario `#9DB9B6` y acción `#F2C14E`.
- **Fichas:** marfil `#F7F2E6` con canto `#D9CFB8`. Los números van en los cuatro colores de las fichas: rojo `#C62828`, azul `#1E5BB8`, negro `#1F1F1F` y ámbar `#946409` (el amarillo `#D9930D` del prototipo oscurecido sin cambiar el tono hasta pasar 4.5:1 sobre el marfil: da 4.6:1). Los puntajes totales se escriben con fichas, un dígito por ficha, alternando colores.
- **Display:** **Alfa Slab One** para fichas y títulos.
- **Pantalla de Partida (carrera):** un atril por Participante (Jugador o Equipo) con el total en fichas y una barra de progreso hacia la meta ("faltan N"). Debajo, las Manos jugadas como chips. Botón principal: "Anotar mano N". Terminar partida va en el menú "⋯".
- **Anotar mano (calculadora):** pantalla con el total de cada Participante en miniatura y un segmented control con sus nombres. Incluye steppers para canastas limpias y sucias, campos numéricos para las fichas en mesa y en mano, y switches para Cerró y Tomó el muerto. Muestra el resultado de la mano en fichas y en cuánto quedaría el Participante. Los valores están en `docs/SPEC.md`.

## Ícono

**Puñado de porotos:** cuatro porotos sueltos (dos colorados `#8E2A23`, uno negro `#2B211C` y uno dorado `#C9A15A`) sobre un fondo claro `#F6EBDD`.

## Reglas comunes

- Objetivos táctiles de al menos 44 pt. El +1 y la acción principal ocupan todo el ancho del pulgar en la parte baja de la pantalla.
- Las acciones destructivas (Terminar partida) quedan separadas de las de sumar.
- Las fuentes de display (Shrikhand, Bevan, Abril Fatface y Alfa Slab One) van incluidas en la app y solo se usan en momentos de display. Todo el texto de UI usa SF con Dynamic Type.
- Los valores de puntaje del prototipo no son la referencia: las reglas de cada Juego están en `docs/SPEC.md`.

## Accesibilidad y uso en la mesa

Decidido en [Accesibilidad y uso en la mesa](https://github.com/facundocapua/scores-app/issues/11).

- **Contraste:** WCAG AA. 4.5:1 para texto chico y 3:1 para texto grande y gráficos. Sin variante propia para Aumentar contraste.
- **Modo claro:** el shell sigue el modo del sistema. Los mundos de Juego son siempre oscuros (el fin de Truco se invierte igual).
- **Dynamic Type:** el shell y las pantallas de texto escalan sin límite. Los números de display de los mundos (el total de Truco, las fichas de Burako) no escalan. La planilla de Generala escala hasta xxxLarge; desde AX1, la columna de categorías queda fija y las columnas de Jugadores se desplazan en horizontal.
- **VoiceOver:** soporte completo. Los fósforos se leen como "Nosotros, 17, buenas 2" y son ajustables (deslizar arriba o abajo suma o resta un tanto). Las celdas se leen como "Ana, Full, 30, servido". Los totales en fichas se leen como número ("1.240, faltan 1.760").
- **Pantalla encendida:** automática mientras hay una Partida abierta en primer plano, sin opción. En el shell, el Historial y la pantalla de fin vuelve al comportamiento normal.
- **Orientación:** solo vertical.
- **Una mano:** las acciones frecuentes van en los dos tercios de abajo. Deshacer queda en la barra de navegación. Sin gestos ocultos (nada de agitar para deshacer).
- **Hápticos:** un toque liviano por cada tanto o celda anotada, uno de éxito al terminar y uno de advertencia al deshacer. Respetan el ajuste del sistema, sin interruptor propio.
- **Reducir movimiento:** las animaciones (el fósforo, las fichas, la inversión del fin) pasan a ser fundidos cortos.
