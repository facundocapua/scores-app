# Matches store Entries and the score is computed

A Match stores the ordered list of its Entries (each Truco point, each Generala Scoresheet cell, each Burako Hand) and never stores totals: the scores, the end and the Winners are computed from that list. This way, Undo works the same in all three Games (the last change to the Entries is reverted), the History can rebuild any Match, and a new Game only has to define its Entry type and how it is computed.

## Considered Options

- **Store only the totals per Participant:** simpler, but it allows neither undoing nor rebuilding a Match, and each Game would need its own correction mechanism.
- **Store the totals plus a separate change log:** duplicates the truth and can get out of sync.

## Consequences

Generala Entries (cells) and Burako Entries (Hands) can be edited in place. For that reason Undo reverts the last **change** (adding or editing an Entry), and the Match stores, besides its Entries, the history of those changes with the previous value of each edit. That history is used only for Undo: scores are still computed from the current Entries.

Subtracting in Truco is an Entry of −1, not a deletion: it stays in the Match's history. Computations must be fast over short lists (a Match has at most a few hundred Entries), so there is no need to cache totals.
