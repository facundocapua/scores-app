import SwiftUI

/// Tokens del shell (ver `DESIGN.md`). Los de cada mundo de Juego viven con su Juego.
extension Color {
    /// Poroto colorado, el tint de la marca.
    static let porotoColorado = Color(red: 0x8E / 255, green: 0x2A / 255, blue: 0x23 / 255)
    /// Texto sobre el poroto colorado.
    static let sobrePorotoColorado = Color(red: 0xFF / 255, green: 0xF6 / 255, blue: 0xEE / 255)
}

/// Las fuentes de display incluidas en la app. Solo se usan en momentos de display: todo el
/// texto de UI usa SF con Dynamic Type.
enum FuenteDeDisplay: String, CaseIterable {
    /// Wordmark de Porotos.
    case shrikhand = "Shrikhand-Regular"
    /// Truco.
    case bevan = "Bevan-Regular"
    /// Generala.
    case abrilFatface = "AbrilFatface-Regular"
    /// Burako.
    case alfaSlabOne = "AlfaSlabOne-Regular"

    /// Un tamaño fijo, para los números de display que no escalan (SPEC §8).
    func fija(_ tamano: CGFloat) -> Font {
        .custom(rawValue, fixedSize: tamano)
    }

    /// Un tamaño que escala con Dynamic Type a partir de un estilo de texto.
    func escalable(_ tamano: CGFloat, relativoA estilo: Font.TextStyle) -> Font {
        .custom(rawValue, size: tamano, relativeTo: estilo)
    }
}
