import Foundation
import SwiftData

/// Finding, adding and renaming Players with the name rules of `PlayerName` (SPEC §3.3).
extension Player {
    /// Every Player, in alphabetical order (the Players tab, SPEC §5.6).
    static func alphabetical(in context: ModelContext) throws -> [Player] {
        try context.fetch(FetchDescriptor<Player>()).sorted(by: alphabetically)
    }

    /// Those who played most recently first, then those who never played, alphabetically
    /// (the Player picker, SPEC §5.2).
    static func byMostRecentlyPlayed(in context: ModelContext) throws -> [Player] {
        try context.fetch(FetchDescriptor<Player>()).sorted(by: mostRecentlyPlayed)
    }

    /// The Player with this name, compared ignoring case, accents and surrounding spaces.
    static func named(_ name: String, in context: ModelContext) throws -> Player? {
        try context.fetch(FetchDescriptor<Player>()).first { PlayerName.isSame($0.name, name) }
    }

    /// Creates and saves a Player. Fails if the name is empty, too long or already taken.
    @discardableResult
    static func add(named name: String, in context: ModelContext, date: Date = .now) throws -> Player {
        let existing = try context.fetch(FetchDescriptor<Player>()).map(\.name)
        let cleaned = try PlayerName.validate(name, existing: existing).get()
        let player = Player(name: cleaned, createdAt: date)
        context.insert(player)
        try context.save()
        return player
    }

    /// Renames the Player everywhere, History included. Fails if another Player has the name.
    func rename(to newName: String) throws {
        let others = try otherNames()
        name = try PlayerName.validate(newName, existing: others).get()
        try modelContext?.save()
    }

    /// Why `newName` can't be saved as this Player's name, or `nil` if it can.
    func renameProblem(_ newName: String) -> PlayerNameError? {
        let others = (try? otherNames()) ?? []
        if case .failure(let error) = PlayerName.validate(newName, existing: others) { return error }
        return nil
    }

    /// Whether the Player is in some Match In progress (the deletion warning, SPEC §5.6).
    var isPlayingMatchInProgress: Bool {
        seats.contains { $0.participant?.match?.status == .inProgress }
    }

    /// The date of the last Entry of the latest Match they played, if any.
    var lastPlayedAt: Date? {
        seats.compactMap { $0.participant?.match?.lastEntryAt }.max()
    }

    // MARK: - Private

    private func otherNames() throws -> [String] {
        guard let context = modelContext else { return [] }
        let id = persistentModelID
        return try context.fetch(FetchDescriptor<Player>()).filter { $0.persistentModelID != id }.map(\.name)
    }

    private static func alphabetically(_ lhs: Player, _ rhs: Player) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    private static func mostRecentlyPlayed(_ lhs: Player, _ rhs: Player) -> Bool {
        switch (lhs.lastPlayedAt, rhs.lastPlayedAt) {
        case let (l?, r?) where l != r: l > r
        case (_?, nil): true
        case (nil, _?): false
        default: alphabetically(lhs, rhs)
        }
    }
}
