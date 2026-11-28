import Foundation

/// What History filters by (SPEC §5.5): every Game or a single one.
enum HistoryFilter: Hashable {
    case all
    case game(GameKind)

    func includes(_ match: Match) -> Bool {
        switch self {
        case .all: true
        case .game(let kind): match.kind == kind
        }
    }
}

/// The Finished Matches of one month, newest first.
struct HistoryMonth: Identifiable, Equatable {
    /// The first instant of the month.
    var start: Date
    var matches: [Match]

    var id: Date { start }
}

/// The pure logic behind History (SPEC §5.5): ordering, grouping by month and the texts.
enum History {
    /// Dates and durations are shown in Rioplatense Spanish, like the rest of the UI copy.
    static let locale = Locale(identifier: "es_AR")

    /// When a Match finished (or, if it somehow has no end date, when it started).
    static func endDate(_ match: Match) -> Date {
        match.finishedAt ?? match.startedAt
    }

    /// The Finished Matches that pass the filter, grouped by month, newest first.
    static func months(
        _ matches: [Match],
        filter: HistoryFilter = .all,
        calendar: Calendar = .current
    ) -> [HistoryMonth] {
        let finished = matches
            .filter { $0.status == .finished && filter.includes($0) }
            .sorted { endDate($0) > endDate($1) }
        var months: [HistoryMonth] = []
        for match in finished {
            let start = calendar.dateInterval(of: .month, for: endDate(match))?.start ?? endDate(match)
            if let last = months.indices.last, months[last].start == start {
                months[last].matches.append(match)
            } else {
                months.append(HistoryMonth(start: start, matches: [match]))
            }
        }
        return months
    }

    /// "Noviembre 2026".
    static func monthTitle(_ start: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "LLLL yyyy"
        let title = formatter.string(from: start)
        return title.prefix(1).uppercased() + title.dropFirst()
    }

    /// "28 nov".
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }

    /// "28 de noviembre de 2026, 21:30".
    static func fullDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year().hour().minute().locale(locale))
    }

    /// The time a Match took, from its start date to its end date: "Menos de 1 min", "35 min",
    /// "1 h 5 min", "2 h".
    static func duration(from start: Date, to end: Date) -> String {
        let minutes = Int((max(end.timeIntervalSince(start), 0) / 60).rounded())
        guard minutes >= 1 else { return "Menos de 1 min" }
        let hours = minutes / 60
        let rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (_, 0): return "\(hours) h"
        default: return "\(hours) h \(rest) min"
        }
    }
}

extension Outcome {
    /// Everyone's position for History (SPEC §5.5): the Winners share the 1st, then the rest
    /// follow by score, skipping places after a tie. It differs from `positions()` when the
    /// Winners don't have the highest score (a Served Generala that wins the Match).
    func finalPositions() -> [Int] {
        scores.indices.map { index in
            if winners.contains(index) { return 1 }
            let others = scores.indices.filter { !winners.contains($0) }
            return 1 + winners.count + others.filter { scores[$0] > scores[index] }.count
        }
    }
}

extension Match {
    /// What "Jugar de nuevo" opens (SPEC §5.5): the new Match if the Rematch can start
    /// directly, or the New Match screen with the rest loaded when someone is missing.
    func playAgain(date: Date = .now) -> MatchFlowStart? {
        guard let rules = GameCatalog.rules(for: kind) else { return nil }
        if let next = try? startRematch(rules, date: date) { return .open(next) }
        return .rematchSetup(self)
    }
}
