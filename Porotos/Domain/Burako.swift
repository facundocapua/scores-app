import Foundation

/// Burako (SPEC §4.3): individual with 2 to 4 Players, or 2 pairs. Each Hand is scored with the
/// calculator, and the Match ends on the first Hand that leaves someone at the Target score
/// with a single highest total. The app is a scorekeeper, not a referee: it enforces only what
/// is named in the spec.
enum Burako: GameRules {
    /// What taking, or not taking, the Muerto is worth (SPEC §4.3).
    enum Muerto: String, Codable, CaseIterable, Sendable {
        /// "Suma y resta" (default): +100 taking it, −100 not taking it.
        case addsAndSubtracts
        /// "Solo resta": 0 taking it, −100 not taking it.
        case subtractsOnly
        /// "Solo suma": +100 taking it, 0 not taking it.
        case addsOnly

        var taken: Int {
            switch self {
            case .addsAndSubtracts, .addsOnly: 100
            case .subtractsOnly: 0
            }
        }

        var notTaken: Int {
            switch self {
            case .addsAndSubtracts, .subtractsOnly: -100
            case .addsOnly: 0
            }
        }

        var displayName: String {
            switch self {
            case .addsAndSubtracts: "Suma y resta"
            case .subtractsOnly: "Solo resta"
            case .addsOnly: "Solo suma"
            }
        }
    }

    struct Variant: Codable, Equatable, Sendable {
        /// The Target score.
        var target: Int
        var muerto: Muerto

        static let presets = [2000, 2500, 3000]
        /// A free Target score ("Otra") has to be in this range.
        static let targetRange = 100...99_999

        static func isValidTarget(_ target: Int) -> Bool { targetRange.contains(target) }
    }

    /// What one Participant scored in a Hand: the calculator's fields (SPEC §4.3).
    struct Line: Codable, Equatable, Sendable {
        var cleanCanastas = 0
        var dirtyCanastas = 0
        /// Tiles melded: one number, added up by hand (in pairs, both partners together).
        var tilesMelded = 0
        /// Tiles in hand: subtracts.
        var tilesInHand = 0
        /// "Cerró".
        var wentOut = false
        /// "Tomó el muerto".
        var tookMuerto = false

        static let cleanCanastaValue = 200
        static let dirtyCanastaValue = 100
        static let wentOutValue = 100

        /// Nothing entered yet.
        var isBlank: Bool { self == Line() }

        /// clean × 200 + dirty × 100 + Tiles melded − Tiles in hand + Went out + Muerto.
        /// No rule validation: for example, Went out without canastas is allowed.
        func result(_ variant: Variant) -> Int {
            cleanCanastas * Self.cleanCanastaValue
                + dirtyCanastas * Self.dirtyCanastaValue
                + tilesMelded
                - tilesInHand
                + (wentOut ? Self.wentOutValue : 0)
                + (tookMuerto ? variant.muerto.taken : variant.muerto.notTaken)
        }
    }

    /// A Hand: one Line per Participant, in the Match's order.
    struct Hand: Codable, Equatable, Sendable {
        var lines: [Line]

        init(participantCount: Int) {
            lines = Array(repeating: Line(), count: participantCount)
        }

        /// At most one Participant goes out, or none.
        var isValid: Bool { lines.filter(\.wentOut).count <= 1 }

        func result(for participant: Int, _ variant: Variant) -> Int {
            lines.indices.contains(participant) ? lines[participant].result(variant) : 0
        }

        /// A Hand with nothing entered.
        var isBlank: Bool { lines.allSatisfy(\.isBlank) }
    }

    typealias Entry = Hand

    /// The Hand being entered, saved with the Match so it survives the app being killed
    /// (SPEC §6.5).
    struct Draft: Codable, Equatable, Sendable {
        var hand: Hand
        /// Whose tab of the calculator was open.
        var participant: Int
    }

    static let kind = GameKind.burako
    static let standardVariant = Variant(target: 3000, muerto: .addsAndSubtracts)
    static let maxPlayers = 4
    static let minIndividualPlayers = 2

    /// The first time: Pairs with empty spots.
    static var initialParticipants: [ParticipantDraft] {
        (0..<2).map { _ in .team("", players: [nil, nil]) }
    }

    /// Whether the drafts are two pairs rather than individual Players.
    static func isPairs(_ participants: [ParticipantDraft]) -> Bool {
        participants.contains { $0.teamName != nil }
    }

    /// 2 Players in individual (up to 4), or all 4 spots filled in Pairs.
    static func canStart(with participants: [ParticipantDraft]) -> Bool {
        if isPairs(participants) {
            return participants.count == 2 && participants.allSatisfy {
                $0.teamName != nil && $0.players.count == 2 && !$0.hasEmptySeats
            }
        }
        let filled = participants.filter { $0.players.compactMap { $0 }.count == 1 }
        return filled.count == participants.count
            && (minIndividualPlayers...maxPlayers).contains(participants.count)
    }

    /// "Facu y Caro", from the Players' names (SPEC §3.3), cut to the Team name limit.
    static func defaultTeamName(at index: Int, players: [String]) -> String {
        let names = players.filter { !$0.isEmpty }
        guard !names.isEmpty else { return "Pareja \(index + 1)" }
        return TeamName.limited(names.joined(separator: " y "))
    }

    // MARK: - Scores and the end

    /// The totals after each Hand, until the Match ends. Negative totals are allowed.
    /// The Match ends on the first Hand that leaves someone at the Target score or past it
    /// with a single highest total; a tie at the top is broken by another Hand.
    static func outcome(variant: Variant, participantCount: Int, entries: [Hand]) -> Outcome {
        var scores = Array(repeating: 0, count: participantCount)
        for hand in entries {
            for participant in scores.indices {
                scores[participant] += hand.result(for: participant, variant)
            }
            if let winner = winner(of: scores, target: variant.target) {
                return Outcome(scores: scores, isFinished: true, winners: [winner])
            }
        }
        return .inProgress(scores)
    }

    /// The position of the Hand that ends the Match, if any.
    static func endingHand(variant: Variant, participantCount: Int, entries: [Hand]) -> Int? {
        var scores = Array(repeating: 0, count: participantCount)
        for (index, hand) in entries.enumerated() {
            for participant in scores.indices {
                scores[participant] += hand.result(for: participant, variant)
            }
            if winner(of: scores, target: variant.target) != nil { return index }
        }
        return nil
    }

    /// Whoever has the single highest total, once someone reached the Target score.
    private static func winner(of scores: [Int], target: Int) -> Int? {
        guard let highest = scores.max(), highest >= target else { return nil }
        let leaders = Outcome.leaders(scores)
        return leaders.count == 1 ? leaders[0] : nil
    }

    /// Whether Hand `index` can be corrected to `hand` (SPEC §6.1). A correction that makes
    /// someone reach the Target score in a Hand earlier than the last is rejected, so that no
    /// Hands are left after the end.
    static func canCorrect(
        handAt index: Int,
        to hand: Hand,
        variant: Variant,
        participantCount: Int,
        entries: [Hand]
    ) -> Bool {
        guard entries.indices.contains(index), hand.isValid else { return false }
        var corrected = entries
        corrected[index] = hand
        guard let ending = endingHand(variant: variant, participantCount: participantCount, entries: corrected) else {
            return true
        }
        return ending == corrected.count - 1
    }

    /// Whether the Target score can be changed mid-Match (SPEC §6.4): it has to be above every
    /// total, or it would end the Match on the spot.
    static func canSetTarget(_ target: Int, scores: [Int]) -> Bool {
        guard Variant.isValidTarget(target) else { return false }
        return target > (scores.max() ?? 0)
    }

    /// How many points a Participant has left to the Target score.
    static func remaining(score: Int, target: Int) -> Int {
        max(target - score, 0)
    }

    // MARK: - Reading numbers

    /// "1.240": thousands separated by a dot, as read in Argentina. Always grouped, so it
    /// doesn't depend on the device's region.
    static func grouped(_ number: Int) -> String {
        let digits = String(abs(number))
        var result = ""
        for (offset, digit) in digits.reversed().enumerated() {
            if offset > 0, offset % 3 == 0 { result.append(".") }
            result.append(digit)
        }
        return (number < 0 ? "-" : "") + String(result.reversed())
    }

    /// What VoiceOver reads after a Participant's name: "1.240, faltan 1.760" (SPEC §8).
    static func spokenTotal(score: Int, target: Int) -> String {
        let total = score < 0 ? "menos \(grouped(-score))" : grouped(score)
        return "\(total), faltan \(grouped(remaining(score: score, target: target)))"
    }
}
