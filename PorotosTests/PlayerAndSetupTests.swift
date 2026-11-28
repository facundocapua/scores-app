import Foundation
import SwiftData
import Testing
import UIKit
@testable import Porotos

@MainActor
struct PlayerTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try Store.container(inMemory: true)
    }

    private func match(with players: [Player]) throws -> Match {
        try Match.create(
            SumGame.self,
            variant: .init(target: 10),
            participants: players.map { .player($0) },
            in: context
        )
    }

    @Test func renamingAPlayerShowsInTheirMatches() throws {
        let ana = Player(name: "Ana")
        context.insert(ana)
        let match = try match(with: [ana])

        ana.name = "Anita"
        #expect(match.orderedParticipants.first?.name == "Anita")
    }

    @Test func deletingAPlayerKeepsTheirLastNameInTheirMatches() throws {
        let ana = Player(name: "Ana")
        let beto = Player(name: "Beto")
        context.insert(ana)
        context.insert(beto)
        let inProgress = try match(with: [ana, beto])
        let finished = try match(with: [ana, beto])
        try finished.endEarly()

        ana.name = "Anita"
        try ana.delete()

        #expect(try context.fetchCount(FetchDescriptor<Player>()) == 1)
        for match in [inProgress, finished] {
            let seat = try #require(match.orderedParticipants.first?.orderedSeats.first)
            #expect(seat.player == nil)
            #expect(seat.name == "Anita")
        }
    }
}

@MainActor
struct RememberedSetupTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try Store.container(inMemory: true)
    }

    @Test func theFirstTimeItProposesTheStandardValues() throws {
        let setup = try RememberedSetup.last(SumGame.self, in: context)

        #expect(setup.variant == SumGame.standardVariant)
        #expect(setup.participants == SumGame.initialParticipants)
    }

    @Test func itProposesTheLatestMatchOfThatGame() throws {
        let ana = Player(name: "Ana")
        context.insert(ana)
        try Match.create(
            SumGame.self, variant: .init(target: 15),
            participants: [.team("A"), .team("B")], in: context,
            date: Date(timeIntervalSince1970: 100)
        )
        try Match.create(
            SumGame.self, variant: .init(target: 30),
            participants: [.team("Los de acá", players: [ana]), .team("Ellos")], in: context,
            date: Date(timeIntervalSince1970: 200)
        )
        try Match.create(
            OtherGame.self, variant: .init(option: false),
            participants: [], in: context,
            date: Date(timeIntervalSince1970: 300)
        )

        let setup = try RememberedSetup.last(SumGame.self, in: context)
        #expect(setup.variant == .init(target: 30))
        #expect(setup.participants == [.team("Los de acá", players: [ana]), .team("Ellos")])
        #expect(try RememberedSetup.last(OtherGame.self, in: context).variant == .init(option: false))
    }

    @Test func aDiscardedMatchIsNoLongerRemembered() throws {
        try Match.create(
            SumGame.self, variant: .init(target: 15),
            participants: SumGame.initialParticipants, in: context,
            date: Date(timeIntervalSince1970: 100)
        )
        let discarded = try Match.create(
            SumGame.self, variant: .init(target: 30),
            participants: SumGame.initialParticipants, in: context,
            date: Date(timeIntervalSince1970: 200)
        )
        try discarded.delete()

        #expect(try RememberedSetup.last(SumGame.self, in: context).variant == .init(target: 15))
    }

    @Test func aDeletedPlayerLeavesAnEmptySeat() throws {
        let ana = Player(name: "Ana")
        let beto = Player(name: "Beto")
        context.insert(ana)
        context.insert(beto)
        try Match.create(
            SumGame.self, variant: .init(target: 10),
            participants: [.player(ana), .player(beto)], in: context
        )
        try ana.delete()

        let setup = try RememberedSetup.last(SumGame.self, in: context)
        #expect(setup.participants == [.player(nil), .player(beto)])
        #expect(setup.participants[0].hasEmptySeats)
    }
}

@MainActor
struct DisplayFontTests {
    @Test(arguments: DisplayFont.allCases)
    func displayFontsAreBundled(font: DisplayFont) {
        #expect(UIFont(name: font.rawValue, size: 12) != nil)
    }
}
