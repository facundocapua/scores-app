# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Stack

SwiftUI + SwiftData, iOS 17+, solo iPhone. Offline, sin backend ni cuentas.

## Users

Grupos de amigos y familias argentinas que juegan Generala, Burako o Truco en la mesa (asados, juntadas, sobremesas, a menudo de noche). Una persona hace de **anotador**: tiene el teléfono en la mano o apoyado en la mesa y anota mientras juega y conversa. El resto mira la pantalla de vez en cuando para ver cómo va la Partida.

## Product Purpose

Reemplazar el papel y la birome (o los porotos y los fósforos) para llevar la cuenta de Generala, Burako y Truco. Tiene éxito cuando el anotador anota cada Mano en segundos, sin errores y sin dejar de prestarle atención a la mesa, y cuando al final de la Partida queda claro quién ganó.

## Positioning

- **Reglas argentinas reales**: la Variante estándar argentina de cada Juego y su vocabulario local (malas y buenas, servido, tachar), no reglas genéricas traducidas.
- **Cero fricción**: abrir y anotar en segundos. Gratis, sin cuentas, sin anuncios, sin compras dentro de la app y sin internet.
- **Recuerda a la barra**: Jugadores guardados y reutilizables, más un Historial de las Partidas con la gente de siempre.

## Operating Context

- Se usa en la mesa, con una mano y entre jugada y jugada, a veces con poca luz.
- Truco: un anotador lleva los tantos de dos Equipos con fósforos (malas y buenas). No se registra cada canto.
- Generala: Planilla clásica con Jugadores en columnas, Servido y Tachar.
- Burako: anotación por Mano, individual o en parejas.
- Glosario del dominio: `GLOSSARY.md`.

## Capabilities and Constraints

- MVP: Partida en curso, Historial simple y Jugadores guardados.
- Toda la app en español, con tono rioplatense y cálido.
- El modelo tiene que permitir agregar más Juegos después.
- Distribución: TestFlight para el MVP y App Store más adelante.
- Fuera de alcance: estadísticas, sincronización con iCloud, iPad, Apple Watch y otros Juegos.
- Las reglas de los tres Juegos, el modelo y las pantallas están cerrados en `docs/SPEC.md`.

## Brand Commitments

- Nombre: **Porotos**. Subtítulo en la App Store: "Anotador de juegos de mesa". Bundle ID: `com.facundocapua.porotos`.
- "Porotos" alude a los porotos que se usan en Argentina para contar los tantos.
- No hay assets visuales previos ni restricciones visuales.

## Evidence on Hand

Ninguna todavía. No hay usuarios, testimonios ni capturas. No hay que inventarlos.

## Product Principles

1. **La mesa primero**: el anotador mira la pantalla un segundo y vuelve a la conversación.
2. **Hablar como en la mesa**: usar los términos que la gente ya dice, no jerga de app.
3. **Nada entre abrir y anotar**: ni cuentas, ni avisos, ni pasos que se puedan evitar.
4. **Cada Juego con su forma**: cada Juego se anota de la forma propia, no con una tabla genérica para todos.

## Accessibility & Inclusion

Se lee a distancia de brazo y con poca luz, y se usa con una mano. WCAG AA, Dynamic Type, VoiceOver completo y mundos de Juego siempre oscuros. El detalle está en `DESIGN.md`.
