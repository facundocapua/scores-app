# Glosario

Lenguaje del dominio de la app de anotador de juegos de mesa. Solo términos, no detalles de implementación.

**Juego**: Uno de los juegos de mesa soportados (Generala, Burako, Truco). Define sus reglas y su forma de anotar.

**Partida**: Una sesión concreta de un Juego, con sus Participantes y su Variante, desde el inicio hasta que hay ganadores o se abandona. Está En curso, Terminada o Abandonada. Puede haber varias Partidas En curso a la vez.

**Participante**: Quien suma puntos y puede ganar en una Partida. Tiene un nombre y cero o más Jugadores. Según el Juego, es un Jugador o un Equipo.

**Anotación**: Cada acción de anotar puntos en una Partida (por ejemplo, un tanto en Truco, una celda de la Planilla en Generala o una Mano en Burako). Los puntajes de una Partida se calculan a partir de sus Anotaciones.

**Ganadores**: Los Participantes que ganan una Partida Terminada. Suele ser uno, pero en Generala puede haber un empate compartido. Los Jugadores ganan a través de su Participante.

**Jugador**: Persona guardada en la app y reutilizable entre Partidas. Solo tiene un nombre, que no se repite. No hay invitados: un nombre nuevo al crear una Partida queda guardado como Jugador. Si se borra, el Historial conserva el nombre con el que jugó. Aparece como máximo una vez por Partida.

**Equipo**: Participante que agrupa Jugadores bajo un nombre propio (Truco siempre; Burako cuando se juega en parejas, con exactamente dos Jugadores). Existe solo dentro de su Partida.

**Variante**: Conjunto de opciones de reglas elegidas al crear una Partida (por ejemplo, Truco a 15 o a 30). Cada Juego tiene una Variante estándar argentina. Una Partida nueva propone la Variante y los Participantes de la última Partida de ese Juego.

**Historial**: Listado de Partidas Terminadas.

**Revancha**: Partida nueva que repite el Juego, la Variante y los Participantes (en el mismo orden) de una Partida Terminada.

## Truco

**Tantos**: Puntos de un Equipo en Truco.

**Malas / Buenas**: Las dos mitades del tanteador de Truco en una partida a 30: de 0 a 15 son las malas y de 15 a 30 las buenas. Una partida a 15 no se divide.

**Fósforos**: Representación visual clásica de los tantos, en grupos de cinco (cuadrado con diagonal).

## Generala

**Planilla**: Tabla de categorías (1 a 6, Escalera, Full, Póker, Generala, Doble Generala) por Jugador.

**Servido**: Juego logrado en el primer tiro, que suma un bonus.

**Tachar**: Anotar cero en una categoría de la Planilla.

**Generala servida**: Generala lograda en el primer tiro. En la Variante estándar gana la Partida en el acto.

**Doble Generala**: Segunda Generala de un Jugador. Solo cuenta si ya tiene la Generala anotada con puntos (no tachada).

**Turno**: El momento en que le toca tirar a un Jugador. Termina cuando anota una categoría de la Planilla.

## Burako

**Mano**: Una ronda completa de Burako, que produce puntos para cada Participante. Es la Anotación de Burako.

**Canasta limpia**: Juego de siete o más fichas sin comodines.

**Canasta sucia**: Juego de siete o más fichas que incluye algún comodín.

**Fichas en mesa**: Suma del valor de las fichas que un Participante bajó en la Mano.

**Fichas en mano**: Suma del valor de las fichas que un Participante no llegó a bajar. Se resta.

**Cerrar**: Quedarse sin fichas y terminar la Mano. En cada Mano cierra un Participante o ninguno (por ejemplo, si se acaba el pozo).

**Muerto**: Pilón de fichas de reserva que un Participante toma al quedarse sin fichas por primera vez. Tomarlo o no tomarlo suma o resta según la Variante.

**Meta**: Puntaje que, al alcanzarse al final de una Mano, termina la Partida.
