import Foundation
import SwiftData

/// What the New Match screen preloads.
struct MatchSetup<Variant: Equatable> {
    var variant: Variant
    var participants: [ParticipantDraft]
}

/// Remember the last setup (SPEC §3.5): each Game proposes the Variant and the Participants
/// of its latest Match that still exists, whether in progress or finished. A deleted Player
/// leaves an empty seat. The first time, the standard values are used.
enum RememberedSetup {
    static func last<R: GameRules>(_ rules: R.Type, in context: ModelContext) throws -> MatchSetup<R.Variant> {
        let kind = R.kind.rawValue
        var descriptor = FetchDescriptor<Match>(
            predicate: #Predicate { $0.kindRaw == kind },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let latest = try context.fetch(descriptor).first else {
            return MatchSetup(variant: R.standardVariant, participants: R.initialParticipants)
        }
        return MatchSetup(
            variant: try latest.variant(rules),
            participants: latest.orderedParticipants.map { participant in
                ParticipantDraft(
                    teamName: participant.teamName,
                    players: participant.orderedSeats.map(\.player)
                )
            }
        )
    }
}
