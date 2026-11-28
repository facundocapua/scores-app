import Foundation

/// Uno de los Juegos soportados (ver `GLOSSARY.md`).
enum TipoDeJuego: String, Codable, CaseIterable, Sendable {
    case truco
    case generala
    case burako

    var nombre: String {
        switch self {
        case .truco: "Truco"
        case .generala: "Generala"
        case .burako: "Burako"
        }
    }
}

/// Lo que define un Juego (SPEC §3.6). El resto de la app (Inicio, Historial, Jugadores,
/// Deshacer, terminar y descartar) es común y trabaja con cualquier `ReglasDeJuego`.
///
/// Todo es lógica pura: puntajes, fin y Ganadores se calculan siempre a partir de las
/// Anotaciones y nunca se guardan (ADR 0001).
protocol ReglasDeJuego {
    /// Las opciones de reglas elegidas al crear la Partida.
    associatedtype Variante: Codable & Equatable & Sendable
    /// Cada acción de anotar puntos (un tanto, una celda de la Planilla, una Mano).
    associatedtype Anotacion: Codable & Equatable & Sendable

    static var tipo: TipoDeJuego { get }

    /// La Variante estándar argentina, que se usa la primera vez.
    static var varianteEstandar: Variante { get }

    /// Los Participantes que se proponen la primera vez (por ejemplo, "Nosotros" y "Ellos").
    static var participantesIniciales: [ParticipanteBorrador] { get }

    /// Si se cumple el mínimo del Juego para empezar la Partida.
    static func puedeEmpezar(con participantes: [ParticipanteBorrador]) -> Bool

    /// Puntajes, fin y Ganadores según las reglas, sin contemplar Terminada antes.
    static func resultado(
        variante: Variante,
        cantidadDeParticipantes: Int,
        anotaciones: [Anotacion]
    ) -> Resultado
}

/// Lo que se calcula de una Partida. Los Participantes se identifican por su posición.
struct Resultado: Equatable, Sendable {
    var puntajes: [Int]
    var terminada: Bool
    /// Vacío mientras la Partida no terminó. Más de uno en un empate compartido.
    var ganadores: [Int]

    static func enCurso(_ puntajes: [Int]) -> Resultado {
        Resultado(puntajes: puntajes, terminada: false, ganadores: [])
    }

    /// Los Participantes que van primeros: todos los que tienen el puntaje más alto.
    static func lideres(_ puntajes: [Int]) -> [Int] {
        guard let maximo = puntajes.max() else { return [] }
        return puntajes.indices.filter { puntajes[$0] == maximo }
    }
}
