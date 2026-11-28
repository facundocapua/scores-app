import Foundation
import SwiftData
import Testing
@testable import Porotos

struct TrucoRulesTests {
    private func points(_ pairs: [(team: Int, points: Int)]) -> [Truco.Entry] {
        pairs.map { Truco.Entry(team: $0.team, points: $0.points) }
    }

    private func repeated(_ team: Int, _ count: Int, points: Int = 1) -> [Truco.Entry] {
        Array(repeating: Truco.Entry(team: team, points: points), count: count)
    }

    @Test(arguments: [15, 30])
    func reachingTheTargetEndsTheMatch(target: Int) {
        let variant = Truco.Variant(target: target)
        let almost = repeated(0, target - 1) + repeated(1, 10)

        #expect(Truco.outcome(variant: variant, participantCount: 2, entries: almost) == .inProgress([target - 1, 10]))
        let ended = Truco.outcome(variant: variant, participantCount: 2, entries: almost + repeated(0, 1))
        #expect(ended == Outcome(scores: [target, 10], isFinished: true, winners: [0]))
    }

    @Test func theScoreCannotBeExceeded() {
        let outcome = Truco.outcome(variant: .to15, participantCount: 2, entries: repeated(1, 20))

        #expect(outcome.scores == [0, 15])
        #expect(!Truco.canAdd(to: 15, variant: .to15))
        #expect(Truco.canAdd(to: 15, variant: .to30))
    }

    @Test func subtractingStopsAtZero() {
        let entries = repeated(0, 2) + repeated(0, 3, points: -1) + repeated(0, 1)

        #expect(Truco.outcome(variant: .to30, participantCount: 2, entries: entries).scores == [1, 0])
        #expect(!Truco.canSubtract(from: 0))
        #expect(Truco.canSubtract(from: 1))
    }

    @Test func aMinusOneTakesAPointBack() {
        let entries = points([(0, 1), (0, 1), (1, 1), (0, -1)])

        #expect(Truco.outcome(variant: .to30, participantCount: 2, entries: entries).scores == [1, 1])
    }

    @Test func goingTo15IsDisabledWhenATeamHas15OrMore() {
        #expect(!Truco.allows(.to15, participantCount: 2, entries: repeated(0, 15)))
        #expect(Truco.allows(.to15, participantCount: 2, entries: repeated(0, 14)))
        #expect(Truco.allows(.to30, participantCount: 2, entries: repeated(0, 14)))
    }

    @Test func theStandardSetupIsNosotrosAgainstEllosTo30() {
        #expect(Truco.standardVariant == .to30)
        #expect(Truco.initialParticipants == [.team("Nosotros"), .team("Ellos")])
        #expect(Truco.canStart(with: Truco.initialParticipants))
        #expect(Truco.defaultTeamName(at: 1, players: []) == "Ellos")
    }
}

struct TrucoTallyTests {
    @Test func to30TheScoreIsSplitIntoMalasAndBuenas() {
        #expect(TrucoTally(score: 12, variant: .to30).buenas == 0)
        let tally = TrucoTally(score: 17, variant: .to30)
        #expect(tally.malas == 15)
        #expect(tally.buenas == 2)
    }

    @Test func to15ThereIsASingleBlock() {
        let tally = TrucoTally(score: 13, variant: .to15)
        #expect(tally.malas == 13)
        #expect(tally.buenas == 0)
    }

    @Test func matchsticksGroupInFives() {
        #expect(TrucoTally.groups(0) == [])
        #expect(TrucoTally.groups(5) == [5])
        #expect(TrucoTally.groups(12) == [5, 5, 2])
        #expect(TrucoTally.groups(15) == [5, 5, 5])
    }

    @Test func voiceOverReadsTheTotalAndTheHalf() {
        #expect(TrucoTally(score: 17, variant: .to30).spokenValue(score: 17, variant: .to30) == "17, buenas 2")
        #expect(TrucoTally(score: 9, variant: .to30).spokenValue(score: 9, variant: .to30) == "9, malas 9")
        #expect(TrucoTally(score: 9, variant: .to15).spokenValue(score: 9, variant: .to15) == "9")
    }
}

struct TeamNameTests {
    @Test func aClearedNameGoesBackToTheDefault() {
        #expect(TeamName.resolved("   ", default: "Nosotros") == "Nosotros")
        #expect(TeamName.resolved(" Los de acá ", default: "Nosotros") == "Los de acá")
    }

    @Test func aNameIsUpTo30Characters() {
        let long = String(repeating: "a", count: 35)
        #expect(TeamName.resolved(long, default: "Ellos").count == 30)
    }
}

@MainActor
struct TrucoMatchTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try Store.container(inMemory: true)
    }

    private func newMatch(_ variant: Truco.Variant = .to30, participants: [ParticipantDraft] = Truco.initialParticipants) throws -> Match {
        try Match.create(Truco.self, variant: variant, participants: participants, in: context)
    }

    private func add(_ count: Int, to team: Int, in match: Match) throws {
        for _ in 0..<count {
            try match.modify(Truco.self) { $0.add(.init(team: team, points: 1)) }
        }
    }

    @Test func theMatchEndsByItselfAndUndoReopensIt() throws {
        let match = try newMatch(.to15)
        try add(15, to: 1, in: match)
        #expect(match.status == .finished)
        #expect(try match.outcome(Truco.self).winners == [1])

        try match.undo(Truco.self)
        #expect(match.status == .inProgress)
        #expect(try match.outcome(Truco.self).scores == [0, 14])
    }

    @Test func endedEarlyWithATieSharesTheWin() throws {
        let match = try newMatch()
        try add(8, to: 0, in: match)
        try add(8, to: 1, in: match)
        try match.endEarly()

        #expect(match.status == .finished)
        #expect(try match.outcome(Truco.self).winners == [0, 1])
    }

    @Test func undoOnTheEndOfAMatchThatEndedEarlyOnlyResumesIt() throws {
        let match = try newMatch()
        try add(3, to: 0, in: match)
        try match.endEarly()
        #expect(match.canUndo(Truco.self))

        try match.undo(Truco.self)
        #expect(match.status == .inProgress)
        #expect(!match.endedEarly)
        #expect(try match.outcome(Truco.self).scores == [3, 0])
    }

    @Test func theVariantCantChangeToOneThatWouldEndTheMatch() throws {
        let match = try newMatch()
        try add(15, to: 0, in: match)

        #expect(!match.allows(Truco.Variant.to15, Truco.self))
        try match.undo(Truco.self)
        #expect(match.allows(Truco.Variant.to15, Truco.self))
        try match.changeVariant(Truco.self, to: .to15)
        #expect(match.status == .inProgress)
    }

    @Test func aClearedTeamNameGoesBackToTheDefault() throws {
        let match = try newMatch()
        try match.renameTeam(at: 0, to: "Los de acá", Truco.self)
        #expect(match.orderedParticipants[0].name == "Los de acá")

        try match.renameTeam(at: 0, to: "  ", Truco.self)
        #expect(match.orderedParticipants[0].name == "Nosotros")
    }

    @Test func rematchStartsWithTheSameTeamsAndVariantWithoutDeletedPlayers() throws {
        let ana = try Player.add(named: "Ana", in: context)
        let beto = try Player.add(named: "Beto", in: context)
        let match = try newMatch(.to15, participants: [.team("Los de acá", players: [ana, beto]), .team("Ellos")])
        try add(15, to: 0, in: match)
        try beto.delete()

        let rematch = try #require(try match.startRematch(Truco.self))
        #expect(rematch !== match)
        #expect(rematch.status == .inProgress)
        #expect(try rematch.variant(Truco.self) == .to15)
        #expect(rematch.orderedParticipants.map(\.name) == ["Los de acá", "Ellos"])
        #expect(rematch.orderedParticipants[0].orderedSeats.map(\.name) == ["Ana"])
    }

    @Test func homeListsTheMatchesInProgressLastScoredFirst() throws {
        let first = try newMatch()
        let second = try newMatch()
        let finished = try newMatch(.to15)
        try add(15, to: 0, in: finished)
        try first.modify(Truco.self, date: .now.addingTimeInterval(60)) { $0.add(.init(team: 0, points: 1)) }

        #expect(try Match.inProgress(in: context).map(\.id) == [first.id, second.id])
    }

    @Test func killingTheAppMidMatchLosesNothing() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Porotos.store")

        do {
            let container = try Store.container(url: url)
            let match = try Match.create(Truco.self, variant: .to30, participants: Truco.initialParticipants, in: container.mainContext)
            try match.modify(Truco.self) { $0.add(.init(team: 0, points: 1)) }
            try match.modify(Truco.self) { $0.add(.init(team: 1, points: 1)) }
            try match.renameTeam(at: 1, to: "Los otros", Truco.self)
        }

        let container = try Store.container(url: url)
        let match = try #require(try Match.inProgress(in: container.mainContext).first)
        #expect(try match.outcome(Truco.self).scores == [1, 1])
        #expect(match.orderedParticipants.map(\.name) == ["Nosotros", "Los otros"])
        try match.undo(Truco.self)
        #expect(try match.outcome(Truco.self).scores == [1, 0])
    }
}

struct OutcomePositionsTests {
    @Test func tiesShareThePositionAndTheNextOneSkips() {
        let outcome = Outcome(scores: [30, 50, 50, 10], isFinished: true, winners: [1, 2])
        #expect(outcome.positions() == [3, 1, 1, 4])
        #expect(outcome.positions(lowerIsBetter: true) == [2, 3, 3, 1])
        #expect(Outcome.ordinal(1) == "1.º")
    }
}
