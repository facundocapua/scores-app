# Design

Identidad visual de **Porotos**. Decidida en el ticket [Identidad visual con impeccable](https://github.com/facundocapua/scores-app/issues/3). El prototipo de referencia está en la rama `prototype/identidad-visual` (`prototypes/identidad-visual/index.html`).

## Principio

**Un shell común y un mundo por Juego.** La app (inicio, Historial, Jugadores, ajustes) es iOS nativo con el color de la marca. Al entrar a una Partida, la pantalla de anotación adopta el mundo propio de su Juego. El mundo aporta fondo, paleta, tipografía de display y un gesto distintivo. La navegación y los controles son siempre los nativos de iOS (barra de navegación, sheets, steppers, switches y segmented control).

Agregar un Juego nuevo significa definir su mundo con estos mismos cuatro elementos.

## Shell (Porotos)

- **Marca:** poroto colorado `#8E2A23` como tint, con texto `#FFF6EE` sobre él.
- **Fondo y superficies:** colores semánticos del sistema (`systemGroupedBackground` y `secondarySystemGroupedBackground`). Modo claro y oscuro automáticos.
- **Wordmark:** "Porotos" en **Shrikhand**, solo en el título del inicio. Todo lo demás usa SF Pro con Dynamic Type.
- **Inicio = selector de juego:** fila "Partida en curso" con el botón Seguir y, debajo, "Nueva partida" con una tarjeta grande por Juego que anticipa su mundo (fósforos, dados sobre paño y fichas).
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
- **Acentos:** latón `#D8B45A` para el título, el marco de la planilla, los totales y el Jugador que tira. Texto `#F4F0E2`. Tachado en `#E05A4F`.
- **Planilla:** las categorías van en filas (1 a 6 con caras de dado, Escalera, Full, Póker, Generala, Doble Generala y Total) y los Jugadores en columnas. Una línea separa la sección de números de la de juegos.
- **Turno:** la columna del Jugador que tira se resalta con un velo de latón y el rótulo "Tira".
- **Celdas:** vacías, con un punto tenue; Servido con una "S" en superíndice latón; Tachado como un 0 tachado.
- **Display:** **Abril Fatface** para el título y los totales. Los números de las celdas van en SF Rounded tabular.
- **Interacción:** tocar una celda abre un sheet nativo con los valores posibles, la opción servida y Tachar. Al anotar, el turno pasa al Jugador siguiente. Terminar partida va en el menú "⋯".

## Burako: fichas sobre la mesa

- **Fondo:** mesa verde petróleo, de `#123B40` a `#0C2C30`. Texto `#EAF2F0`, secundario `#9DB9B6` y acción `#F2C14E`.
- **Fichas:** marfil `#F7F2E6` con canto `#D9CFB8`. Los números van en los cuatro colores de las fichas: rojo `#C62828`, azul `#1E5BB8`, negro `#1F1F1F` y amarillo `#D9930D`. Los puntajes totales se escriben con fichas, un dígito por ficha, alternando colores.
- **Display:** **Alfa Slab One** para fichas y títulos.
- **Pantalla de Partida (carrera):** un atril por Equipo con el total en fichas y una barra de progreso hacia la meta ("faltan N"). Debajo, las Manos jugadas como chips. Botón principal: "Anotar mano N". Terminar partida va en el menú "⋯".
- **Anotar mano (calculadora):** pantalla con el total de cada Equipo en miniatura y un segmented control Nosotros/Ellos. Incluye steppers para canastas limpias y sucias, campos numéricos para las fichas en mesa y en mano, y switches para Cerró y Tomó el muerto. Muestra el resultado de la mano en fichas y en cuánto quedaría el Equipo. Los campos exactos dependen de las reglas de Burako.

## Ícono

**Puñado de porotos:** cuatro porotos sueltos (dos colorados `#8E2A23`, uno negro `#2B211C` y uno dorado `#C9A15A`) sobre un fondo claro `#F6EBDD`.

## Reglas comunes

- Objetivos táctiles de al menos 44 pt. El +1 y la acción principal ocupan todo el ancho del pulgar en la parte baja de la pantalla.
- Las acciones destructivas (Terminar partida) quedan separadas de las de sumar.
- Las fuentes de display (Shrikhand, Bevan, Abril Fatface y Alfa Slab One) van incluidas en la app y solo se usan en momentos de display. Todo el texto de UI usa SF con Dynamic Type.
- Los valores de puntaje que muestra el prototipo son provisorios hasta que se cierren las reglas de cada Juego.

## Abierto

Estos temas están en el fog del mapa: el modo claro de los mundos de Juego (hoy son todos oscuros o de color pleno), el comportamiento con Dynamic Type grande en la planilla de Generala y la pantalla siempre encendida.
