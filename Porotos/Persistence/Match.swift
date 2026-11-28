import Foundation
import SwiftData

enum MatchStatus: String, Codable, Sendable {
    case inProgress
    case finished
}

/// A session of a Game (SPEC §3.1). It is shared by every Game: the Variant, the Entries and
/// the draft are stored encoded, and each Game reads them through its `GameRules`. Totals are
/// never stored: scores, the end and the Winners are computed (ADR 0001).
///
/// Every change is saved immediately, so closing the app never loses a Match.
@Model
final class Match {
    var id: UUID
    var kindRaw: String
    var statusRaw: String
    var endedEarly: Bool
    var startedAt: Date
    var finishedAt: Date?
    var lastEntryAt: Date
    var variantData: Data
    var logData: Data
    /// For Burako: the Hand being entered.
    var draftData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Participant.match)
    var participants: [Participant] = []

    private init(kind: GameKind, variantData: Data, logData: Data, date: Date) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.statusRaw = MatchStatus.inProgress.rawValue
        self.endedEarly = false
        self.startedAt = date
        self.finishedAt = nil
        self.lastEntryAt = date
        self.variantData = variantData
        self.logData = logData
    }

    /// Creates an in-progress Match and saves it. Empty seats in the drafts are skipped.
    @discardableResult
    static func create<R: GameRules>(
        _ rules: R.Type,
        variant: R.Variant,
        participants: [ParticipantDraft],
        in context: ModelContext,
        date: Date = .now
    ) throws -> Match {
        let match = Match(
            kind: R.kind,
            variantData: try Coding.encode(variant),
            logData: try Coding.encode(EntryLog<R.Entry>()),
            date: date
        )
        context.insert(match)
        for (order, draft) in participants.enumerated() {
            let participant = Participant(order: order, teamName: draft.teamName)
            match.participants.append(participant)
            for (seatOrder, player) in draft.players.compactMap({ $0 }).enumerated() {
                participant.seats.append(Seat(order: seatOrder, player: player))
            }
        }
        try context.save()
        return match
    }

    // MARK: - Reading

    var kind: GameKind { GameKind(rawValue: kindRaw) ?? .truco }

    var status: MatchStatus {
        get { MatchStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var orderedParticipants: [Participant] {
        participants.sorted { $0.order < $1.order }
    }

    func variant<R: GameRules>(_ rules: R.Type) throws -> R.Variant {
        try check(rules)
        return try Coding.decode(R.Variant.self, from: variantData)
    }

    func log<R: GameRules>(_ rules: R.Type) throws -> EntryLog<R.Entry> {
        try check(rules)
        return try Coding.decode(EntryLog<R.Entry>.self, from: logData)
    }

    /// Scores, end and Winners. In a Match that ended early, whoever is in the lead wins.
    func outcome<R: GameRules>(_ rules: R.Type) throws -> Outcome {
        let byRules = R.outcome(
            variant: try variant(rules),
            participantCount: participants.count,
            entries: try log(rules).entries
        )
        guard endedEarly else { return byRules }
        return Outcome(scores: byRules.scores, isFinished: true, winners: Outcome.leaders(byRules.scores))
    }

    /// For the shared screens, which don't know the Game.
    func outcome(using rules: any GameRules.Type) throws -> Outcome {
        try outcome(rules)
    }

    // MARK: - Changes

    /// Applies a change to the Entries (add, edit, remove or undo), recomputes the status and
    /// saves. If the Match had ended early, the change resumes it.
    func modify<R: GameRules>(
        _ rules: R.Type,
        date: Date = .now,
        _ change: (inout EntryLog<R.Entry>) -> Void
    ) throws {
        var log = try log(rules)
        change(&log)
        logData = try Coding.encode(log)
        lastEntryAt = date
        endedEarly = false
        try updateStatus(rules, date: date)
    }

    /// Changes the Variant mid-Match (SPEC §6.4). Each Game decides which options are allowed.
    func changeVariant<R: GameRules>(_ rules: R.Type, to newVariant: R.Variant, date: Date = .now) throws {
        try check(rules)
        variantData = try Coding.encode(newVariant)
        try updateStatus(rules, date: date)
    }

    /// "Terminar con este resultado" (SPEC §4.4).
    func endEarly(date: Date = .now) throws {
        guard status == .inProgress else { return }
        endedEarly = true
        status = .finished
        finishedAt = date
        try save()
    }

    /// Puts a Match that ended early back in progress, without touching its Entries.
    func resume<R: GameRules>(_ rules: R.Type) throws {
        guard endedEarly else { return }
        endedEarly = false
        try updateStatus(rules, date: finishedAt ?? .now)
    }

    func draft<D: Decodable>(_ type: D.Type) throws -> D? {
        guard let draftData else { return nil }
        return try Coding.decode(type, from: draftData)
    }

    func saveDraft<D: Encodable>(_ draft: D?) throws {
        if let draft {
            draftData = try Coding.encode(draft)
        } else {
            draftData = nil
        }
        try save()
    }

    /// Discard or delete (SPEC §6.3).
    func delete() throws {
        guard let context = modelContext else { return }
        context.delete(self)
        try context.save()
    }

    // MARK: - Private

    private func updateStatus<R: GameRules>(_ rules: R.Type, date: Date) throws {
        let outcome = try outcome(rules)
        if outcome.isFinished {
            if status == .inProgress {
                status = .finished
                finishedAt = date
            }
        } else {
            status = .inProgress
            finishedAt = nil
        }
        try save()
    }

    private func check<R: GameRules>(_ rules: R.Type) throws {
        guard R.kind == kind else {
            throw MatchError.wrongGame(expected: kind, got: R.kind)
        }
    }

    private func save() throws {
        try modelContext?.save()
    }
}

enum MatchError: Error, Equatable {
    case wrongGame(expected: GameKind, got: GameKind)
}

enum Coding {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}
