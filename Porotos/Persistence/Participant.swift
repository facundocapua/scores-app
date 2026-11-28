import Foundation
import SwiftData

/// Whoever scores and can win in a Match: a single Player or a Team (SPEC §3.2).
@Model
final class Participant {
    var order: Int
    /// The Team's name. `nil` when the Participant is a single Player.
    var teamName: String?
    var match: Match?

    @Relationship(deleteRule: .cascade, inverse: \Seat.participant)
    var seats: [Seat] = []

    init(order: Int, teamName: String?) {
        self.order = order
        self.teamName = teamName
    }

    var orderedSeats: [Seat] {
        seats.sorted { $0.order < $1.order }
    }

    var isTeam: Bool { teamName != nil }

    var name: String {
        teamName ?? orderedSeats.first?.name ?? ""
    }
}

/// A Player's place within a Participant.
@Model
final class Seat {
    var order: Int
    /// `nil` if the Player was deleted.
    var player: Player?
    /// The name shown once the Player is deleted.
    var savedName: String
    var participant: Participant?

    init(order: Int, player: Player) {
        self.order = order
        self.player = player
        self.savedName = player.name
    }

    /// The Player's current name while they exist; otherwise, the last one they had.
    var name: String { player?.name ?? savedName }
}

/// A Participant before the Match is created: what the New Match screen builds and what
/// the remembered setup proposes.
struct ParticipantDraft: Equatable {
    /// The Team's name, or `nil` for a single Player.
    var teamName: String?
    /// The Players in order. `nil` is an empty seat (for example, a deleted Player).
    var players: [Player?]

    init(teamName: String? = nil, players: [Player?] = []) {
        self.teamName = teamName
        self.players = players
    }

    static func player(_ player: Player?) -> ParticipantDraft {
        ParticipantDraft(players: [player])
    }

    static func team(_ name: String, players: [Player?] = []) -> ParticipantDraft {
        ParticipantDraft(teamName: name, players: players)
    }

    var hasEmptySeats: Bool { players.contains { $0 == nil } }
}
