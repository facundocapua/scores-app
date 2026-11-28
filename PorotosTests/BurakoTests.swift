import Foundation
import SwiftData
import Testing
@testable import Porotos

private let standard = Burako.Variant(target: 3000, muerto: .addsAndSubtracts)

/// A Hand where `lines` are the Participants' Lines, in order.
private func hand(_ lines: Burako.Line...) -> Burako.Hand {
    var hand = Burako.Hand(participantCount: lines.count)
    hand.lines = lines
    return hand
}

/// A Line whose result is exactly `points` with the "Suma y resta" Muerto taken (+100).
private func line(scoring points: Int) -> Burako.Line {
    Burako.Line(tilesMelded: max(points - 100, 0), tilesInHand: max(100 - points, 0), tookMuerto: true)
}

struct BurakoHandResultTests {
    @Test func theResultAddsCanastasAndTilesAndSubtractsTilesInHand() {
        let line = Burako.Line(cleanCanastas: 2, dirtyCanastas: 1, tilesMelded: 140, tilesInHand: 35, wentOut: true, tookMuerto: true)
        // 400 + 100 + 140 - 35 + 100 (went out) + 100 (muerto)
        #expect(line.result(standard) == 805)
    }

    @Test func addsAndSubtractsAddsWhenTakenAndSubtractsWhenNot() {
        let taken = Burako.Line(tookMuerto: true)
        let notTaken = Burako.Line(tookMuerto: false)
        #expect(taken.result(.init(target: 3000, muerto: .addsAndSubtracts)) == 100)
        #expect(notTaken.result(.init(target: 3000, muerto: .addsAndSubtracts)) == -100)
    }

    @Test func subtractsOnlyIsZeroWhenTakenAndSubtractsWhenNot() {
        let variant = Burako.Variant(target: 3000, muerto: .subtractsOnly)
        #expect(Burako.Line(tookMuerto: true).result(variant) == 0)
        #expect(Burako.Line(tookMuerto: false).result(variant) == -100)
    }

    @Test func addsOnlyAddsWhenTakenAndIsZeroWhenNot() {
        let variant = Burako.Variant(target: 3000, muerto: .addsOnly)
        #expect(Burako.Line(tookMuerto: true).result(variant) == 100)
        #expect(Burako.Line(tookMuerto: false).result(variant) == 0)
    }

    @Test func theMuertoOptionChangesTheSameHandInPairsToo() {
        // A pair enters one Tiles melded and one Tiles in hand number for both partners.
        let pair = Burako.Line(cleanCanastas: 1, dirtyCanastas: 2, tilesMelded: 260, tilesInHand: 45, tookMuerto: false)
        #expect(pair.result(.init(target: 3000, muerto: .addsAndSubtracts)) == 515)  // 200+200+260-45-100
        #expect(pair.result(.init(target: 3000, muerto: .subtractsOnly)) == 515)
        #expect(pair.result(.init(target: 3000, muerto: .addsOnly)) == 615)
    }

    @Test func nothingIsValidatedSoWentOutWorksWithoutCanastasAndTotalsCanBeNegative() {
        let line = Burako.Line(tilesInHand: 150, wentOut: true)
        #expect(line.result(standard) == -150)  // 100 - 150 - 100
    }

    @Test func atMostOneParticipantGoesOut() {
        #expect(hand(.init(wentOut: true), .init(), .init()).isValid)
        #expect(hand(.init(), .init()).isValid)
        #expect(!hand(.init(wentOut: true), .init(wentOut: true)).isValid)
    }
}

struct BurakoRulesTests {
    @Test func totalsAddUpHandByHand() {
        let hands = [hand(line(scoring: 500), line(scoring: 300)), hand(line(scoring: -200), line(scoring: 700))]
        let outcome = Burako.outcome(variant: standard, participantCount: 2, entries: hands)
        #expect(outcome == .inProgress([300, 1000]))
    }

    @Test func theMatchEndsOnTheHandWhereSomeoneReachesTheTarget() {
        let hands = [hand(line(scoring: 2900), line(scoring: 1000)), hand(line(scoring: 100), line(scoring: 50))]
        let outcome = Burako.outcome(variant: standard, participantCount: 2, entries: hands)
        #expect(outcome == Outcome(scores: [3000, 1050], isFinished: true, winners: [0]))
    }

    @Test func thePlayerWithTheHighestTotalWinsEvenIfAnotherAlsoPassedTheTarget() {
        let hands = [hand(line(scoring: 3100), line(scoring: 3400), line(scoring: 200))]
        let outcome = Burako.outcome(variant: standard, participantCount: 3, entries: hands)
        #expect(outcome.winners == [1])
        #expect(outcome.isFinished)
    }

    @Test func aTieAtTheTopIsBrokenByAnotherHand() {
        let tied = hand(line(scoring: 3000), line(scoring: 3000))
        let inProgress = Burako.outcome(variant: standard, participantCount: 2, entries: [tied])
        #expect(inProgress == .inProgress([3000, 3000]))

        let tiebreak = hand(line(scoring: 150), line(scoring: 120))
        let finished = Burako.outcome(variant: standard, participantCount: 2, entries: [tied, tiebreak])
        #expect(finished == Outcome(scores: [3150, 3120], isFinished: true, winners: [0]))
    }

    @Test func aTieAtTheTopSurvivesSeveralHandsUntilItIsBroken() {
        let tied = hand(line(scoring: 3000), line(scoring: 3000))
        let sameAgain = hand(line(scoring: 100), line(scoring: 100))
        let outcome = Burako.outcome(variant: standard, participantCount: 2, entries: [tied, sameAgain])
        #expect(outcome == .inProgress([3100, 3100]))
    }

    @Test func aTieBelowTheTargetDoesNotEndAnything() {
        let outcome = Burako.outcome(variant: standard, participantCount: 2, entries: [hand(line(scoring: 500), line(scoring: 500))])
        #expect(!outcome.isFinished)
    }

    @Test func totalsCanBeNegative() {
        let outcome = Burako.outcome(variant: standard, participantCount: 2, entries: [hand(line(scoring: -350), line(scoring: 40))])
        #expect(outcome == .inProgress([-350, 40]))
    }

    @Test func aLowerTargetEndsTheMatchSoItIsNotAllowedMidMatch() {
        let hands = [hand(line(scoring: 1800), line(scoring: 900))]
        #expect(Burako.canSetTarget(2000, scores: [1800, 900]))
        #expect(!Burako.canSetTarget(1800, scores: [1800, 900]))
        #expect(!Burako.canSetTarget(1500, scores: [1800, 900]))
        #expect(Burako.allows(.init(target: 2000, muerto: .addsAndSubtracts), participantCount: 2, entries: hands))
        #expect(!Burako.allows(.init(target: 1500, muerto: .addsAndSubtracts), participantCount: 2, entries: hands))
    }

    @Test func aFreeTargetHasToBeInRange() {
        #expect(Burako.Variant.isValidTarget(1500))
        #expect(!Burako.Variant.isValidTarget(0))
        #expect(!Burako.Variant.isValidTarget(1_000_000))
    }

    // MARK: Correcting (SPEC §6.1)

    private let earlier = [
        hand(line(scoring: 1000), line(scoring: 900)),
        hand(line(scoring: 1000), line(scoring: 900)),
        hand(line(scoring: 900), line(scoring: 800)),
    ]

    @Test func aCorrectionThatEndsTheMatchBeforeTheLastHandIsRejected() {
        // Raising Hand 1 to 3000 would leave Participant 0 at the Target after Hand 1.
        let corrected = hand(line(scoring: 3000), line(scoring: 900))
        #expect(!Burako.canCorrect(handAt: 0, to: corrected, variant: standard, participantCount: 2, entries: earlier))
    }

    @Test func aCorrectionThatDoesNotMoveTheEndIsAccepted() {
        let corrected = hand(line(scoring: 1100), line(scoring: 900))
        #expect(Burako.canCorrect(handAt: 0, to: corrected, variant: standard, participantCount: 2, entries: earlier))
    }

    @Test func aCorrectionThatEndsTheMatchOnTheLastHandIsAccepted() {
        let corrected = hand(line(scoring: 1100), line(scoring: 900))
        // 1000 + 1000 + 1100 = 3100 on the last Hand: the Match ends there.
        #expect(Burako.canCorrect(handAt: 2, to: corrected, variant: standard, participantCount: 2, entries: earlier))
    }

    @Test func aCorrectionWithTwoParticipantsGoingOutIsRejected() {
        let corrected = hand(.init(wentOut: true), .init(wentOut: true))
        #expect(!Burako.canCorrect(handAt: 0, to: corrected, variant: standard, participantCount: 2, entries: earlier))
    }

    @Test func endingHandIsNilWhileInProgress() {
        #expect(Burako.endingHand(variant: standard, participantCount: 2, entries: earlier) == nil)
    }

    // MARK: Participants and the setup

    private func players(_ names: String...) -> [Player] { names.map { Player(name: $0) } }

    @Test func individualNeedsTwoToFourPlayers() {
        let all = players("Facu", "Caro", "Juli", "Beto", "Ana")
        #expect(!Burako.canStart(with: [.player(all[0])]))
        #expect(Burako.canStart(with: all.prefix(2).map { .player($0) }))
        #expect(Burako.canStart(with: all.prefix(4).map { .player($0) }))
        #expect(!Burako.canStart(with: all.prefix(5).map { .player($0) }))
    }

    @Test func pairsNeedAllFourSpotsFilled() {
        let all = players("Facu", "Caro", "Juli", "Beto")
        #expect(Burako.canStart(with: [
            .team("Facu y Caro", players: [all[0], all[1]]),
            .team("Juli y Beto", players: [all[2], all[3]]),
        ]))
        #expect(!Burako.canStart(with: [
            .team("Facu y Caro", players: [all[0], all[1]]),
            .team("Juli", players: [all[2], nil]),
        ]))
        #expect(!Burako.canStart(with: Burako.initialParticipants))
    }

    @Test func theFirstTimeIsPairsWithEmptySpots() {
        #expect(Burako.isPairs(Burako.initialParticipants))
        #expect(Burako.initialParticipants.allSatisfy { $0.players == [nil, nil] })
        #expect(Burako.standardVariant == Burako.Variant(target: 3000, muerto: .addsAndSubtracts))
    }

    @Test func theTeamNameIsBuiltFromThePlayersAndCutToTheLimit() {
        #expect(Burako.defaultTeamName(at: 0, players: ["Facu", "Caro"]) == "Facu y Caro")
        #expect(Burako.defaultTeamName(at: 0, players: ["Facu"]) == "Facu")
        let long = String(repeating: "a", count: 20)
        #expect(Burako.defaultTeamName(at: 1, players: [long, long]).count == TeamName.maxLength)
    }

    @Test func totalsAreReadAsNumbers() {
        #expect(Burako.grouped(1240) == "1.240")
        #expect(Burako.grouped(-1240) == "-1.240")
        #expect(Burako.grouped(950) == "950")
        #expect(Burako.grouped(1_250_000) == "1.250.000")
        #expect(Burako.spokenTotal(score: 1240, target: 3000) == "1.240, faltan 1.760")
        #expect(Burako.spokenTotal(score: -200, target: 3000) == "menos 200, faltan 3.200")
        #expect(Burako.spokenTotal(score: 3100, target: 3000) == "3.100, faltan 0")
    }
}

@MainActor
struct BurakoMatchTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try Store.container(inMemory: true)
    }

    private func pairsMatch() throws -> Match {
        let names = ["Facu", "Caro", "Juli", "Beto"].map { Player(name: $0) }
        names.forEach(context.insert)
        return try Match.create(
            Burako.self,
            variant: standard,
            participants: [
                .team("Facu y Caro", players: [names[0], names[1]]),
                .team("Juli y Beto", players: [names[2], names[3]]),
            ],
            in: context
        )
    }

    @Test func aTiedMatchKeepsGoingAndFinishesWithTheTiebreak() throws {
        let match = try pairsMatch()
        try match.modify(Burako.self) { $0.add(hand(line(scoring: 3000), line(scoring: 3000))) }
        #expect(match.status == .inProgress)
        try match.modify(Burako.self) { $0.add(hand(line(scoring: 100), line(scoring: 200))) }
        #expect(match.status == .finished)
        #expect(try match.outcome(Burako.self).winners == [1])

        try match.undo(Burako.self)
        #expect(match.status == .inProgress)
    }

    @Test func aHandCanBeCorrectedInPlaceAndUndone() throws {
        let match = try pairsMatch()
        try match.modify(Burako.self) { $0.add(hand(line(scoring: 500), line(scoring: 300))) }
        try match.modify(Burako.self) { $0.edit(at: 0, with: hand(line(scoring: 600), line(scoring: 300))) }
        #expect(try match.outcome(Burako.self).scores == [600, 300])

        try match.undo(Burako.self)
        #expect(try match.outcome(Burako.self).scores == [500, 300])
    }

    @Test func changingTheMuertoRecomputesTheTotals() throws {
        let match = try pairsMatch()
        try match.modify(Burako.self) { $0.add(hand(.init(tookMuerto: false), .init(tookMuerto: true))) }
        #expect(try match.outcome(Burako.self).scores == [-100, 100])
        try match.changeVariant(Burako.self, to: .init(target: 3000, muerto: .addsOnly))
        #expect(try match.outcome(Burako.self).scores == [0, 100])
    }

    @Test func aRematchOfIndividualDropsADeletedPlayerAndStillStarts() throws {
        let players = ["Facu", "Caro", "Juli"].map { Player(name: $0) }
        players.forEach(context.insert)
        let match = try Match.create(Burako.self, variant: standard, participants: players.map { .player($0) }, in: context)
        context.delete(players[2])
        try context.save()

        let rematch = try #require(try match.startRematch(Burako.self))
        #expect(rematch.orderedParticipants.map(\.name) == ["Facu", "Caro"])
    }

    @Test func aRematchOfPairsWithAMissingPlayerOpensTheNewMatchScreen() throws {
        let match = try pairsMatch()
        let juli = try #require(try Player.named("Juli", in: context))
        context.delete(juli)
        try context.save()

        #expect(try match.startRematch(Burako.self) == nil)
        let setup = try match.rematchSetup(Burako.self)
        #expect(setup.participants[1].players.contains { $0 == nil })
        #expect(Burako.isPairs(setup.participants))
    }

    @Test func theRememberedSetupKeepsTheTargetAndTheMuerto() throws {
        let variant = Burako.Variant(target: 2500, muerto: .addsOnly)
        let players = ["Facu", "Caro"].map { Player(name: $0) }
        players.forEach(context.insert)
        try Match.create(Burako.self, variant: variant, participants: players.map { .player($0) }, in: context)

        let setup = try RememberedSetup.last(Burako.self, in: context)
        #expect(setup.variant == variant)
        #expect(setup.participants.map(\.teamName) == [nil, nil])
    }
}

/// Killing the app with a half-entered Hand and coming back restores it (SPEC §6.5).
@MainActor
struct BurakoDraftTests {
    @Test func theHalfEnteredHandSurvivesReopeningTheStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Porotos.store")

        var half = Burako.Draft(hand: Burako.Hand(participantCount: 2), participant: 1)
        half.hand.lines[0] = .init(cleanCanastas: 1, tilesMelded: 85, wentOut: true)
        half.hand.lines[1] = .init(dirtyCanastas: 2, tilesInHand: 30, tookMuerto: true)

        do {
            let container = try Store.container(url: url)
            let match = try Match.create(Burako.self, variant: standard, participants: [.team("Nosotros"), .team("Ellos")], in: container.mainContext)
            try match.modify(Burako.self) { $0.add(hand(line(scoring: 400), line(scoring: 250))) }
            try match.saveDraft(half)
        }

        let container = try Store.container(url: url)
        let match = try #require(try container.mainContext.fetch(FetchDescriptor<Match>()).first)
        #expect(try match.draft(Burako.Draft.self) == half)
        #expect(try match.outcome(Burako.self).scores == [400, 250])
    }

    @Test func theDraftIsClearedOnceTheHandIsScored() throws {
        let container = try Store.container(inMemory: true)
        let match = try Match.create(Burako.self, variant: standard, participants: [.team("Nosotros"), .team("Ellos")], in: container.mainContext)
        try match.saveDraft(Burako.Draft(hand: Burako.Hand(participantCount: 2), participant: 0))
        try match.saveDraft(Optional<Burako.Draft>.none)
        #expect(try match.draft(Burako.Draft.self) == nil)
    }
}
