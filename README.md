# Porotos

A score keeper for Truco, Generala and Burako on iPhone. The MVP spec lives in [`docs/SPEC.md`](docs/SPEC.md) and the domain language in [`GLOSSARY.md`](GLOSSARY.md).

## Development

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml` and is not checked in.

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

## Conventions

- Code, comments, docs, commits, PRs and issues are written in English, using the English domain terms from `GLOSSARY.md` (Match, Player, Entry…).
- User-facing UI copy is Rioplatense Spanish.

## Layout

- `Porotos/Domain`: pure logic. Each Game implements `GameRules` and registers in `GameCatalog`.
- `Porotos/Persistence`: the SwiftData model (Match, Participant, Seat and Player) and the remembered setup.
- `Porotos/Shell`: the native iOS shell and the tokens from `DESIGN.md`.
- `Porotos/Resources`: assets and the display fonts (OFL license next to each font).
- `PorotosTests`: Swift Testing, with test Games that exercise the shared model.
