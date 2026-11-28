import Foundation
import SwiftData
import Testing
@testable import Porotos

struct GeneralaRulesTests {
    typealias Category = Generala.Category
    private let on = Generala.Variant(servedGeneralaWins: true)
    private let off = Generala.Variant(servedGeneralaWins: false)

    private func entry(_ participant: Int, _ category: Category, _ points: Int, served: Bool = false) -> Generala.Entry {
        Generala.Entry(participant: participant, category: category, mark: .points(points), served: served)
    }

    private func scratch(_ participant: Int, _ category: Category) -> Generala.Entry {
        Generala.Entry(participant: participant, category: category, mark: .scratched)
    }

    /// Everything a Player can fill, scratched.
    private func filled(_ participant: Int, except skipped: Set<Category> = []) -> [Generala.Entry] {
        Category.allCases.filter { !skipped.contains($0) }.map { scratch(participant, $0) }
    }

    // MARK: - Points table

    @Test func onesToSixesOfferOneToFiveTimesTheFace() {
        for category in Category.allCases.prefix(6) {
            let face = category.face!
            let options = Generala.options(for: category, variant: on)

            #expect(options.map(\.points) == (1...5).map { $0 * face })
            #expect(options.allSatisfy { !$0.served })
        }
    }

    @Test(arguments: [
        (Category.straight, 20, 25),
        (Category.fullHouse, 30, 35),
        (Category.fourOfAKind, 40, 45),
        (Category.doubleGenerala, 100, 100),
    ])
    func combinationsHaveANormalAndAServedValue(category: Category, normal: Int, served: Int) {
        for variant in [on, off] {
            #expect(Generala.options(for: category, variant: variant) == [
                .init(points: normal, served: false),
                .init(points: served, served: true),
            ])
        }
    }

    @Test func aServedGeneralaIsWorth55OnlyWithTheOptionOff() {
        #expect(Generala.options(for: .generala, variant: off) == [.init(points: 50, served: false), .init(points: 55, served: true)])
        #expect(Generala.options(for: .generala, variant: on).first == .init(points: 50, served: false))
        #expect(Generala.options(for: .generala, variant: on).last?.served == true)
    }

    @Test func scratchingScoresZero() {
        let entries = [entry(0, .sixes, 18), scratch(0, .straight), entry(0, .fullHouse, 35, served: true)]

        #expect(Generala.total(of: 0, in: entries) == 53)
    }

    @Test func thereIsNoSectionBonus() {
        let entries = (0..<6).map { entry(0, Category.allCases[$0], Category.allCases[$0].face! * 5) }

        #expect(Generala.total(of: 0, in: entries) == 5 * (1 + 2 + 3 + 4 + 5 + 6))
    }

    // MARK: - Served Generala

    @Test func aServedGeneralaWinsOnTheSpotWithTheOptionOn() {
        let entries = [entry(0, .fives, 15), entry(1, .generala, 50, served: true)]
        let outcome = Generala.outcome(variant: on, participantCount: 3, entries: entries)

        #expect(outcome == Outcome(scores: [15, 50, 0], isFinished: true, winners: [1]))
    }

    @Test func theServedGeneralaWinsEvenWithAHigherTotalElsewhere() {
        let entries = [entry(0, .fourOfAKind, 45, served: true), entry(0, .doubleGenerala, 100), entry(1, .generala, 50, served: true)]
        let outcome = Generala.outcome(variant: on, participantCount: 2, entries: entries)

        #expect(outcome.isFinished)
        #expect(outcome.winners == [1])
    }

    @Test func aServedGeneralaIsWorth55WithTheOptionOffAndTheMatchGoesOn() {
        let entries = [entry(1, .generala, 55, served: true)]
        let outcome = Generala.outcome(variant: off, participantCount: 2, entries: entries)

        #expect(outcome == .inProgress([0, 55]))
    }

    @Test func aGeneralaThatIsNotServedDoesNotEndTheMatch() {
        let outcome = Generala.outcome(variant: on, participantCount: 2, entries: [entry(0, .generala, 50)])

        #expect(outcome == .inProgress([50, 0]))
    }

    @Test func turningTheOptionOnIsDisabledOnceAServedGeneralaHasHappened() {
        let withServed = [entry(0, .generala, 55, served: true)]
        let without = [entry(0, .generala, 50)]

        #expect(!Generala.allows(on, participantCount: 2, entries: withServed))
        #expect(Generala.allows(off, participantCount: 2, entries: withServed))
        #expect(Generala.allows(on, participantCount: 2, entries: without))
    }

    // MARK: - Double Generala

    @Test func theDoubleOnlyScoresWithPointsIfTheGeneralaHasPoints() {
        let empty: [Generala.Entry] = []
        let scratched = [scratch(0, .generala)]
        let scored = [entry(0, .generala, 50)]
        let servedOff = [entry(0, .generala, 55, served: true)]

        #expect(Generala.rejection(placing: .points(100), in: .doubleGenerala, of: 0, entries: empty) == .doubleNeedsGenerala)
        #expect(Generala.rejection(placing: .points(100), in: .doubleGenerala, of: 0, entries: scratched) == .doubleNeedsGenerala)
        #expect(Generala.rejection(placing: .points(100), in: .doubleGenerala, of: 0, entries: scored) == nil)
        #expect(Generala.rejection(placing: .points(100), in: .doubleGenerala, of: 0, entries: servedOff) == nil)
        // It can always be scratched.
        #expect(Generala.rejection(placing: .scratched, in: .doubleGenerala, of: 0, entries: empty) == nil)
        // Another Player's Generala doesn't count.
        #expect(Generala.rejection(placing: .points(100), in: .doubleGenerala, of: 1, entries: scored) == .doubleNeedsGenerala)
    }

    @Test func theGeneralaCannotBeScratchedOrClearedWhileTheDoubleHasPoints() {
        var log = EntryLog<Generala.Entry>()
        Generala.place(.points(50), in: .generala, of: 0, log: &log)
        Generala.place(.points(100), in: .doubleGenerala, of: 0, log: &log)

        #expect(Generala.place(.scratched, in: .generala, of: 0, log: &log) == .generalaHasDouble)
        #expect(Generala.place(nil, in: .generala, of: 0, log: &log) == .generalaHasDouble)
        #expect(Generala.entry(of: 0, .generala, in: log.entries)?.mark == .points(50))
        // Changing it to another value with points is fine.
        #expect(Generala.place(.points(55), served: true, in: .generala, of: 0, log: &log) == nil)
    }

    @Test func scratchingTheDoubleFirstFreesTheGenerala() {
        var log = EntryLog<Generala.Entry>()
        Generala.place(.points(50), in: .generala, of: 0, log: &log)
        Generala.place(.points(100), in: .doubleGenerala, of: 0, log: &log)

        Generala.place(.scratched, in: .doubleGenerala, of: 0, log: &log)
        #expect(Generala.place(.scratched, in: .generala, of: 0, log: &log) == nil)

        var other = EntryLog<Generala.Entry>()
        Generala.place(.points(50), in: .generala, of: 0, log: &other)
        Generala.place(.points(100), in: .doubleGenerala, of: 0, log: &other)
        Generala.place(nil, in: .doubleGenerala, of: 0, log: &other)
        #expect(Generala.place(nil, in: .generala, of: 0, log: &other) == nil)
        #expect(other.entries.isEmpty)
    }

    @Test func aRejectedChangeLeavesTheLogUntouched() {
        var log = EntryLog<Generala.Entry>()

        #expect(Generala.place(.points(100), in: .doubleGenerala, of: 0, log: &log) == .doubleNeedsGenerala)
        #expect(log.entries.isEmpty)
        #expect(!log.canUndo)
    }

    // MARK: - Correcting in place

    @Test func aCellIsEditedInPlaceScratchedAndClearedWithUndoForEach() {
        var log = EntryLog<Generala.Entry>()
        Generala.place(.points(12), in: .fours, of: 1, log: &log)
        Generala.place(.points(16), in: .fours, of: 1, log: &log)
        #expect(log.entries.count == 1)
        #expect(Generala.total(of: 1, in: log.entries) == 16)

        Generala.place(.scratched, in: .fours, of: 1, log: &log)
        #expect(Generala.total(of: 1, in: log.entries) == 0)
        #expect(Generala.entry(of: 1, .fours, in: log.entries)?.mark == .scratched)

        Generala.place(nil, in: .fours, of: 1, log: &log)
        #expect(log.entries.isEmpty)

        log.undo()
        #expect(Generala.entry(of: 1, .fours, in: log.entries)?.mark == .scratched)
        log.undo()
        #expect(Generala.total(of: 1, in: log.entries) == 16)
        log.undo()
        #expect(Generala.total(of: 1, in: log.entries) == 12)
        log.undo()
        #expect(log.entries.isEmpty)
    }

    @Test func clearingAnEmptyCellDoesNothing() {
        var log = EntryLog<Generala.Entry>()

        Generala.place(nil, in: .twos, of: 0, log: &log)

        #expect(!log.canUndo)
    }

    // MARK: - Turns

    @Test func theTurnStartsWithTheFirstPlayerAndPassesWhenTheOneRollingScores() {
        #expect(Generala.turn(participantCount: 3, entries: []) == 0)
        #expect(Generala.turn(participantCount: 3, entries: [entry(0, .ones, 3)]) == 1)
        #expect(Generala.turn(participantCount: 3, entries: [entry(0, .ones, 3), scratch(1, .twos)]) == 2)
        #expect(Generala.turn(participantCount: 3, entries: [entry(0, .ones, 3), scratch(1, .twos), entry(2, .sixes, 12)]) == 0)
    }

    @Test func scoringInAnotherPlayersColumnDoesNotMoveTheTurn() {
        let entries = [entry(0, .ones, 3), entry(0, .twos, 6)]

        // Player 1 is rolling, but Player 0's column gets a second cell.
        #expect(Generala.turn(participantCount: 3, entries: entries) == 1)
        #expect(Generala.turn(participantCount: 3, entries: [entry(0, .ones, 3), entry(2, .ones, 2)]) == 1)
    }

    @Test func theTurnSkipsWhoeverFilledTheirScoresheet() {
        let entries = filled(1) + [entry(0, .ones, 3)]

        #expect(Generala.turn(participantCount: 3, entries: entries) == 2)
        // Back to the first one with free categories.
        #expect(Generala.turn(participantCount: 3, entries: entries + [entry(2, .twos, 4)]) == 0)
    }

    @Test func theTurnComesBackToAPlayerWhoStillHasFreeCategories() {
        // Player 1 is done; with 2 Players the Turn alternates only to Player 0.
        let entries = filled(1) + [entry(0, .ones, 1), entry(0, .twos, 2)]

        #expect(Generala.turn(participantCount: 2, entries: entries) == 0)
    }

    @Test func theTurnIsNilWhenEveryoneIsDone() {
        #expect(Generala.turn(participantCount: 2, entries: filled(0) + filled(1)) == nil)
    }

    // MARK: - The end and the tie

    @Test func theMatchEndsWhenEveryoneHasFilledTheir11Categories() {
        let almost = filled(0) + filled(1, except: [.sixes])
        let ended = almost + [entry(1, .sixes, 30)]

        #expect(!Generala.outcome(variant: on, participantCount: 2, entries: almost).isFinished)
        #expect(Generala.outcome(variant: on, participantCount: 2, entries: ended) == Outcome(scores: [0, 30], isFinished: true, winners: [1]))
    }

    @Test func aTieForFirstPlaceIsShared() {
        let entries = filled(0, except: [.sixes]) + filled(1, except: [.sixes]) + filled(2, except: [.sixes])
            + [entry(0, .sixes, 24), entry(1, .sixes, 24), entry(2, .sixes, 6)]
        let outcome = Generala.outcome(variant: on, participantCount: 3, entries: entries)

        #expect(outcome.isFinished)
        #expect(outcome.winners == [0, 1])
        #expect(outcome.positions() == [1, 1, 3])
    }

    @Test func entriesOfPlayersWhoAreNotInTheMatchAreIgnored() {
        let outcome = Generala.outcome(variant: on, participantCount: 2, entries: [entry(5, .ones, 5)])

        #expect(outcome == .inProgress([0, 0]))
    }

    // MARK: - Starting

    @Test func aMatchNeedsBetween2And6Players() {
        func drafts(_ count: Int) -> [ParticipantDraft] {
            (0..<count).map { _ in ParticipantDraft(players: [Player(name: "x")]) }
        }

        #expect(!Generala.canStart(with: drafts(0)))
        #expect(!Generala.canStart(with: drafts(1)))
        #expect(Generala.canStart(with: drafts(2)))
        #expect(Generala.canStart(with: drafts(6)))
        #expect(!Generala.canStart(with: drafts(7)))
    }

    @Test func theStandardSetupIsAnEmptyListWithTheOptionOn() {
        #expect(Generala.standardVariant == .standard)
        #expect(Generala.standardVariant.servedGeneralaWins)
        #expect(Generala.initialParticipants.isEmpty)
        #expect(GameCatalog.rules(for: .generala) is Generala.Type)
    }
}

@MainActor
struct GeneralaMatchTests {
    private func makeContext() throws -> ModelContext {
        ModelContext(try Store.container(inMemory: true))
    }

    private func players(_ names: [String], in context: ModelContext) -> [Player] {
        names.map { name in
            let player = Player(name: name)
            context.insert(player)
            return player
        }
    }

    @Test func aMatchIsPlayedToTheEndAndUndoReopensIt() throws {
        let context = try makeContext()
        let people = players(["Ana", "Beto"], in: context)
        let match = try Match.create(Generala.self, variant: .standard, participants: people.map { .player($0) }, in: context)

        for category in Generala.Category.allCases {
            try match.modify(Generala.self) { Generala.place(.points(5), in: category, of: 0, log: &$0) }
            #expect(match.status == .inProgress)
        }
        for category in Generala.Category.allCases {
            try match.modify(Generala.self) { Generala.place(.scratched, in: category, of: 1, log: &$0) }
        }
        #expect(match.status == .finished)
        #expect(try match.outcome(Generala.self).winners == [0])

        try match.undo(Generala.self)
        #expect(match.status == .inProgress)
    }

    @Test func aServedGeneralaEndsTheMatchAndTheVariantChangeIsAllowedOnlyIfItDoesNot() throws {
        let context = try makeContext()
        let people = players(["Ana", "Beto", "Caro"], in: context)
        let match = try Match.create(
            Generala.self,
            variant: Generala.Variant(servedGeneralaWins: false),
            participants: people.map { .player($0) },
            in: context
        )
        try match.modify(Generala.self) { Generala.place(.points(55), served: true, in: .generala, of: 2, log: &$0) }

        #expect(match.status == .inProgress)
        #expect(!match.allows(.standard, Generala.self))

        try match.modify(Generala.self) { $0.undo() }
        #expect(match.allows(.standard, Generala.self))
        try match.changeVariant(Generala.self, to: .standard)
        try match.modify(Generala.self) { Generala.place(.points(50), served: true, in: .generala, of: 2, log: &$0) }
        #expect(match.status == .finished)
        #expect(try match.outcome(Generala.self).winners == [2])
    }

    @Test func endingEarlyGivesTheWinToWhoeverLeads() throws {
        let context = try makeContext()
        let people = players(["Ana", "Beto"], in: context)
        let match = try Match.create(Generala.self, variant: .standard, participants: people.map { .player($0) }, in: context)
        try match.modify(Generala.self) { Generala.place(.points(30), in: .fullHouse, of: 1, log: &$0) }

        try match.endEarly()

        #expect(match.endedEarly)
        #expect(try match.outcome(Generala.self).winners == [1])
    }

    @Test func aRematchKeepsTheOrderAndTheVariant() throws {
        let context = try makeContext()
        let people = players(["Ana", "Beto", "Caro"], in: context)
        let variant = Generala.Variant(servedGeneralaWins: false)
        let match = try Match.create(Generala.self, variant: variant, participants: people.map { .player($0) }, in: context)

        let next = try #require(try match.startRematch(Generala.self))

        #expect(next.orderedParticipants.map(\.name) == ["Ana", "Beto", "Caro"])
        #expect(try next.variant(Generala.self) == variant)
    }

    @Test func aRematchWithoutADeletedPlayerStartsIfTwoAreLeft() throws {
        let context = try makeContext()
        let people = players(["Ana", "Beto", "Caro"], in: context)
        let match = try Match.create(Generala.self, variant: .standard, participants: people.map { .player($0) }, in: context)
        try people[1].delete()

        let next = try #require(try match.startRematch(Generala.self))

        #expect(next.orderedParticipants.map(\.name) == ["Ana", "Caro"])
    }
}
