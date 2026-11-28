# MVP Spec: Porotos

Spanish-language iOS app for scoring **Truco**, **Generala** and **Burako** matches at the table. This spec gathers all the decisions from the map [Map: iOS board-game scorekeeper app](https://github.com/facundocapua/scores-app/issues/1) and is enough to start building. If anything here contradicts another document, this spec wins.

**Documents that accompany this spec:**

- [`GLOSSARY.md`](../GLOSSARY.md): the domain language. The capitalized terms (Match, Participant, Entry…) are the glossary's, and the code uses them as they are.
- [`DESIGN.md`](../DESIGN.md): the visual identity, with the tokens, the typefaces and each Game's world.
- [`PRODUCT.md`](../PRODUCT.md): the users, the purpose and the principles.
- [ADR 0001](adr/0001-entries-and-computed-scores.md): Matches store Entries and the score is computed.
- Visual prototype (reference, not merged): branch `prototype/identidad-visual`, `prototypes/identidad-visual/index.html`.

UI copy is Spanish and is quoted verbatim; an English gloss in parentheses is added the first time where it helps.

---

## 1. Product and scope

**Porotos** replaces pen and paper for keeping score. It is used by a **scorekeeper**: someone at the table who holds the phone, scores between plays, often in low light, and goes back to the conversation.

**In the MVP:**

- Truco, Generala and Burako Matches, with the standard Argentine Variant of each and few options.
- Several Matches In progress at the same time.
- History of Finished Matches.
- Saved, reusable Players.

**Out of the MVP:**

- Statistics (who wins most, streaks).
- iCloud or cross-device sync.
- iPad, Apple Watch and other platforms.
- Other Games (the model must allow adding them; see [§3.6](#36-adding-a-game)).
- Series of several Matches (for example, Truco best of 3).
- Automatic counting of Burako tiles from a photo.
- App settings or preferences.
- A dedicated variant for Increase Contrast.

## 2. Platform and constraints

- **Stack:** SwiftUI and SwiftData, **iOS 17+**, iPhone only, **portrait only**.
- **Offline:** no backend, no accounts, no network. No third-party SDKs or analytics.
- **Price:** free, no ads and no in-app purchases.
- **Language:** the whole app in Rioplatense Spanish (voseo, warm tone). There are no other localizations.
- **Name:** Porotos. Bundle ID: `com.facundocapua.porotos`.
- **Distribution:** the MVP is distributed through TestFlight, and published on the App Store later (see [§9](#9-publishing)).
- **Persistence:** every change is saved instantly in SwiftData. Closing the app, or iOS killing it, never loses a Match.

## 3. Domain model

The definitions are in `GLOSSARY.md`. This section fixes how the concepts relate.

### 3.1 Match

Common to all Games, it has:

- **Game** and **Variant** (the Game's own options).
- **Participants** in order.
- **Entries** in order, plus the change history used by Undo (see [§3.4](#34-entries-and-scoring)).
- **Status:** In progress or Finished. There are no other statuses: a Match that nobody wants to finish is discarded, that is, deleted.
- The **Ended early** mark, if it was ended on request before the end set by the rules.
- **Start date**, **end date** and **date of the last Entry** (to sort Home).
- **Winners** (one or more). They are computed, not stored.
- For Burako, the **draft** of the Hand that is half entered, if any.

There can be several Matches In progress, even of the same Game. The History shows only the Finished ones.

### 3.2 Participant

Whoever scores points and can win. Has a **name** and **zero or more Players**.

| Game | Participants |
|---|---|
| Truco | Always 2 Teams. Players are optional and assigned freely (any number per Team, even uneven or all in one). |
| Generala | 2 to 6 Players, one per Participant. No Teams. |
| Individual Burako | 2 to 4 Players, one per Participant. |
| Burako in pairs | 2 Teams of exactly 2 Players each. |

### 3.3 Player and Team

- **Player:** has only a **name**, which is unique. It is compared ignoring case, accents and surrounding spaces, and is up to **20 characters**. There are no guests: a new name typed when creating a Match is saved as a Player. Appears at most once per Match.
- **Team:** a Participant that lives only within its Match and is not reused.
  - Its name is up to **30 characters** and is never empty: if cleared, it goes back to the default name.
  - The two Teams of a Match can have the same name.
  - **Default name:**
    - **Truco:** "Nosotros" and "Ellos" (Us and Them).
    - **Burako:** built from the Players' names ("Facu y Caro") and editable. If the pair changes, it goes back to the automatic one.
- **Renaming a Player** changes the name everywhere, including in the History.
- **Deleting a Player** is allowed even if they have Matches, including one In progress. Matches keep the last name the Player had, so on deletion their name is copied to each Match they played in.

### 3.4 Entries and scoring

Details in [ADR 0001](adr/0001-entries-and-computed-scores.md).

- **Entry per Game:**
  - **Truco:** a point of +1 or −1 for a Team.
  - **Generala:** a Scoresheet cell (Player, category, value or Scratched, and whether it was served).
  - **Burako:** a Hand, with the calculator fields for each Participant.
- **Scores, the end of the Match and the Winners are always computed** from the Entries. Totals are never stored.
- **Undo** reverts **the last change**, with no limit while the Match is In progress:
  - if an Entry was added, it removes it;
  - if one was edited (a Generala cell or a Burako Hand), it restores the previous value.

  The change history is stored with the Match, so Undo works the same after reopening the app.

### 3.5 Remembering the last setup

When creating a Match, each Game preloads the Variant and the Participants of **its last Match that still exists**, whether In progress or Finished. If a Player from that Match was deleted, their spot is left empty. The first time, each Game's standard values are used (see [§5.2](#52-new-match-screen)).

### 3.6 Adding a Game

A new Game defines:

- its Variant options and their standard values;
- its Participant rules (number, whether they play in Teams, minimum to start);
- its Entry type and how scores are computed;
- its end and Winners rule;
- its Match screen, with its own world (background, palette, display typography and a distinctive gesture; see `DESIGN.md`).

The rest (Home, History, Players, Undo, ending and discarding) is common and does not change.

## 4. Rules per Game

The app is a **scorekeeper, not a referee**: it enforces only the rules named here.

### 4.1 Truco

- **Variant:** only the score, **to 15 or to 30** (default **30**). There is no option for flor or for format (1 vs 1, 2 vs 2, 3 vs 3). Envido, flor and the other calls are points that the scorekeeper adds by hand. Each call is not recorded and there are no Hands.
- **Scoring:** +1 or −1 point per Team. The −1 is disabled when the Team has 0.
- **Malas and buenas:**
  - **To 30:** from 0 to 15 are the malas (first half) and from 15 to 30 the buenas (second half).
  - **To 15:** not divided (a single block of three groups of matchsticks).
  - The big number shows the **running total** (for example, 18), not "3 buenas". The division is visible only in the matchsticks and in the dotted line.
- **End:** when a Team reaches the score, it wins and the Match ends by itself. The score cannot be exceeded.
- **Ties:** there are none, except in a Match that Ended early.

### 4.2 Generala

- **Variant:** a single option, **"Generala servida gana"** (Served Generala wins), on by default.
- **Players:** 2 to 6, one per column, in Turn order.
- **Scoresheet:** 11 categories per Player.

| Category | Values | Served |
|---|---|---|
| Ones to sixes | Sum of the dice of that face: from 1 to 5 times the face. No section bonus. | Does not apply |
| Straight | 20 | 25 |
| Full house | 30 | 35 |
| Four of a kind | 40 | 45 |
| Generala | 50 | Wins the Match (option on) or is worth 55 (option off) |
| Double Generala | 100 | 100 |

- **Scratch** scores 0 in any category.
- **Served Generala (option on):** the Player wins on the spot and the Match ends.
- **Double Generala:** is scored with points only if the Player already has the Generala with points (50, or 55 served with the option off). If the Generala is empty or Scratched, the Double can only be Scratched.
  - The app also enforces this when correcting: if a Player has the Double with points, their Generala cannot be Scratched or cleared. The app rejects it with a notice, and the Double must be Scratched or cleared first.
- **Turns:** the Turn passes by itself to the next Player who has free categories, in the Match's order, when the one rolling scores. It is also possible to score in another Player's column: the Turn is a guide, not a lock.
- **End:** when everyone has filled their 11 categories (with points or Scratched), or on a Served Generala if the option is on.
- **Winners:** the highest total. If there is a tie for first place, it is a shared tie, with no tiebreaker.

### 4.3 Burako

- **Mode:** individual with 2 to 4 Players, or 2 pairs (2 vs 2). It is not played with 3 pairs. Scoring is per Participant.
- **Variant:**
  - **Target score:** 3000 by default, with shortcuts of 2000, 2500 and 3000, or a free value.
  - **Muerto:** three options.

    | Option | Taking it | Not taking it |
    |---|---|---|
    | **Suma y resta** (adds and subtracts; default) | +100 | −100 |
    | **Solo resta** (subtracts only) | 0 | −100 |
    | **Solo suma** (adds only) | +100 | 0 |

  - The other values are fixed.
- **Calculator per Hand**, for each Participant:

  | Field | Control | Value |
  |---|---|---|
  | Clean canastas | stepper | × 200 |
  | Dirty canastas | stepper | × 100 |
  | Tiles melded | number added up by hand | adds |
  | Tiles in hand | number added up by hand | subtracts |
  | Cerró (Went out) | switch | +100. At most one Participant per Hand marks it, or none |
  | Tomó el muerto (Took the Muerto) | switch | according to the Variant's Muerto option |

  - In pairs, a single Tiles melded number and a single Tiles in hand number are entered per Team (the sum of the two partners).
  - Next to the tile fields the values are shown as a help: joker 50, 2 = 20, 1 = 15, 8 to 13 = 10 and 3 to 7 = 5. The app does not count tile by tile.
  - **Hand result:** clean × 200 + dirty × 100 + Tiles melded − Tiles in hand + Went out + Muerto.
  - **No rule validation:** for example, it lets you mark Went out without canastas. Negative totals are allowed.
- **End:** when a Hand ends in which some Participant reached the Target score or went past it, the highest total wins. If there is a tie at the top, the Match continues and another Hand is played to break the tie.

### 4.4 Ended early

In any Game, "Terminar con este resultado" (End with this result; see [§6.3](#63-ending-discarding-and-deleting)) ends the Match on the spot. Those in the lead win, with shared Winners if there is a tie, and the Match is marked as **Ended early**.

## 5. Screens and navigation

Structure: native iOS shell with the tab bar **Jugar · Historial · Jugadores** (Play · History · Players). The Match screen goes full screen, with its Game's world.

### 5.1 Home (Jugar tab)

- Opening the app always lands on Home. If iOS kept it in memory, it returns to where it was.
- **With no Matches In progress:** the "Porotos" wordmark and the three Game cards ("Nueva partida", New match). There is no onboarding.
- **With Matches In progress:**
  - At the top, one row per Match (Game, Participants, score and "Seguir", Continue), the last one scored first.
  - Up to 3 are shown. "Ver todas" (See all) opens the full list.
  - In the rows and in "Ver todas", **swipe to delete**, with confirmation. It is the same as Discard.
  - Below, the Game cards.
- An icon opens **"Acerca de Porotos"** (About Porotos), with the privacy policy, the contact (email) and the version. There are no preferences.

### 5.2 New Match screen

- A single screen per Game, in a full-screen sheet:
  - the Participants at the top;
  - the Variant always visible, below;
  - "Empezar" (Start) fixed at the bottom, disabled until the Game's minimum is met.
- It **preloads** the last setup of that Game (see [§3.5](#35-remembering-the-last-setup)): repeating a Match takes two taps. If there is already a Match In progress of that Game, it creates another one without warning.
- **First time for each Game:**
  - **Truco:** "Nosotros" against "Ellos", to 30.
  - **Generala:** empty list, with "Generala servida gana" on.
  - **Burako:** Pairs ("Parejas") with empty spots, Target score 3000 and Muerto "Suma y resta".
- **Variant controls:**
  - **Truco:** segmented 15 / 30.
  - **Generala:** a switch.
  - **Burako:** Target score (2000 / 2500 / 3000 / "Otra", Other) and Muerto (three options).
- **Player picker:**
  - It has a search field and shows first those who played most recently.
  - If a new name is typed, "Agregar «Nombre»" (Add "Name") appears, which creates the Player and picks them. If the name already exists (with the comparison from [§3.3](#33-player-and-team)), the existing one is offered.
  - Those already in the Match disappear from the picker. To move someone to another Team, first remove them from their current one.
- **Generala and individual Burako:** the order is dragged. In Generala it is the Turn order. There is no draw.
- **Burako:**
  - A segmented control picks **"Individual"** or **"Parejas"** (Pairs). In Pairs there are two blocks of two spots, and Players are swapped by dragging.
  - When switching modes, the chosen Players are kept: pairs are formed as 1 and 2 against 3 and 4.
- **Truco:** the two Team names and "Agregar Jugadores" (Add Players) as a secondary action.
- **Minimums to Start:**
  - **Truco:** always possible.
  - **Generala:** 2 Players.
  - **Burako:** 2 Players in individual, or all 4 spots filled in Pairs.

### 5.3 Match screen

- Full screen, with no tab bar, in the Game's world (see `DESIGN.md`).
- **Navigation:**
  - **"Inicio"** (Home) at the top left leaves without confirmation, and the Match stays In progress.
  - **At the top right:** Undo and a "⋯" menu.
  - **The "⋯" menu** has the details (Variant and Participants), the editing of the Variant and of Team names (see [§6.4](#64-mid-match-changes)) and, in Generala and Burako, "Terminar partida" (End match).
  - **Truco:** "Terminar partida" is isolated at the bottom.
- **Truco:** tapping a Team's column or its +1 button adds a point. The − is on the side.
- **Generala:** tapping a cell opens a native sheet with the category's possible values, the served option (if it applies) and "Tachar" (Scratch). An already scored cell opens the same sheet, to change the value, Scratch it or clear it.
- **Burako:**
  - The screen shows the race toward the Target score: one rack per Participant with the total in tiles and "faltan N" (N to go), and below the Hands played as chips.
  - The main button "Anotar mano N" (Score hand N) opens the calculator, with a segmented control per Participant.
  - Tapping a Hand's chip opens it in the calculator to correct it.
- **Screen on** while the Match is open in the foreground.

### 5.4 End of Match

- It is the same in the three Games, in each one's world. It shows:
  - the Winners (with "Empate", Tie, if there are several);
  - everyone's final scores, with positions if there are more than two Participants;
  - the buttons **"Revancha"** (Rematch; primary) and **"Inicio"** (Home).
- In Truco, the screen inverts with "¡Ganaron …!" (They won!).
- The Scoresheet or the Hands can be viewed (read-only). **Undo** stays visible and reopens the Match (see [§6.2](#62-undoing-the-ending)).
- **Rematch** starts directly with the same Participants, order and Variant.
  - If a deleted Player is missing and the rest meet the Game's minimum, it starts without them.
  - If they do not (or if in Burako in Pairs a pair is left incomplete), it opens the New Match screen with the rest loaded.

### 5.5 History

- **List:**
  - Only Finished Matches, grouped by month, newest first.
  - Each row shows the Game, the Winners highlighted, the scores and the date. The labels "Empate" and "Terminada antes" (Ended early) appear when they apply.
  - Filter by Game, no search.
  - Swipe to delete, with confirmation and no trash.
- **Detail:**
  - It is read-only, with the date, the duration (from the start date to the end date), the Variant, the Participants with their Players and the full result in the Game's world.
  - In a tie, shared positions show the "1.º" (1st) repeated.
  - It has **"Jugar de nuevo"** (Play again; works as a Rematch) and Delete.
- **Empty:** "Todavía no terminaron ninguna partida" (No match has been finished yet), with the button "Empezar una" (Start one).

### 5.6 Players

- Alphabetical list with "+".
- Tapping a Player opens a sheet to **rename** or **delete** them (with confirmation).
  - When renaming to a name that already exists, an inline notice prevents saving.
  - If the Player is in a Match In progress, the deletion confirmation says "Está jugando una partida en curso" (Is playing a match in progress).
- There is no Player profile and there are no counters.
- **Empty:** "Acá va a estar la barra" (The crew will be here), with the button "Agregar jugador" (Add player).

## 6. Edge cases

### 6.1 Correcting

- **Undo:** reverts the last change, with no limit while the Match is In progress (see [§3.4](#34-entries-and-scoring)).
- **Generala:** edited in place (see [§5.3](#53-match-screen)), with the Double Generala rule of [§4.2](#42-generala).
- **Burako:** a Hand is corrected in the calculator. If the correction makes someone reach the Target score in a Hand earlier than the last, the app rejects it with a notice, so that no Hands are left after the end.
- **Truco:** not edited. It is corrected with Undo or with −1.

### 6.2 Undoing the ending

- A Finished Match is reopened only with Undo from the end screen.
- In a Match that **Ended early**, that Undo reverts only the ending: the Match goes back In progress with the same score, without touching its Entries. A second Undo, already in the Match, reverts the last Entry.
- On leaving there, through Rematch, through Home, or because the app was closed, the ending becomes final.
- The History detail is always read-only.

### 6.3 Ending, discarding and deleting

- **"Terminar partida"** (End match) offers two options:
  - **"Terminar con este resultado":** the Match is Ended early (see [§4.4](#44-ended-early)).
  - **"Descartar partida"** (Discard match): with confirmation, the Match is deleted.
- **Deleting:** by swipe and confirmation, with no trash. It applies to Finished Matches (in the list and in the History detail) and to those In progress (in the Home rows and in "Ver todas").

### 6.4 Mid-Match changes

- **Variant:** it can be changed from "⋯" while the Match is In progress. Options that would end it on the spot are disabled:
  - Truco to 15 when some Team has 15 or more;
  - a Target score equal to or lower than some Burako total;
  - turning on "Generala servida gana" if a Served Generala has already happened.
- **Team names:** edited from "⋯", with the rules of [§3.3](#33-player-and-team).
- **Participants:** fixed once the Match has started, including the Generala Turn order.
- **Players:** can be renamed or deleted at any time (see [§3.3](#33-player-and-team) and [§5.6](#56-players)).

### 6.5 Closing the app

- Every change is saved instantly.
- The half-entered Burako Hand is saved as its Match's draft and restored on return, even if iOS killed the app.
- An unconfirmed Generala value in the sheet is lost.

## 7. Visual identity

All the detail is in [`DESIGN.md`](../DESIGN.md). In summary:

- **Shell:** native iOS with system semantic colors, bean-red tint `#8E2A23` and the wordmark in Shrikhand. It follows the system's light or dark mode.
- **Game worlds, always dark:**
  - **Truco:** matchsticks on a night table, with Bevan.
  - **Generala:** casino felt with brass, with Abril Fatface.
  - **Burako:** ivory tiles on a petrol-green table, with Alfa Slab One.
- The display fonts are bundled in the app and used only in display moments. The rest of the text uses SF with Dynamic Type.
- **Icon:** "Handful of beans" (*Puñado de porotos*).

## 8. Accessibility and use at the table

Details in the "Accessibility and use at the table" section of `DESIGN.md`.

- **Contrast:** WCAG AA. The Generala Scratch mark is an "✕" in the text color. The Burako yellow tile is `#946409`. Brass is used only on large text and borders.
- **Dynamic Type:**
  - The shell and the text screens scale without limit.
  - The display numbers of the worlds do not scale.
  - The Generala Scoresheet scales up to xxxLarge. From AX1, the category column stays fixed and the Player columns scroll horizontally.
- **VoiceOver:** full support.
  - The matchsticks are read as "Nosotros, 17, buenas 2" (Us, 17, buenas 2) and are adjustable: swiping up or down adds or subtracts a point.
  - Cells are read as "Ana, Full, 30, servido" (Ana, Full house, 30, served).
  - Totals in tiles are read as a number ("1.240, faltan 1.760", 1,240, 1,760 to go).
  - The calculator uses native controls with labels.
- **One hand:** frequent actions go in the bottom two thirds, with targets of at least 44 pt. There are no hidden gestures.
- **Haptics:**
  - a light tap for each point or cell scored;
  - a success one on finishing the Match;
  - a warning one on undoing.

  They respect the system setting.
- **Reduce Motion:** animations become short fades.

## 9. Publishing

Source: [App Store requirements for a free, offline app](https://github.com/facundocapua/scores-app/issues/7).

**Before building:**

1. **Renew the Apple Developer Program membership** (99 USD per year). It expired on 2026-08-22, and the renewal is pending with Apple support. It is needed even for TestFlight.
2. **Create the App Store Connect record** to reserve the name:
   - name **Porotos**;
   - subtitle **"Anotador de juegos de mesa"**;
   - bundle ID `com.facundocapua.porotos`;
   - primary language Spanish (Mexico), because App Store Connect has no Rioplatense variant.

**Build and listing requirements:**

- **Privacy label:** "Data Not Collected". For it to stay valid, no third-party SDKs or analytics are added.
- **Privacy policy and support:**
  - Two static pages on the repo's **GitHub Pages**: the privacy policy (the app collects no data) and support, with a contact email defined at build time.
  - Both URLs are entered in App Store Connect.
  - "Acerca de Porotos" links both pages and shows the email (guideline 5.1.1).
- **Icon:** 1024 × 1024, no alpha channel.
- **Screenshots:** needed when publishing on the App Store, not for TestFlight. 1 to 10 iPhone screenshots at 1290 × 2796, which cover the two required sizes.
- **TestFlight:** up to 100 internal testers without review, and external ones with a Beta App Review of the first build. Builds last 90 days.
- **Rating:** 4+ expected. A scorekeeper is not gambling. Avoid mentioning betting with money.
- **Countries:** availability per country is chosen when publishing on the App Store, after the MVP.

## 10. MVP acceptance criteria

- [ ] A Match of each Game is created, played and finished, and appears in the History with the correct Winners.
- [ ] Repeating a Game's last Match takes two taps from Home.
- [ ] Truco to 15 and to 30: the matchsticks group in fives, the malas and buenas are visible at 30, and the Match ends by itself on reaching the score.
- [ ] Generala: meets the points table, Served, Served Generala (with the option on and off), the Double rule (also when correcting), the Turns and the shared tie.
- [ ] Burako: the calculator gives the result of [§4.3](#43-burako) with the three Muerto options, in individual and in pairs, and breaks ties with another Hand.
- [ ] Undo reverts additions and edits in order, also after reopening the app, and reopens a Match from the end screen.
- [ ] Killing the app in the middle of a Match, or of a Burako Hand, loses nothing.
- [ ] Deleting a Player keeps their name in the History and in the Matches In progress.
- [ ] Passes a VoiceOver and Dynamic Type review (up to AX5) on the three Match screens.
- [ ] The build makes no network request.
