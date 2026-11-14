# Glosario

Lenguaje del dominio de la app de anotador de juegos de mesa. Solo términos, no detalles de implementación.

**Juego**: Uno de los juegos de mesa soportados (Generala, Burako, Truco). Define sus reglas y su forma de anotar.

**Partida**: Una sesión concreta de un Juego, con participantes, desde el inicio hasta que hay un ganador o se abandona. Una Partida terminada pasa al Historial.

**Jugador**: Persona guardada en la app y reutilizable entre Partidas.

**Equipo**: Agrupación de Jugadores que suman tantos en conjunto (Truco siempre; Burako cuando se juega en parejas).

**Mano**: Una ronda de juego dentro de una Partida que produce puntos (por ejemplo, en Burako, una mano completa). En Truco no se registran Manos, solo Tantos.

**Variante**: Conjunto de opciones de reglas elegidas al crear una Partida (por ejemplo, Truco a 15 o a 30). Cada Juego tiene una Variante estándar argentina.

**Historial**: Listado de Partidas terminadas.

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

**Participante**: Quien suma puntos en una Partida de Burako: un Jugador si se juega individual, o un Equipo si se juega en parejas.

**Canasta limpia**: Juego de siete o más fichas sin comodines.

**Canasta sucia**: Juego de siete o más fichas que incluye algún comodín.

**Fichas en mesa**: Suma del valor de las fichas que un Participante bajó en la Mano.

**Fichas en mano**: Suma del valor de las fichas que un Participante no llegó a bajar. Se resta.

**Cerrar**: Quedarse sin fichas y terminar la Mano. En cada Mano cierra un Participante o ninguno (por ejemplo, si se acaba el pozo).

**Muerto**: Pilón de fichas de reserva que un Participante toma al quedarse sin fichas por primera vez. Tomarlo o no tomarlo suma o resta según la Variante.

**Meta**: Puntaje que, al alcanzarse al final de una Mano, termina la Partida.
