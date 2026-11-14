# Glosario

Lenguaje del dominio de la app de anotador de juegos de mesa. Solo términos, no detalles de implementación.

**Juego**: Uno de los juegos de mesa soportados (Generala, Burako, Truco). Define sus reglas y su forma de anotar.

**Partida**: Una sesión concreta de un Juego, con participantes, desde el inicio hasta que hay un ganador o se abandona. Una Partida terminada pasa al Historial.

**Jugador**: Persona guardada en la app y reutilizable entre Partidas.

**Equipo**: Agrupación de Jugadores que suman tantos en conjunto (Truco siempre; Burako cuando se juega en parejas).

**Mano**: Una ronda de juego dentro de una Partida que produce puntos (en Burako, una mano completa; en Truco, cada reparto).

**Variante**: Conjunto de opciones de reglas elegidas al crear una Partida (por ejemplo, Truco a 15 o a 30, con o sin flor). Cada Juego tiene una Variante estándar argentina.

**Historial**: Listado de Partidas terminadas.

## Truco

**Tantos**: Puntos de un Equipo en Truco.

**Malas / Buenas**: Las dos mitades del tanteador de Truco (por ejemplo, en una partida a 30: de 0 a 15 son las malas y de 15 a 30 las buenas).

**Fósforos**: Representación visual clásica de los tantos, en grupos de cinco (cuadrado con diagonal).

## Generala

**Planilla**: Tabla de categorías (1 a 6, Escalera, Full, Póker, Generala, Doble Generala) por Jugador.

**Servido**: Juego logrado en el primer tiro, que suma un bonus.

**Tachar**: Anotar cero en una categoría de la Planilla.

**Generala servida**: Generala lograda en el primer tiro. En la Variante estándar gana la Partida en el acto.

**Doble Generala**: Segunda Generala de un Jugador. Solo cuenta si ya tiene la Generala anotada con puntos (no tachada).

**Turno**: El momento en que le toca tirar a un Jugador. Termina cuando anota una categoría de la Planilla.
