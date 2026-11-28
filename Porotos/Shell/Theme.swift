import SwiftUI

/// Shell tokens (see `DESIGN.md`). Each Game world keeps its own tokens next to the Game.
extension Color {
    /// The brand tint for text and icons: poroto colorado (red bean) in light mode, a lighter
    /// tint of it in dark mode so it keeps 4.5:1 over the system backgrounds (WCAG AA).
    static let brand = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: 0xE5857A) : UIColor(rgb: 0x8E2A23)
        }
    )
    /// The brand red as a fill, always `#8E2A23`: it carries `onBrand` text in both modes.
    static let brandFill = Color(hex: 0x8E2A23)
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

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
