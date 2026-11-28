import Foundation

/// Truco (SPEC §4.1): two Teams, +1 or −1 point at a time, to 15 or to 30. The app enforces
/// only the score: envido, flor and the other calls are points the scorekeeper adds by hand.
enum Truco: GameRules {
    struct Variant: Codable, Equatable, Sendable {
        /// 15 or 30.
        var target: Int

        static let to15 = Variant(target: 15)
        static let to30 = Variant(target: 30)
        static let all = [to15, to30]

        /// Up to 30 the score is split into malas and buenas; up to 15 it is a single block.
        var hasHalves: Bool { target == 30 }
    }

    /// A point of +1 or −1 for a Team.
    struct Entry: Codable, Equatable, Sendable {
        /// The Team's position: 0 or 1.
        var team: Int
        /// +1 or −1.
        var points: Int
    }

    static let kind = GameKind.truco
    static let standardVariant = Variant.to30
    static let teamNames = ["Nosotros", "Ellos"]

    static var initialParticipants: [ParticipantDraft] {
        teamNames.map { .team($0) }
    }

    /// Truco can always start, with or without Players.
    static func canStart(with participants: [ParticipantDraft]) -> Bool {
        participants.count == 2
    }

    /// Scores never go below 0 or above the target. The first Team to reach it wins.
    static func outcome(variant: Variant, participantCount: Int, entries: [Entry]) -> Outcome {
        let scores = scores(variant: variant, participantCount: participantCount, entries: entries)
        let winners = scores.indices.filter { scores[$0] >= variant.target }
        guard !winners.isEmpty else { return .inProgress(scores) }
        return Outcome(scores: scores, isFinished: true, winners: winners)
    }

    static func scores(variant: Variant, participantCount: Int, entries: [Entry]) -> [Int] {
        var scores = Array(repeating: 0, count: participantCount)
        for entry in entries where scores.indices.contains(entry.team) {
            scores[entry.team] = min(max(scores[entry.team] + entry.points, 0), variant.target)
        }
        return scores
    }

    /// The −1 is disabled when the Team has 0.
    static func canSubtract(from score: Int) -> Bool { score > 0 }

    /// The score can't be exceeded.
    static func canAdd(to score: Int, variant: Variant) -> Bool { score < variant.target }
}

/// How a Truco score is drawn and read: the malas, the buenas and the groups of five
/// matchsticks (SPEC §4.1).
struct TrucoTally: Equatable {
    /// To 30: the points from 0 to 15. To 15: every point.
    var malas: Int
    /// To 30: the points from 15 to 30. To 15: always 0.
    var buenas: Int

    init(score: Int, variant: Truco.Variant) {
        if variant.hasHalves {
            malas = min(score, 15)
            buenas = max(score - 15, 0)
        } else {
            malas = score
            buenas = 0
        }
    }

    /// The matchsticks of each group of five: [5, 5, 2] for 12.
    static func groups(_ points: Int) -> [Int] {
        stride(from: 0, to: points, by: 5).map { min(5, points - $0) }
    }

    /// What VoiceOver reads after the Team's name: "17, buenas 2" (SPEC §8).
    func spokenValue(score: Int, variant: Truco.Variant) -> String {
        guard variant.hasHalves else { return "\(score)" }
        return buenas > 0 ? "\(score), buenas \(buenas)" : "\(score), malas \(malas)"
    }
}
