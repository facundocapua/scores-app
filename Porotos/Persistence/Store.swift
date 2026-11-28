import Foundation
import SwiftData

/// The app's SwiftData container. Everything stays on the device: no iCloud, no network.
enum Store {
    static let schema = Schema([Match.self, Participant.self, Seat.self, Player.self])

    static func container(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
