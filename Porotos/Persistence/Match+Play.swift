import Foundation
import SwiftData

/// The shared actions of the Match and end screens: Undo, Variant and Team name changes,
/// Rematch, and the list of Matches In progress for Home.
extension Match {
    /// The Matches In progress, the last one scored first (Home, SPEC §5.1).
    static func inProgress(in context: ModelContext) throws -> [Match] {
        let status = MatchStatus.inProgress.rawValue
        return try context.fetch(FetchDescriptor<Match>(
            predicate: #Predicate { $0.statusRaw == status },
            sortBy: [SortDescriptor(\.lastEntryAt, order: .reverse)]
        ))
    }

    // MARK: - Undo

    func canUndo<R: GameRules>(_ rules: R.Type) -> Bool {
        endedEarly || ((try? log(rules).canUndo) ?? false)
    }

    /// Reverts the last change. On the end screen of a Match that Ended early, it only reverts
    /// the ending: the Match goes back In progress with the same Entries (SPEC §6.2). Otherwise
    /// it reverts the last change to the Entries, which reopens a Match that ended by the rules.
    func undo<R: GameRules>(_ rules: R.Type, date: Date = .now) throws {
        if endedEarly {
            try resume(rules)
        } else {
            try modify(rules, date: date) { $0.undo() }
        }
    }

    // MARK: - Mid-Match changes (SPEC §6.4)

    /// Whether the Variant can be changed to `variant` without ending the Match on the spot.
    func allows<R: GameRules>(_ variant: R.Variant, _ rules: R.Type) -> Bool {
        guard let entries = try? log(rules).entries else { return false }
        return R.allows(variant, participantCount: participants.count, entries: entries)
    }

    /// Renames a Team. A cleared name goes back to the default one (SPEC §3.3).
    func renameTeam<R: GameRules>(at index: Int, to text: String, _ rules: R.Type) throws {
        let ordered = orderedParticipants
        guard ordered.indices.contains(index), ordered[index].isTeam else { return }
        let players = ordered[index].orderedSeats.map(\.name)
        ordered[index].teamName = TeamName.resolved(text, default: R.defaultTeamName(at: index, players: players))
        try modelContext?.save()
    }

    // MARK: - Rematch (SPEC §5.4)

    /// The same Participants, order and Variant, with deleted Players left out. The drafts keep
    /// a `nil` seat for each deleted Player.
    func rematchSetup<R: GameRules>(_ rules: R.Type) throws -> MatchSetup<R.Variant> {
        MatchSetup(
            variant: try variant(rules),
            participants: orderedParticipants.map {
                ParticipantDraft(teamName: $0.teamName, players: $0.orderedSeats.map(\.player))
            }
        )
    }

    /// Starts the Rematch directly if those who are left meet the Game's minimum; otherwise
    /// returns `nil`, and the New Match screen should open with `rematchSetup`.
    func startRematch<R: GameRules>(_ rules: R.Type, date: Date = .now) throws -> Match? {
        guard let context = modelContext else { return nil }
        let setup = try rematchSetup(rules)
        let remaining = setup.participants.compactMap { draft -> ParticipantDraft? in
            let players = draft.players.compactMap { $0 }
            if draft.teamName == nil && players.isEmpty { return nil }
            return ParticipantDraft(teamName: draft.teamName, players: players)
        }
        guard R.canStart(with: remaining) else { return nil }
        return try Match.create(rules, variant: setup.variant, participants: remaining, in: context, date: date)
    }
}
