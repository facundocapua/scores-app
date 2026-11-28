import SwiftData
import SwiftUI

@main
struct PorotosApp: App {
    private let contenedor: ModelContainer = {
        do {
            return try Almacen.contenedor()
        } catch {
            fatalError("No se pudo abrir el almacén de Porotos: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RaizView()
        }
        .modelContainer(contenedor)
    }
}
