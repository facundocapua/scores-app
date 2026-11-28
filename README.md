# Porotos

Anotador de Truco, Generala y Burako para iPhone. La spec del MVP está en [`docs/SPEC.md`](docs/SPEC.md).

## Desarrollo

El proyecto de Xcode se genera con [XcodeGen](https://github.com/yonaskolb/XcodeGen) a partir de `project.yml` y no se versiona.

```sh
brew install xcodegen
xcodegen generate
open Porotos.xcodeproj
```

Tests:

```sh
xcodebuild test -project Porotos.xcodeproj -scheme Porotos \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Estructura

- `Porotos/Dominio`: lógica pura. Cada Juego implementa `ReglasDeJuego` y se registra en `CatalogoDeJuegos`.
- `Porotos/Persistencia`: el modelo de SwiftData (Partida, Participante, Integrante y Jugador) y Recordar.
- `Porotos/Shell`: el shell iOS nativo y los tokens de `DESIGN.md`.
- `Porotos/Recursos`: assets y las fuentes de display (licencia OFL, junto a cada fuente).
- `PorotosTests`: Swift Testing, con Juegos de prueba para el modelo común.
