import SwiftUI

/// Shell tokens (see `DESIGN.md`). Each Game world keeps its own tokens next to the Game.
extension Color {
    /// The brand tint: poroto colorado (red bean).
    static let brand = Color(red: 0x8E / 255, green: 0x2A / 255, blue: 0x23 / 255)
    /// Text on the brand color.
    static let onBrand = Color(red: 0xFF / 255, green: 0xF6 / 255, blue: 0xEE / 255)
}

/// The display fonts bundled with the app. They are only used for display moments: all UI
/// text uses SF with Dynamic Type.
enum DisplayFont: String, CaseIterable {
    /// The Porotos wordmark.
    case shrikhand = "Shrikhand-Regular"
    /// Truco.
    case bevan = "Bevan-Regular"
    /// Generala.
    case abrilFatface = "AbrilFatface-Regular"
    /// Burako.
    case alfaSlabOne = "AlfaSlabOne-Regular"

    /// A fixed size, for display numbers that don't scale (SPEC §8).
    func fixed(_ size: CGFloat) -> Font {
        .custom(rawValue, fixedSize: size)
    }

    /// A size that scales with Dynamic Type, relative to a text style.
    func scaled(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(rawValue, size: size, relativeTo: style)
    }
}
