import Foundation
import SwiftData

/// Lo que se precarga en Crear Partida.
struct ConfiguracionDePartida<Variante: Equatable> {
    var variante: Variante
    var participantes: [ParticipanteBorrador]
}

/// Recordar la última configuración (SPEC §3.5): cada Juego propone la Variante y los
/// Participantes de su última Partida que todavía existe, esté En curso o Terminada. Un
/// Jugador borrado deja su lugar vacío. La primera vez se usan los valores estándar.
enum Recordar {
    static func ultimaConfiguracion<R: ReglasDeJuego>(
        _ reglas: R.Type,
        en contexto: ModelContext
    ) throws -> ConfiguracionDePartida<R.Variante> {
        let tipo = R.tipo.rawValue
        var descriptor = FetchDescriptor<Partida>(
            predicate: #Predicate { $0.tipoRaw == tipo },
            sortBy: [SortDescriptor(\.fechaDeInicio, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let ultima = try contexto.fetch(descriptor).first else {
            return ConfiguracionDePartida(variante: R.varianteEstandar, participantes: R.participantesIniciales)
        }
        return ConfiguracionDePartida(
            variante: try ultima.variante(reglas),
            participantes: ultima.participantesEnOrden.map { participante in
                ParticipanteBorrador(
                    nombreDeEquipo: participante.nombreDeEquipo,
                    jugadores: participante.integrantesEnOrden.map(\.jugador)
                )
            }
        )
    }
}
