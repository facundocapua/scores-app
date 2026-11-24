# Las Partidas guardan Anotaciones y el puntaje se calcula

Una Partida guarda la lista ordenada de sus Anotaciones (cada tanto de Truco, cada celda de la Planilla de Generala, cada Mano de Burako) y nunca guarda totales: los puntajes, el fin y los Ganadores se calculan a partir de esa lista. Así, Deshacer funciona igual en los tres Juegos (se saca la última Anotación), el Historial puede reconstruir cualquier Partida y un Juego nuevo solo tiene que definir su tipo de Anotación y cómo se calcula.

## Considered Options

- **Guardar solo los totales por Participante:** más simple, pero no permite deshacer ni reconstruir una Partida, y cada Juego necesitaría su propio mecanismo de corrección.
- **Guardar los totales más un registro de cambios aparte:** duplica la verdad y puede desincronizarse.

## Consequences

Restar en Truco es una Anotación de −1, no un borrado: queda en la historia de la Partida. Los cálculos tienen que ser rápidos sobre listas cortas (una Partida tiene a lo sumo unos cientos de Anotaciones), así que no hace falta guardar totales en caché.
