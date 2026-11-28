import Foundation
@testable import Porotos

/// Un Juego mínimo para probar el modelo común: cada Anotación suma puntos a un
/// Participante, y gana el primero que llega a la meta.
enum JuegoDeSuma: ReglasDeJuego {
    struct Variante: Codable, Equatable, Sendable { var meta: Int }
    struct Anotacion: Codable, Equatable, Sendable { var participante: Int; var puntos: Int }

    static let tipo = TipoDeJuego.truco
    static let varianteEstandar = Variante(meta: 10)
    static var participantesIniciales: [ParticipanteBorrador] { [.equipo("Nosotros"), .equipo("Ellos")] }

    static func puedeEmpezar(con participantes: [ParticipanteBorrador]) -> Bool {
        participantes.count >= 2
    }

    static func resultado(variante: Variante, cantidadDeParticipantes: Int, anotaciones: [Anotacion]) -> Resultado {
        var puntajes = Array(repeating: 0, count: cantidadDeParticipantes)
        for anotacion in anotaciones { puntajes[anotacion.participante] += anotacion.puntos }
        let llegaron = puntajes.indices.filter { puntajes[$0] >= variante.meta }
        guard !llegaron.isEmpty else { return .enCurso(puntajes) }
        return Resultado(puntajes: puntajes, terminada: true, ganadores: Resultado.lideres(puntajes))
    }
}

/// Otro Juego, para probar que cada Juego recuerda lo suyo.
enum OtroJuego: ReglasDeJuego {
    struct Variante: Codable, Equatable, Sendable { var opcion: Bool }
    typealias Anotacion = Int

    static let tipo = TipoDeJuego.generala
    static let varianteEstandar = Variante(opcion: true)
    static var participantesIniciales: [ParticipanteBorrador] { [] }

    static func puedeEmpezar(con participantes: [ParticipanteBorrador]) -> Bool { true }

    static func resultado(variante: Variante, cantidadDeParticipantes: Int, anotaciones: [Int]) -> Resultado {
        .enCurso(Array(repeating: 0, count: cantidadDeParticipantes))
    }
}
