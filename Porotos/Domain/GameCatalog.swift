import Foundation

/// The rules of each Game, for the shared screens that work with any Match (Home, History).
/// Each Game registers here when it is implemented.
enum GameCatalog {
    static func rules(for kind: GameKind) -> (any GameRules.Type)? {
        switch kind {
        case .truco: Truco.self
        case .burako: Burako.self
        case .generala: nil
        }
    }
}
