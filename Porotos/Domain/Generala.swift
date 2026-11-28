import Foundation

/// Generala (SPEC §4.2): 2 to 6 Players, one Scoresheet each with 11 categories. The app
/// enforces only the rules named in the spec: the points table, Served, "Generala servida
/// gana", the Double Generala rule, the Turns, the end and the shared tie.
enum Generala: GameRules {
    struct Variant: Codable, Equatable, Sendable {
        /// "Generala servida gana": a Served Generala wins the Match on the spot. When it is
        /// off, a Served Generala is worth 55.
        var servedGeneralaWins: Bool

        static let standard = Variant(servedGeneralaWins: true)
    }

    /// The 11 categories of the Scoresheet, in the order they are drawn.
    enum Category: Int, Codable, CaseIterable, Sendable {
        case ones, twos, threes, fours, fives, sixes
        case straight, fullHouse, fourOfAKind, generala, doubleGenerala

        /// The die face for ones to sixes: the points are a multiple of it.
        var face: Int? {
            rawValue < 6 ? rawValue + 1 : nil
        }

        var isCombination: Bool { face == nil }
    }

    /// What a Scoresheet cell holds once it is filled.
    enum Mark: Codable, Equatable, Sendable {
        case points(Int)
        case scratched

        var points: Int {
            if case .points(let points) = self { points } else { 0 }
        }

        var isScratched: Bool { self == .scratched }
    }

    /// A Scoresheet cell: whose, which category, its value and whether it was Served.
    /// A cell has at most one Entry; correcting it edits or removes that Entry.
    struct Entry: Codable, Equatable, Sendable {
        /// The Player's position, in Turn order.
        var participant: Int
        var category: Category
        var mark: Mark
        var served: Bool

        init(participant: Int, category: Category, mark: Mark, served: Bool = false) {
            self.participant = participant
            self.category = category
            self.mark = mark
            self.served = served
        }
    }

    /// A value the sheet offers for a category.
    struct Option: Hashable, Sendable {
        var points: Int
        var served: Bool
    }

    /// Why a correction is refused (SPEC §4.2, §6.1).
    enum Rejection: Equatable, Sendable {
        /// The Double can only be Scratched while the Generala is empty or Scratched.
        case doubleNeedsGenerala
        /// The Generala can't be Scratched or cleared while the Double has points.
        case generalaHasDouble
    }

    static let kind = GameKind.generala
    static let standardVariant = Variant.standard
    static let minimumPlayers = 2
    static let maximumPlayers = 6
    /// Every Player fills one cell per category.
    static let categoryCount = Category.allCases.count

    static var initialParticipants: [ParticipantDraft] { [] }

    /// 2 to 6 Players, one per Participant.
    static func canStart(with participants: [ParticipantDraft]) -> Bool {
        (minimumPlayers...maximumPlayers).contains(participants.count)
            && participants.allSatisfy { $0.teamName == nil && $0.players.compactMap { $0 }.count == 1 }
    }

    // MARK: - Points table

    /// The values the sheet offers for a category: the normal ones first, then the Served one
    /// when it applies (ones to sixes have none).
    static func options(for category: Category, variant: Variant) -> [Option] {
        if let face = category.face {
            return (1...5).map { Option(points: face * $0, served: false) }
        }
        switch category {
        case .straight:
            return [Option(points: 20, served: false), Option(points: 25, served: true)]
        case .fullHouse:
            return [Option(points: 30, served: false), Option(points: 35, served: true)]
        case .fourOfAKind:
            return [Option(points: 40, served: false), Option(points: 45, served: true)]
        case .generala:
            // With the option on, the Served Generala ends the Match: the 50 only stands in for it.
            return [
                Option(points: 50, served: false),
                Option(points: variant.servedGeneralaWins ? 50 : 55, served: true),
            ]
        default: // Double Generala
            return [Option(points: 100, served: false), Option(points: 100, served: true)]
        }
    }

    // MARK: - Reading the Scoresheet

    static func entry(of participant: Int, _ category: Category, in entries: [Entry]) -> Entry? {
        entries.last { $0.participant == participant && $0.category == category }
    }

    private static func index(of participant: Int, _ category: Category, in entries: [Entry]) -> Int? {
        entries.lastIndex { $0.participant == participant && $0.category == category }
    }

    static func total(of participant: Int, in entries: [Entry]) -> Int {
        Category.allCases.reduce(0) { sum, category in
            sum + (entry(of: participant, category, in: entries)?.mark.points ?? 0)
        }
    }

    static func filledCount(of participant: Int, in entries: [Entry]) -> Int {
        Category.allCases.filter { entry(of: participant, $0, in: entries) != nil }.count
    }

    static func hasFilledScoresheet(_ participant: Int, in entries: [Entry]) -> Bool {
        filledCount(of: participant, in: entries) == categoryCount
    }

    // MARK: - End and Winners

    /// Scores, end and Winners. The Match ends when a Served Generala is scored with the option
    /// on (that Player wins) or when every Player has filled the 11 categories (the highest
    /// total wins; a tie for first place is shared, with no tiebreaker).
    static func outcome(variant: Variant, participantCount: Int, entries: [Entry]) -> Outcome {
        let entries = entries.filter { (0..<participantCount).contains($0.participant) }
        let scores = (0..<participantCount).map { total(of: $0, in: entries) }

        if variant.servedGeneralaWins,
           let served = entries.first(where: { $0.category == .generala && $0.served && !$0.mark.isScratched }) {
            return Outcome(scores: scores, isFinished: true, winners: [served.participant])
        }
        let allFilled = participantCount > 0
            && (0..<participantCount).allSatisfy { hasFilledScoresheet($0, in: entries) }
        guard allFilled else { return .inProgress(scores) }
        return Outcome(scores: scores, isFinished: true, winners: Outcome.leaders(scores))
    }

    // MARK: - Turns

    /// Whose Turn it is, or `nil` when everyone has filled their Scoresheet. It starts with
    /// the first Player and passes to the next one who has free categories, in the Match's
    /// order, when the one rolling scores. Scoring in another Player's column doesn't move it:
    /// the Turn is a guide, not a lock. Computed from the Entries, so Undo and corrections
    /// keep it consistent.
    static func turn(participantCount: Int, entries: [Entry]) -> Int? {
        guard participantCount > 0 else { return nil }
        var filled = Array(repeating: Set<Category>(), count: participantCount)

        func firstFree(from start: Int) -> Int? {
            (0..<participantCount)
                .map { (start + $0) % participantCount }
                .first { filled[$0].count < categoryCount }
        }

        var current = firstFree(from: 0)
        for entry in entries where filled.indices.contains(entry.participant) {
            filled[entry.participant].insert(entry.category)
            guard let rolling = current else { break }
            if entry.participant == rolling {
                current = firstFree(from: rolling + 1)
            }
        }
        return current
    }

    // MARK: - Correcting (the Double Generala rule)

    /// Checks putting `mark` (or clearing, with `nil`) in a cell against the Double Generala
    /// rule: the Double has points only if the Generala has them, also when correcting.
    static func rejection(
        placing mark: Mark?,
        in category: Category,
        of participant: Int,
        entries: [Entry]
    ) -> Rejection? {
        switch category {
        case .doubleGenerala:
            guard case .points = mark else { return nil }
            let generala = entry(of: participant, .generala, in: entries)
            if case .points = generala?.mark { return nil }
            return .doubleNeedsGenerala
        case .generala:
            if case .points = mark { return nil }
            if case .points = entry(of: participant, .doubleGenerala, in: entries)?.mark {
                return .generalaHasDouble
            }
            return nil
        default:
            return nil
        }
    }

    /// Fills, edits, scratches or clears (with `mark == nil`) a cell, as one change that Undo
    /// can revert. Returns the reason if the Double Generala rule forbids it.
    @discardableResult
    static func place(
        _ mark: Mark?,
        served: Bool = false,
        in category: Category,
        of participant: Int,
        log: inout EntryLog<Entry>
    ) -> Rejection? {
        if let rejection = rejection(placing: mark, in: category, of: participant, entries: log.entries) {
            return rejection
        }
        let existing = index(of: participant, category, in: log.entries)
        switch (existing, mark) {
        case (nil, nil):
            break
        case let (nil, mark?):
            log.add(Entry(participant: participant, category: category, mark: mark, served: served))
        case let (index?, mark?):
            log.edit(at: index, with: Entry(participant: participant, category: category, mark: mark, served: served))
        case let (index?, nil):
            log.remove(at: index)
        }
        return nil
    }
}
