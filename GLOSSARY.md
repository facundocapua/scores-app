# Glossary

Domain language of the board-game scorekeeper app. Terms only, no implementation details. The Spanish word shown as "UI" is what appears in the app.

**Game** (UI: *Juego*): One of the supported board games (Generala, Burako, Truco). It defines its rules and its way of scoring.

**Match** (UI: *Partida*): A concrete session of a Game, with its Participants and its Variant, from the start until there are Winners. It is In progress or Finished; a Match that nobody wants to finish is discarded, that is, deleted. Several Matches can be In progress at the same time.

**Ended early** (UI: *Terminada antes*): A Finished Match that was ended on request before reaching the end set by the rules of its Game. The Participants who were ahead at that moment win.

**Participant** (UI: *Participante*): Whoever scores points and can win a Match. Has a name and zero or more Players. Depending on the Game, it is a Player or a Team.

**Entry** (UI: *Anotación*): Each action of scoring points in a Match (for example, a point in Truco, a Scoresheet cell in Generala or a Hand in Burako). The scores of a Match are computed from its Entries.

**Winners** (UI: *Ganadores*): The Participants who win a Finished Match. Usually one, but there can be a shared tie (in Generala, or in a Match that Ended early). Players win through their Participant.

**Player** (UI: *Jugador*): A person saved in the app and reusable across Matches. Has only a name, which is unique. There are no guests: a new name typed when creating a Match is saved as a Player. If deleted, the History keeps the name the Player played under. Appears at most once per Match.

**Team** (UI: *Equipo*): A Participant that groups Players under its own name (always in Truco; in Burako when played in pairs, with exactly two Players). It exists only within its Match.

**Variant** (UI: *Variante*): A set of rule options chosen when creating a Match (for example, Truco to 15 or to 30). Each Game has a standard Argentine Variant. A new Match proposes the Variant and the Participants of the last Match of that Game.

**History** (UI: *Historial*): The list of Finished Matches.

**Rematch** (UI: *Revancha*): A new Match that repeats the Game, the Variant and the Participants (in the same order) of a Finished Match.

## Truco

**Points** (UI: *Tantos*): A Team's points in Truco.

**Malas / buenas** (UI: *Malas / Buenas*): The two halves of the Truco scoreboard in a match to 30: from 0 to 15 are the malas (first half) and from 15 to 30 the buenas (second half). A match to 15 is not divided.

**Matchsticks** (UI: *Fósforos*): The classic visual representation of the points, in groups of five (a square with a diagonal).

## Generala

**Scoresheet** (UI: *Planilla*): Table of categories (ones to sixes, Straight, Full house, Four of a kind, Generala, Double Generala) per Player.

**Served** (UI: *Servido*): A combination made on the first roll, which adds a bonus.

**Scratch** (UI: *Tachar*): To score zero in a Scoresheet category. A category scored this way is Scratched (UI: *Tachado*).

**Served Generala** (UI: *Generala servida*): A Generala made on the first roll. In the standard Variant it wins the Match on the spot.

**Double Generala** (UI: *Doble Generala*): A Player's second Generala. It only counts if the Player already has the Generala scored with points (not Scratched).

**Turn** (UI: *Turno*): The moment when a Player is up to roll. It ends when the Player scores a Scoresheet category.

## Burako

**Hand** (UI: *Mano*): One complete round of Burako, which produces points for each Participant. It is the Burako Entry.

**Clean canasta** (UI: *Canasta limpia*): A meld of seven or more tiles without jokers.

**Dirty canasta** (UI: *Canasta sucia*): A meld of seven or more tiles that includes at least one joker.

**Tiles melded** (UI: *Fichas en mesa*): Sum of the value of the tiles a Participant laid down in the Hand.

**Tiles in hand** (UI: *Fichas en mano*): Sum of the value of the tiles a Participant did not manage to lay down. It is subtracted.

**Go out** (UI: *Cerrar*; "Went out" is *Cerró*): To run out of tiles and end the Hand. In each Hand one Participant goes out, or none (for example, if the stock runs out).

**Muerto** (UI: *Muerto*): The reserve pile of tiles that a Participant takes on running out of tiles for the first time. Taking it or not taking it adds or subtracts points depending on the Variant.

**Target score** (UI: *Meta*): The score that, when reached at the end of a Hand, ends the Match.
