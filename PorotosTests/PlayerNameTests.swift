import Foundation
import SwiftData
import Testing
@testable import Porotos

struct PlayerNameTests {
    @Test(arguments: [
        ("Ángel ", "angel"),
        ("  FACU", "facu"),
        ("María José", "maria jose"),
        ("Ñoño", "ñoño"),
    ])
    func namesAreComparedIgnoringCaseAccentsAndSurroundingSpaces(lhs: String, rhs: String) {
        #expect(PlayerName.isSame(lhs, rhs))
    }

    @Test func differentNamesAreDifferent() {
        #expect(!PlayerName.isSame("Ana", "Anita"))
        #expect(!PlayerName.isSame("Ana María", "AnaMaría"))
    }

    @Test func aValidNameIsSavedWithoutSurroundingSpaces() {
        #expect(PlayerName.validate("  Caro ", existing: ["Facu"]) == .success("Caro"))
    }

    @Test func anEmptyNameIsRejected() {
        #expect(PlayerName.validate("   ", existing: []) == .failure(.empty))
    }

    @Test func aNameUpToTwentyCharactersIsAccepted() {
        let twenty = String(repeating: "a", count: 20)
        #expect(PlayerName.validate(twenty, existing: []) == .success(twenty))
        #expect(PlayerName.validate(twenty + "a", existing: []) == .failure(.tooLong))
        #expect(PlayerName.limited(twenty + "abc") == twenty)
    }

    @Test func aTakenNameIsRejected() {
        #expect(PlayerName.validate("angel", existing: ["Facu", "Ángel"]) == .failure(.taken("Ángel")))
    }

    @Test func searchingIgnoresCaseAndAccents() {
        #expect(PlayerName.matches("Ángela", query: "ange"))
        #expect(PlayerName.matches("Facu", query: ""))
        #expect(!PlayerName.matches("Facu", query: "caro"))
    }
}

@MainActor
struct PlayerDirectoryTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try Store.container(inMemory: true)
    }

    @Test func addingATakenNameFails() throws {
        try Player.add(named: "Ángel", in: context)

        #expect(throws: PlayerNameError.taken("Ángel")) {
            try Player.add(named: " angel", in: context)
        }
        #expect(try context.fetchCount(FetchDescriptor<Player>()) == 1)
        #expect(try Player.named("ANGEL", in: context)?.name == "Ángel")
    }

    @Test func renamingToAnotherPlayersNameFails() throws {
        try Player.add(named: "Ana", in: context)
        let beto = try Player.add(named: "Beto", in: context)

        #expect(beto.renameProblem("ana") == .taken("Ana"))
        #expect(throws: PlayerNameError.taken("Ana")) { try beto.rename(to: "ana") }
        #expect(beto.name == "Beto")
    }

    @Test func aPlayerCanBeRenamedToTheirOwnNameWithAnotherCase() throws {
        let beto = try Player.add(named: "beto", in: context)

        #expect(beto.renameProblem("Beto ") == nil)
        try beto.rename(to: "Beto ")
        #expect(beto.name == "Beto")
    }

    @Test func playersAreListedAlphabetically() throws {
        for name in ["beto", "Ángel", "Caro", "ana"] {
            try Player.add(named: name, in: context)
        }

        #expect(try Player.alphabetical(in: context).map(\.name) == ["ana", "Ángel", "beto", "Caro"])
    }

    @Test func thePickerShowsWhoPlayedMostRecentlyFirst() throws {
        let ana = try Player.add(named: "Ana", in: context)
        let beto = try Player.add(named: "Beto", in: context)
        let caro = try Player.add(named: "Caro", in: context)
        try Player.add(named: "Dani", in: context)
        try Match.create(
            SumGame.self, variant: .init(target: 10),
            participants: [.player(caro), .player(ana)], in: context,
            date: Date(timeIntervalSince1970: 100)
        )
        try Match.create(
            SumGame.self, variant: .init(target: 10),
            participants: [.player(beto), .player(ana)], in: context,
            date: Date(timeIntervalSince1970: 200)
        )

        let ordered = try Player.byMostRecentlyPlayed(in: context).map(\.name)
        #expect(ordered == ["Ana", "Beto", "Caro", "Dani"])
    }

    @Test func aPlayerInAMatchInProgressIsFlagged() throws {
        let ana = try Player.add(named: "Ana", in: context)
        let beto = try Player.add(named: "Beto", in: context)
        let finished = try Match.create(
            SumGame.self, variant: .init(target: 10),
            participants: [.player(beto)], in: context
        )
        try finished.endEarly()
        try Match.create(
            SumGame.self, variant: .init(target: 10),
            participants: [.player(ana)], in: context
        )

        #expect(ana.isPlayingMatchInProgress)
        #expect(!beto.isPlayingMatchInProgress)
    }
}

@MainActor
struct PlayerPickerOptionsTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let players: [Player]

    init() throws {
        container = try Store.container(inMemory: true)
        let context = container.mainContext
        players = try ["Facu", "Caro", "Ángela", "Beto"].map { try Player.add(named: $0, in: context) }
    }

    private func player(_ name: String) -> Player {
        players.first { $0.name == name }!
    }

    @Test func withoutSearchItShowsEveryoneNotYetChosen() {
        let options = PlayerPickerOptions(players: players, query: "", excluded: [player("Caro").persistentModelID])

        #expect(options.players.map(\.name) == ["Facu", "Ángela", "Beto"])
        #expect(options.nameToAdd == nil)
    }

    @Test func aNewNameIsOfferedToAdd() {
        let options = PlayerPickerOptions(players: players, query: " Juli ", excluded: [])

        #expect(options.players.isEmpty)
        #expect(options.nameToAdd == "Juli")
    }

    @Test func aPartialNameFiltersAndOffersToAdd() {
        let options = PlayerPickerOptions(players: players, query: "ange", excluded: [])

        #expect(options.players.map(\.name) == ["Ángela"])
        #expect(options.nameToAdd == "ange")
    }

    @Test func aTakenNameOffersTheExistingPlayerFirst() {
        let ange = try! Player.add(named: "Ange", in: context)
        let options = PlayerPickerOptions(players: players + [ange], query: "ÁNGE ", excluded: [])

        #expect(options.players.map(\.name) == ["Ange", "Ángela"])
        #expect(options.nameToAdd == nil)
    }

    @Test func aTakenNameOfAChosenPlayerIsNotOfferedAgain() {
        let options = PlayerPickerOptions(players: players, query: "beto", excluded: [player("Beto").persistentModelID])

        #expect(options.players.isEmpty)
        #expect(options.nameToAdd == nil)
    }

    @Test func theTypedNameIsCutToTwentyCharacters() {
        let options = PlayerPickerOptions(players: players, query: String(repeating: "x", count: 25), excluded: [])

        #expect(options.nameToAdd == String(repeating: "x", count: 20))
    }
}
