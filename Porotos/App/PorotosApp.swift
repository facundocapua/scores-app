import SwiftData
import SwiftUI

@main
struct PorotosApp: App {
    private let container: ModelContainer = {
        do {
            return try Store.container()
        } catch {
            fatalError("Could not open the Porotos store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
