import Foundation
@testable import Porotos

/// A minimal Game to exercise the shared model: each Entry adds points to a Participant, and
/// the first one to reach the target wins.
enum SumGame: GameRules {
    struct Variant: Codable, Equatable, Sendable { var target: Int }
    struct Entry: Codable, Equatable, Sendable { var participant: Int; var points: Int }

    static let kind = GameKind.truco
    static let standardVariant = Variant(target: 10)
    static var initialParticipants: [ParticipantDraft] { [.team("Nosotros"), .team("Ellos")] }

    static func canStart(with participants: [ParticipantDraft]) -> Bool {
        participants.count >= 2
    }

    static func outcome(variant: Variant, participantCount: Int, entries: [Entry]) -> Outcome {
        var scores = Array(repeating: 0, count: participantCount)
        for entry in entries { scores[entry.participant] += entry.points }
        guard scores.contains(where: { $0 >= variant.target }) else { return .inProgress(scores) }
        return Outcome(scores: scores, isFinished: true, winners: Outcome.leaders(scores))
    }
}

/// Another Game, to check that each Game remembers its own setup.
enum OtherGame: GameRules {
    struct Variant: Codable, Equatable, Sendable { var option: Bool }
    typealias Entry = Int

    static let kind = GameKind.generala
    static let standardVariant = Variant(option: true)
    static var initialParticipants: [ParticipantDraft] { [] }

    static func canStart(with participants: [ParticipantDraft]) -> Bool { true }

    static func outcome(variant: Variant, participantCount: Int, entries: [Int]) -> Outcome {
        .inProgress(Array(repeating: 0, count: participantCount))
    }
}
