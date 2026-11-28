import Foundation

/// Las Anotaciones de una Partida, en orden, más el historial de cambios que usa Deshacer.
///
/// Deshacer revierte el último cambio, sin límite (SPEC §3.4): si se agregó una Anotación la
/// saca, y si se editó o se quitó una, restaura el valor anterior. El historial se guarda con
/// la Partida, así que Deshacer funciona igual después de reabrir la app. Solo sirve para
/// Deshacer: los puntajes se calculan con `anotaciones` (ADR 0001).
struct RegistroDeAnotaciones<Anotacion: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    private(set) var anotaciones: [Anotacion] = []
    private var cambios: [Cambio] = []

    private enum Cambio: Codable, Equatable, Sendable {
        case agregada
        case editada(indice: Int, anterior: Anotacion)
        case quitada(indice: Int, anterior: Anotacion)
    }

    init() {}

    var puedeDeshacer: Bool { !cambios.isEmpty }

    mutating func agregar(_ anotacion: Anotacion) {
        anotaciones.append(anotacion)
        cambios.append(.agregada)
    }

    /// Reemplaza una Anotación vieja (una celda de Generala, una Mano de Burako).
    mutating func editar(en indice: Int, por nueva: Anotacion) {
        precondition(anotaciones.indices.contains(indice), "No hay Anotación en \(indice)")
        let anterior = anotaciones[indice]
        guard anterior != nueva else { return }
        anotaciones[indice] = nueva
        cambios.append(.editada(indice: indice, anterior: anterior))
    }

    /// Saca una Anotación vieja (por ejemplo, vaciar una celda de Generala).
    mutating func quitar(en indice: Int) {
        precondition(anotaciones.indices.contains(indice), "No hay Anotación en \(indice)")
        let anterior = anotaciones.remove(at: indice)
        cambios.append(.quitada(indice: indice, anterior: anterior))
    }

    /// Revierte el último cambio. Devuelve `false` si no había nada para deshacer.
    @discardableResult
    mutating func deshacer() -> Bool {
        guard let ultimo = cambios.popLast() else { return false }
        switch ultimo {
        case .agregada:
            anotaciones.removeLast()
        case let .editada(indice, anterior):
            anotaciones[indice] = anterior
        case let .quitada(indice, anterior):
            anotaciones.insert(anterior, at: indice)
        }
        return true
    }
}
