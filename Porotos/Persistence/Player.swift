import Foundation
import SwiftData

/// A saved person, reusable across Matches. A Player only has a name (SPEC §3.3).
@Model
final class Player {
    var id: UUID
    var name: String
    var createdAt: Date

    /// The Seats this Player took in Matches. When the Player is deleted, they keep the name.
    @Relationship(deleteRule: .nullify, inverse: \Seat.player)
    var seats: [Seat] = []

    init(name: String, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.createdAt = createdAt
    }

    /// Deletes the Player. The Matches they played, including those in progress, keep the
    /// last name they had.
    func delete() throws {
        for seat in seats {
            seat.savedName = name
        }
        guard let context = modelContext else { return }
        context.delete(self)
        try context.save()
    }
}
