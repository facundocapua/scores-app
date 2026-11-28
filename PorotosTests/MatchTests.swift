import Foundation
import SwiftData
import Testing
@testable import Porotos

@MainActor
struct MatchTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try Store.container(inMemory: true)
    }

    private func newMatch(target: Int = 10, date: Date = .now) throws -> Match {
        try Match.create(
            SumGame.self,
            variant: .init(target: target),
            participants: SumGame.initialParticipants,
            in: context,
            date: date
        )
    }

    private func add(_ points: Int, to participant: Int, in match: Match, date: Date = .now) throws {
        try match.modify(SumGame.self, date: date) {
            $0.add(.init(participant: participant, points: points))
        }
    }

    @Test func aNewMatchIsInProgressWithItsParticipantsInOrder() throws {
        let match = try newMatch()

        #expect(match.status == .inProgress)
        #expect(match.kind == .truco)
        #expect(match.orderedParticipants.map(\.name) == ["Nosotros", "Ellos"])
        #expect(try match.outcome(SumGame.self) == .inProgress([0, 0]))
    }

    @Test func reachingTheEndFinishesTheMatchAndUndoReopensIt() throws {
        let match = try newMatch(target: 5)
        let end = Date(timeIntervalSince1970: 1_000)
        try add(3, to: 0, in: match)
        try add(5, to: 1, in: match, date: end)

        #expect(match.status == .finished)
        #expect(match.finishedAt == end)
        #expect(try match.outcome(SumGame.self).winners == [1])

        try match.modify(SumGame.self) { $0.undo() }
        #expect(match.status == .inProgress)
        #expect(match.finishedAt == nil)
        #expect(try match.outcome(SumGame.self).scores == [3, 0])
    }

    @Test func everyChangeUpdatesTheLastEntryDate() throws {
        let match = try newMatch()
        let date = Date(timeIntervalSince1970: 5_000)
        try add(1, to: 0, in: match, date: date)

        #expect(match.lastEntryAt == date)
    }

    @Test func endingEarlyMakesTheLeadersWinWithSharedTies() throws {
        let match = try newMatch()
        try add(4, to: 0, in: match)
        try add(4, to: 1, in: match)
        try match.endEarly()

        #expect(match.status == .finished)
        #expect(match.endedEarly)
        #expect(try match.outcome(SumGame.self).winners == [0, 1])
    }

    @Test func resumingAMatchThatEndedEarlyKeepsItsEntries() throws {
        let match = try newMatch()
        try add(4, to: 0, in: match)
        try match.endEarly()
        try match.resume(SumGame.self)

        #expect(match.status == .inProgress)
        #expect(!match.endedEarly)
        #expect(match.finishedAt == nil)
        #expect(try match.outcome(SumGame.self).scores == [4, 0])
    }

    @Test func changingTheVariantRecomputesTheEnd() throws {
        let match = try newMatch(target: 30)
        try add(12, to: 0, in: match)
        try match.changeVariant(SumGame.self, to: .init(target: 10))

        #expect(match.status == .finished)
        #expect(try match.variant(SumGame.self) == .init(target: 10))
    }

    @Test func readingWithAnotherGamesRulesThrows() throws {
        let match = try newMatch()

        #expect(throws: MatchError.wrongGame(expected: .truco, got: .generala)) {
            try match.log(OtherGame.self)
        }
    }

    @Test func sharedScreensComputeWithoutKnowingTheGame() throws {
        let match = try newMatch()
        try add(2, to: 1, in: match)
        let rules: any GameRules.Type = SumGame.self

        #expect(try match.outcome(using: rules).scores == [0, 2])
    }

    @Test func theDraftIsSavedAndCleared() throws {
        let match = try newMatch()
        try match.saveDraft(["canastas": 2])
        #expect(try match.draft([String: Int].self) == ["canastas": 2])

        try match.saveDraft(Optional<[String: Int]>.none)
        #expect(try match.draft([String: Int].self) == nil)
    }

    @Test func deletingAMatchDeletesItsParticipantsButNotItsPlayers() throws {
        let ana = Player(name: "Ana")
        context.insert(ana)
        let match = try Match.create(
            SumGame.self,
            variant: .init(target: 10),
            participants: [.player(ana), .team("Ellos")],
            in: context
        )
        try match.delete()

        #expect(try context.fetchCount(FetchDescriptor<Match>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Participant>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Seat>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Player>()) == 1)
    }
}

/// Closing the app never loses a Match, and Undo keeps working afterwards (SPEC §6.5).
@MainActor
struct PersistenceTests {
    @Test func undoWorksAfterReopeningTheStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Porotos.store")

        do {
            let container = try Store.container(url: url)
            let match = try Match.create(
                SumGame.self,
                variant: .init(target: 30),
                participants: SumGame.initialParticipants,
                in: container.mainContext
            )
            try match.modify(SumGame.self) { $0.add(.init(participant: 0, points: 3)) }
            try match.modify(SumGame.self) { $0.add(.init(participant: 1, points: 4)) }
            try match.modify(SumGame.self) { $0.edit(at: 0, with: .init(participant: 0, points: 6)) }
            try match.saveDraft("half-entered hand")
        }

        let container = try Store.container(url: url)
        let match = try #require(try container.mainContext.fetch(FetchDescriptor<Match>()).first)
        #expect(try match.outcome(SumGame.self).scores == [6, 4])
        #expect(try match.draft(String.self) == "half-entered hand")

        try match.modify(SumGame.self) { $0.undo() }
        #expect(try match.outcome(SumGame.self).scores == [3, 4])
        try match.modify(SumGame.self) { $0.undo() }
        #expect(try match.outcome(SumGame.self).scores == [3, 0])
    }
}
