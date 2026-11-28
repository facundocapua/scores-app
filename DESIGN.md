# Design

Visual identity of **Porotos**. Decided in the ticket [Visual identity with impeccable](https://github.com/facundocapua/scores-app/issues/3). The reference prototype is on the branch `prototype/identidad-visual` (`prototypes/identidad-visual/index.html`).

## Principle

**A common shell and one world per Game.** The app (Home, History, Players and "Acerca de Porotos", i.e. About Porotos) is native iOS with the brand color. On entering a Match, the scoring screen adopts the Game's own world. The world provides background, palette, display typography and a distinctive gesture. Navigation and controls are always the native iOS ones (navigation bar, sheets, steppers, switches and segmented control).

Adding a new Game means defining its world with these same four elements.

## Shell (Porotos)

- **Brand:** bean red `#8E2A23` as tint, with `#FFF6EE` text on top of it (7.9:1). In dark mode the tint used for text and icons lightens to `#E5857A`, because `#8E2A23` reaches only 2:1 over the dark system backgrounds. As a fill carrying `#FFF6EE` text, the red stays `#8E2A23` in both modes.
- **Background and surfaces:** system semantic colors (`systemGroupedBackground` and `secondarySystemGroupedBackground`). Automatic light and dark mode.
- **Wordmark:** "Porotos" in **Shrikhand**, only in the Home title. Everything else uses SF Pro with Dynamic Type.
- **Home = game picker:** at the top, one row per In progress Match with the "Seguir" (Continue) button (up to 3, plus "Ver todas", See all); below, "Nueva partida" (New match) with one large card per Game that previews its world (matchsticks, dice on felt and tiles). The full flow is in `docs/SPEC.md`.
- **Tab bar:** Jugar · Historial · Jugadores (Play · History · Players).

## Truco: matchsticks

- **Background:** night table, from `#221A15` to `#17120F`. Always dark.
- **Matchsticks:** stick `#E8CF9C` with border `#B99560` and head `#C23B22`. Each group of five forms a square (left, top, right, bottom) plus the diagonal.
- **Layout:** two columns (Nosotros | Ellos, i.e. Us | Them). Each shows the name, the number of points, the matchsticks of the malas, a dotted line and those of the buenas.
- **Hierarchy:** the Team that is ahead looks larger and in amber `#F2B33D`; the other one, smaller and muted `#A8998A`.
- **Display:** **Bevan** for names, numbers and the +1 button.
- **Interaction:** tapping the column or the +1 adds a point. The − is on the side. Undo goes in the navigation bar. "Terminar partida" (End match) is isolated at the bottom, in `#E8826F`.
- **End:** on reaching the maximum, the screen inverts (light background `#F3E9D8`, dark text) with "¡Ganaron …!" (They won!) and the Rematch button.

## Generala: casino felt

- **Background:** green felt with overhead light, from `#127049` to `#0D5A3B` and `#083D28`.
- **Accents:** brass `#D8B45A` for the title, the Scoresheet frame, the totals and the Player who is rolling. Text `#F4F0E2`, secondary text `#D2E6DA` (the prototype's `#A9C7B5` gave 3.4:1 under the overhead light, `#127049`; this one gives 4.7:1). Brass is used only on large text and borders, never on small text.
- **Scoresheet:** categories go in rows (ones to sixes with die faces, Straight, Full house, Four of a kind, Generala, Double Generala and Total) and Players in columns. A line separates the numbers section from the combinations section.
- **Turn:** the column of the Player who is rolling is highlighted with a brass veil and the label "Tira" (Rolls).
- **Cells:** empty, with a faint dot; Served with a brass superscript "S"; Scratched as an "✕" in the text color `#F4F0E2` (it does not depend on color alone).
- **Display:** **Abril Fatface** for the title and the totals. The numbers in the cells use tabular SF Rounded.
- **Interaction:** tapping a cell opens a native sheet with the possible values, the served option and "Tachar" (Scratch). On scoring, the Turn passes to the next Player. "Terminar partida" is in the "⋯" menu.

## Burako: tiles on the table

- **Background:** petrol-green table, from `#123B40` to `#0C2C30`. Text `#EAF2F0`, secondary `#9DB9B6` and action `#F2C14E`.
- **Tiles:** ivory `#F7F2E6` with edge `#D9CFB8`. The numbers come in the four tile colors: red `#C62828`, blue `#1E5BB8`, black `#1F1F1F` and amber `#946409` (the prototype's yellow `#D9930D` darkened without changing the hue until it passes 4.5:1 on the ivory: it gives 4.6:1). Total scores are written with tiles, one digit per tile, alternating colors.
- **Display:** **Alfa Slab One** for tiles and titles.
- **Match screen (race):** one rack per Participant (Player or Team) with the total in tiles and a progress bar toward the Target score ("faltan N", N to go). Below, the Hands played as chips. Main button: "Anotar mano N" (Score hand N). "Terminar partida" is in the "⋯" menu.
- **Score hand (calculator):** a screen with each Participant's total in miniature and a segmented control with their names. It includes steppers for clean and dirty canastas, numeric fields for the Tiles melded and Tiles in hand, and switches for "Cerró" (Went out) and "Tomó el muerto" (Took the Muerto). It shows the result of the Hand in tiles and what the Participant's total would become. The values are in `docs/SPEC.md`.

## Icon

**Handful of beans:** four loose beans (two red `#8E2A23`, one black `#2B211C` and one golden `#C9A15A`) on a light background `#F6EBDD`.

## Common rules

- Touch targets of at least 44 pt. The +1 and the main action take the full width of the thumb at the bottom of the screen.
- Destructive actions ("Terminar partida") are kept apart from the scoring ones.
- The display fonts (Shrikhand, Bevan, Abril Fatface and Alfa Slab One) are bundled in the app and used only in display moments. All UI text uses SF with Dynamic Type.
- The prototype's score values are not the reference: each Game's rules are in `docs/SPEC.md`.

## Accessibility and use at the table

Decided in [Accessibility and use at the table](https://github.com/facundocapua/scores-app/issues/11).

- **Contrast:** WCAG AA. 4.5:1 for small text and 3:1 for large text and graphics. No dedicated variant for Increase Contrast.
- **Light mode:** the shell follows the system mode. Game worlds are always dark (the Truco end screen inverts anyway).
- **Dynamic Type:** the shell and the text screens scale without limit. The display numbers of the worlds (the Truco total, the Burako tiles) do not scale. The Generala Scoresheet scales up to xxxLarge; from AX1, the category column stays fixed and the Player columns scroll horizontally.
- **VoiceOver:** full support. The matchsticks are read as "Nosotros, 17, buenas 2" (Us, 17, buenas 2) and are adjustable (swiping up or down adds or subtracts a point). Cells are read as "Ana, Full, 30, servido" (Ana, Full house, 30, served). Totals in tiles are read as a number ("1.240, faltan 1.760", 1,240, 1,760 to go).
- **Screen on:** automatic while a Match is open in the foreground, with no option. In the shell, the History and the end screen, normal behavior returns.
- **Orientation:** portrait only.
- **One hand:** frequent actions go in the bottom two thirds. Undo stays in the navigation bar. No hidden gestures (no shake to undo).
- **Haptics:** a light tap for each point or cell scored, a success one on finishing and a warning one on undoing. They respect the system setting, with no switch of their own.
- **Reduce Motion:** animations (the matchstick, the tiles, the end inversion) become short fades.
