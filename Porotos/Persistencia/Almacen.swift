import Foundation
import SwiftData

/// El contenedor de SwiftData de la app. Todo queda en el dispositivo: sin iCloud ni red.
enum Almacen {
    static let esquema = Schema([Partida.self, Participante.self, Integrante.self, Jugador.self])

    static func contenedor(enMemoria: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let configuracion: ModelConfiguration
        if let url {
            configuracion = ModelConfiguration(schema: esquema, url: url, cloudKitDatabase: .none)
        } else {
            configuracion = ModelConfiguration(
                schema: esquema,
                isStoredInMemoryOnly: enMemoria,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: esquema, configurations: configuracion)
    }
}
