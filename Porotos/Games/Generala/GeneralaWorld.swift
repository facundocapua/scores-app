import SwiftUI

/// The Generala world tokens: casino felt with brass (`DESIGN.md`, Generala). Brass is used
/// only on large text and borders, never on small text.
enum GeneralaWorld {
    static let feltLight = Color(hex: 0x127049)
    static let felt = Color(hex: 0x0D5A3B)
    static let feltDark = Color(hex: 0x083D28)
    static let brass = Color(hex: 0xD8B45A)
    static let ink = Color(hex: 0xF4F0E2)
    static let dim = Color(hex: 0xD2E6DA)
    static let end = Color(hex: 0xF0948A)

    /// Green felt with an overhead light.
    static var background: some View {
        RadialGradient(
            colors: [feltLight, felt, feltDark],
            center: UnitPoint(x: 0.5, y: 0.25),
            startRadius: 0,
            endRadius: 700
        )
        .ignoresSafeArea()
    }
}

/// How the Scoresheet reads, in Spanish: the names the UI and VoiceOver use for each category.
extension Generala.Category {
    /// "Al 3" for the face rows, as it is said at the table.
    var title: String {
        switch self {
        case .straight: "Escalera"
        case .fullHouse: "Full"
        case .fourOfAKind: "Póker"
        case .generala: "Generala"
        case .doubleGenerala: "Doble Generala"
        default: "Al \(face ?? 0)"
        }
    }

    /// The short name for the narrow category column.
    var shortTitle: String {
        self == .doubleGenerala ? "Doble G." : title
    }
}

extension Generala.Option {
    /// "30", "35 servido", or "Servida: gana" for a Served Generala that wins the Match.
    func label(for category: Generala.Category, variant: Generala.Variant) -> String {
        guard served else { return "\(points)" }
        if category == .generala && variant.servedGeneralaWins { return "Servida: gana" }
        return "\(points) servido"
    }
}

extension Generala.Entry {
    /// What a cell reads as for VoiceOver (SPEC §8): "Ana, Full, 30, servido".
    static func spoken(name: String, category: Generala.Category, entry: Generala.Entry?) -> String {
        var parts = [name, category.title]
        switch entry?.mark {
        case nil: parts.append("vacío")
        case .scratched?: parts.append("tachado")
        case .points(let points)?:
            parts.append("\(points)")
            if entry?.served == true { parts.append("servido") }
        }
        return parts.joined(separator: ", ")
    }
}
