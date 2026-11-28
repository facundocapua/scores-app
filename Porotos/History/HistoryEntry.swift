import Foundation

/// A Finished Match read once, as plain values, for the History screens. It works for every
/// Game: the shared parts come from the Match and its Outcome, and each Game adds its own
/// `detail` for the result in its world.
struct HistoryEntry: Identifiable {
    struct Participant: Identifiable {
        var id: Int { index }
        var index: Int
        var name: String
        /// The Players' names, with the last name of any that was deleted. Empty for a
        /// Participant with no Players (Truco).
        var players: [String]
        var isTeam: Bool
        var score: Int
        var position: Int
        var isWinner: Bool
    }

    /// What is specific to each Game.
    enum Detail {
        case truco(Truco.Variant)
        case generala(Generala.Variant, entries: [Generala.Entry])
        case burako(Burako.Variant, handCount: Int)
    }

    var id: UUID
    var kind: GameKind
    var startedAt: Date
    var finishedAt: Date
    var endedEarly: Bool
    /// In the order they played.
    var participants: [Participant]
    var detail: Detail

    var winners: [Participant] { participants.filter(\.isWinner) }

    /// Several Winners share the victory (SPEC §5.4).
    var isTie: Bool { winners.count > 1 }

    /// Best position first; ties keep the order they played.
    var ranking: [Participant] {
        participants.sorted { ($0.position, $0.index) < ($1.position, $1.index) }
    }

    /// `nil` if the Match isn't finished or can't be read.
    init?(_ match: Match) {
        guard match.status == .finished,
              let rules = GameCatalog.rules(for: match.kind),
              let outcome = try? match.outcome(using: rules),
              let detail = Self.detail(of: match)
        else { return nil }
        let ordered = match.orderedParticipants
        guard ordered.count == outcome.scores.count else { return nil }
        let positions = outcome.finalPositions()
        id = match.id
        kind = match.kind
        startedAt = match.startedAt
        finishedAt = History.endDate(match)
        endedEarly = match.endedEarly
        self.detail = detail
        participants = ordered.enumerated().map { index, participant in
            Participant(
                index: index,
                name: participant.name,
                players: participant.orderedSeats.map(\.name),
                isTeam: participant.isTeam,
                score: outcome.scores[index],
                position: positions[index],
                isWinner: outcome.winners.contains(index)
            )
        }
    }

    private static func detail(of match: Match) -> Detail? {
        switch match.kind {
        case .truco:
            guard let variant = try? match.variant(Truco.self) else { return nil }
            return .truco(variant)
        case .generala:
            guard let variant = try? match.variant(Generala.self),
                  let log = try? match.log(Generala.self)
            else { return nil }
            return .generala(variant, entries: log.entries)
        case .burako:
            guard let variant = try? match.variant(Burako.self),
                  let log = try? match.log(Burako.self)
            else { return nil }
            return .burako(variant, handCount: log.entries.count)
        }
    }

    // MARK: - Texts

    /// How the Variant reads in the detail: a label and a value per option.
    var variantRows: [(label: String, value: String)] {
        switch detail {
        case .truco(let variant):
            [("Se juega a", "\(variant.target)")]
        case .generala(let variant, _):
            [("Generala servida gana", variant.servedGeneralaWins ? "Sí" : "No")]
        case .burako(let variant, _):
            [("Meta", Burako.grouped(variant.target)), ("Muerto", variant.muerto.displayName)]
        }
    }

    /// The Winners, or "Empate" followed by who tied, for the headline and VoiceOver.
    var winnersText: String {
        winners.map(\.name).joined(separator: " · ")
    }
}
