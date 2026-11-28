import Foundation
import SwiftData

/// Persona guardada y reutilizable entre Partidas. Solo tiene un nombre (SPEC §3.3).
@Model
final class Jugador {
    var id: UUID
    var nombre: String
    var fechaDeAlta: Date

    /// Los lugares que ocupó en Partidas. Al borrarlo, esos lugares conservan su nombre.
    @Relationship(deleteRule: .nullify, inverse: \Integrante.jugador)
    var integraciones: [Integrante] = []

    init(nombre: String, fechaDeAlta: Date = .now) {
        self.id = UUID()
        self.nombre = nombre
        self.fechaDeAlta = fechaDeAlta
    }

    /// Borra el Jugador. Las Partidas donde jugó, incluso las En curso, conservan el último
    /// nombre que tenía.
    func borrar() throws {
        for integrante in integraciones {
            integrante.nombreGuardado = nombre
        }
        guard let contexto = modelContext else { return }
        contexto.delete(self)
        try contexto.save()
    }
}
