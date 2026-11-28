import Foundation

/// One of the supported Games (see `GLOSSARY.md`).
enum GameKind: String, Codable, CaseIterable, Sendable {
    case truco
    case generala
    case burako

    /// The name shown in the UI.
    var displayName: String {
        switch self {
        case .truco: "Truco"
        case .generala: "Generala"
        case .burako: "Burako"
        }
    }
}

/// What defines a Game (SPEC §3.6). The rest of the app (Home, History, Players, Undo,
/// ending and discarding) is shared and works with any `GameRules`.
///
/// Everything here is pure logic: scores, the end of the Match and the Winners are always
/// computed from the Entries and never stored (ADR 0001).
protocol GameRules {
    /// The rule options chosen when the Match is created.
    associatedtype Variant: Codable & Equatable & Sendable
    /// Each scoring action (a point, a Scoresheet cell, a Hand).
    associatedtype Entry: Codable & Equatable & Sendable

    static var kind: GameKind { get }

    /// The standard Argentine Variant, used the first time the Game is played.
    static var standardVariant: Variant { get }

    /// The Participants proposed the first time (for example, "Nosotros" and "Ellos").
    static var initialParticipants: [ParticipantDraft] { get }

    /// Whether the Game's minimum is met to start the Match.
    static func canStart(with participants: [ParticipantDraft]) -> Bool

    /// Scores, end and Winners according to the rules, ignoring Ended early.
    static func outcome(variant: Variant, participantCount: Int, entries: [Entry]) -> Outcome
}

/// What is computed from a Match. Participants are identified by their position.
struct Outcome: Equatable, Sendable {
    var scores: [Int]
    var isFinished: Bool
    /// Empty while the Match is in progress. More than one on a shared tie.
    var winners: [Int]

    static func inProgress(_ scores: [Int]) -> Outcome {
        Outcome(scores: scores, isFinished: false, winners: [])
    }

    /// The Participants in the lead: everyone with the highest score.
    static func leaders(_ scores: [Int]) -> [Int] {
        guard let highest = scores.max() else { return [] }
        return scores.indices.filter { scores[$0] == highest }
    }
}
