import Foundation

/// Las reglas de cada Juego, para las pantallas comunes que trabajan con cualquier Partida
/// (Inicio, Historial). Cada Juego se registra acá cuando se implementa.
enum CatalogoDeJuegos {
    static func reglas(para tipo: TipoDeJuego) -> (any ReglasDeJuego.Type)? {
        switch tipo {
        case .truco, .generala, .burako:
            nil
        }
    }
}
