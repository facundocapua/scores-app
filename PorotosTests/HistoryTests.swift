import Foundation
import SwiftData
import Testing
@testable import Porotos

@MainActor
struct HistoryTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        container = try Store.container(inMemory: true)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func finishedTruco(start: Date, end: Date, points: Int = 1) throws -> Match {
        let match = try Match.create(
            Truco.self, variant: .to15, participants: Truco.initialParticipants, in: context, date: start
        )
        try match.modify(Truco.self, date: end) { log in
            for _ in 0..<15 { log.add(.init(team: 0, points: points)) }
        }
        return match
    }

    private func players(_ names: [String]) -> [Player] {
        names.map { name in
            let player = Player(name: name)
            context.insert(player)
            return player
        }
    }

    // MARK: - Grouping and filtering

    @Test func monthsGroupFinishedMatchesNewestFirst() throws {
        let october = try finishedTruco(start: date(2026, 10, 3), end: date(2026, 10, 3, hour: 13))
        let novemberEarly = try finishedTruco(start: date(2026, 11, 1), end: date(2026, 11, 1, hour: 13))
        let novemberLate = try finishedTruco(start: date(2026, 11, 20), end: date(2026, 11, 20, hour: 13))
        let inProgress = try Match.create(
            Truco.self, variant: .to30, participants: Truco.initialParticipants, in: context
        )

        let months = History.months(
            [october, novemberEarly, inProgress, novemberLate], calendar: calendar
        )

        #expect(months.count == 2)
        #expect(months[0].start == date(2026, 11, 1, hour: 0))
        #expect(months[0].matches == [novemberLate, novemberEarly])
        #expect(months[1].matches == [october])
    }

    @Test func theFilterKeepsOneGame() throws {
        let truco = try finishedTruco(start: date(2026, 11, 1), end: date(2026, 11, 1, hour: 13))
        let generala = try Match.create(
            Generala.self, variant: .standard, participants: players(["Ana", "Beto"]).map { .player($0) }, in: context
        )
        try generala.endEarly(date: date(2026, 11, 2))

        #expect(History.months([truco, generala], filter: .game(.generala), calendar: calendar).flatMap(\.matches) == [generala])
        #expect(History.months([truco, generala], filter: .game(.burako), calendar: calendar).isEmpty)
        #expect(History.months([truco, generala], filter: .all, calendar: calendar).flatMap(\.matches).count == 2)
    }

    @Test func monthTitleIsCapitalizedSpanish() {
        #expect(History.monthTitle(date(2026, 11, 1, hour: 0), calendar: calendar) == "Noviembre 2026")
    }

    // MARK: - Duration

    @Test func durationReadsInMinutesAndHours() {
        let start = date(2026, 11, 1, hour: 10)
        #expect(History.duration(from: start, to: start.addingTimeInterval(20)) == "Menos de 1 min")
        #expect(History.duration(from: start, to: start.addingTimeInterval(35 * 60)) == "35 min")
        #expect(History.duration(from: start, to: start.addingTimeInterval(60 * 60)) == "1 h")
        #expect(History.duration(from: start, to: start.addingTimeInterval(65 * 60)) == "1 h 5 min")
        #expect(History.duration(from: start, to: start.addingTimeInterval(-5)) == "Menos de 1 min")
    }

    // MARK: - Positions

    @Test func tiedWinnersShareTheFirstPosition() {
        let outcome = Outcome(scores: [50, 50, 10, 30], isFinished: true, winners: [0, 1])
        #expect(outcome.finalPositions() == [1, 1, 4, 3])
    }

    @Test func aWinnerWithoutTheHighestScoreIsStillFirst() {
        let outcome = Outcome(scores: [40, 200, 150], isFinished: true, winners: [0])
        #expect(outcome.finalPositions() == [1, 2, 3])
    }

    // MARK: - Every Game

    @Test func historyWorksWithTheThreeGames() throws {
        let people = players(["Ana", "Beto", "Caro", "Dani"])

        let truco = try finishedTruco(start: date(2026, 11, 1), end: date(2026, 11, 1, hour: 13))
        let generala = try Match.create(
            Generala.self, variant: .standard, participants: people.prefix(3).map { .player($0) }, in: context,
            date: date(2026, 11, 2)
        )
        try generala.modify(Generala.self, date: date(2026, 11, 2, hour: 13)) {
            Generala.place(.points(30), in: .fullHouse, of: 1, log: &$0)
        }
        try generala.endEarly(date: date(2026, 11, 2, hour: 14))
        let burako = try Match.create(
            Burako.self, variant: Burako.standardVariant,
            participants: [.team("Ana y Beto", players: [people[0], people[1]]), .team("Caro y Dani", players: [people[2], people[3]])],
            in: context, date: date(2026, 11, 3)
        )
        var hand = Burako.Hand(participantCount: 2)
        hand.lines[0] = .init(cleanCanastas: 1, tilesMelded: 100)
        try burako.modify(Burako.self) { $0.add(hand) }
        try burako.endEarly(date: date(2026, 11, 3, hour: 15))

        let trucoEntry = try #require(HistoryEntry(truco))
        #expect(trucoEntry.kind == .truco)
        #expect(trucoEntry.winners.map(\.name) == ["Nosotros"])
        #expect(!trucoEntry.isTie)
        #expect(!trucoEntry.endedEarly)

        let generalaEntry = try #require(HistoryEntry(generala))
        #expect(generalaEntry.endedEarly)
        #expect(generalaEntry.winners.map(\.name) == ["Beto"])
        #expect(generalaEntry.ranking.map(\.position) == [1, 2, 2])
        guard case .generala(_, let entries) = generalaEntry.detail else { Issue.record("wrong detail"); return }
        #expect(entries.count == 1)

        let burakoEntry = try #require(HistoryEntry(burako))
        #expect(burakoEntry.participants.map(\.players) == [["Ana", "Beto"], ["Caro", "Dani"]])
        #expect(burakoEntry.variantRows.map(\.label) == ["Meta", "Muerto"])
        guard case .burako(_, let handCount) = burakoEntry.detail else { Issue.record("wrong detail"); return }
        #expect(handCount == 1)
    }

    @Test func aMatchWithADeletedPlayerKeepsTheirLastName() throws {
        let people = players(["Ana", "Beto"])
        let match = try Match.create(
            Generala.self, variant: .standard, participants: people.map { .player($0) }, in: context
        )
        try match.modify(Generala.self) { Generala.place(.points(30), in: .fullHouse, of: 0, log: &$0) }
        try match.endEarly()
        try people[0].delete()

        let entry = try #require(HistoryEntry(match))
        #expect(entry.participants.map(\.name) == ["Ana", "Beto"])
        #expect(entry.winners.map(\.name) == ["Ana"])
        #expect(History.months([match]).count == 1)
    }

    @Test func anUnfinishedMatchHasNoEntry() throws {
        let match = try Match.create(Truco.self, variant: .to30, participants: Truco.initialParticipants, in: context)
        #expect(HistoryEntry(match) == nil)
    }

    // MARK: - Play again

    @Test func playAgainStartsDirectlyWhenEveryoneIsStillThere() throws {
        let people = players(["Ana", "Beto"])
        let match = try Match.create(
            Generala.self, variant: .standard, participants: people.map { .player($0) }, in: context
        )
        try match.endEarly()

        guard case .open(let next)? = match.playAgain() else { Issue.record("expected a new Match"); return }
        #expect(next.status == .inProgress)
        #expect(next.orderedParticipants.map(\.name) == ["Ana", "Beto"])
        #expect(match.status == .finished)
    }

    @Test func playAgainOpensTheNewMatchScreenWhenSomeoneIsMissing() throws {
        let people = players(["Ana", "Beto"])
        let match = try Match.create(
            Generala.self, variant: .standard, participants: people.map { .player($0) }, in: context
        )
        try match.endEarly()
        try people[1].delete()

        guard case .rematchSetup(let source)? = match.playAgain() else { Issue.record("expected the setup"); return }
        #expect(source === match)
    }
}
