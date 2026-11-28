import Foundation
import SwiftData

/// Quien suma puntos y puede ganar en una Partida: un Jugador o un Equipo (SPEC §3.2).
@Model
final class Participante {
    var orden: Int
    /// El nombre del Equipo. `nil` cuando el Participante es un Jugador solo.
    var nombreDeEquipo: String?
    var partida: Partida?

    @Relationship(deleteRule: .cascade, inverse: \Integrante.participante)
    var integrantes: [Integrante] = []

    init(orden: Int, nombreDeEquipo: String?) {
        self.orden = orden
        self.nombreDeEquipo = nombreDeEquipo
    }

    var integrantesEnOrden: [Integrante] {
        integrantes.sorted { $0.orden < $1.orden }
    }

    var esEquipo: Bool { nombreDeEquipo != nil }

    var nombre: String {
        nombreDeEquipo ?? integrantesEnOrden.first?.nombre ?? ""
    }
}

/// El lugar de un Jugador dentro de un Participante.
@Model
final class Integrante {
    var orden: Int
    /// `nil` si el Jugador fue borrado.
    var jugador: Jugador?
    /// El nombre que se muestra si el Jugador fue borrado.
    var nombreGuardado: String
    var participante: Participante?

    init(orden: Int, jugador: Jugador) {
        self.orden = orden
        self.jugador = jugador
        self.nombreGuardado = jugador.nombre
    }

    /// El nombre actual del Jugador mientras exista; si no, el último que tuvo.
    var nombre: String { jugador?.nombre ?? nombreGuardado }
}

/// Un Participante antes de crear la Partida: lo que se arma en Crear Partida y lo que
/// propone Recordar.
struct ParticipanteBorrador: Equatable {
    /// El nombre del Equipo, o `nil` si es un Jugador solo.
    var nombreDeEquipo: String?
    /// Los Jugadores en orden. `nil` es un lugar vacío (por ejemplo, un Jugador borrado).
    var jugadores: [Jugador?]

    init(nombreDeEquipo: String? = nil, jugadores: [Jugador?] = []) {
        self.nombreDeEquipo = nombreDeEquipo
        self.jugadores = jugadores
    }

    static func jugador(_ jugador: Jugador?) -> ParticipanteBorrador {
        ParticipanteBorrador(jugadores: [jugador])
    }

    static func equipo(_ nombre: String, jugadores: [Jugador?] = []) -> ParticipanteBorrador {
        ParticipanteBorrador(nombreDeEquipo: nombre, jugadores: jugadores)
    }

    var tieneLugaresVacios: Bool { jugadores.contains { $0 == nil } }
}
