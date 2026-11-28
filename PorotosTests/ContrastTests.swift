import SwiftUI
import Testing
import UIKit
@testable import Porotos

/// WCAG 2.x contrast ratio between two sRGB colors (SPEC §8).
struct RGB: Equatable {
    var red: Double
    var green: Double
    var blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Resolves a SwiftUI color (also an adaptive one) for a user interface style.
    init(_ color: Color, style: UIUserInterfaceStyle = .light) {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var (red, green, blue, alpha) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: red, green: green, blue: blue)
    }

    /// This color painted over `background` with the given opacity.
    func over(_ background: RGB, opacity: Double) -> RGB {
        RGB(
            red: red * opacity + background.red * (1 - opacity),
            green: green * opacity + background.green * (1 - opacity),
            blue: blue * opacity + background.blue * (1 - opacity)
        )
    }

    var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}

enum Contrast {
    static let smallText = 4.5
    static let largeTextAndGraphics = 3.0

    static func ratio(_ first: RGB, _ second: RGB) -> Double {
        let (a, b) = (first.relativeLuminance, second.relativeLuminance)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}

/// One foreground over one background, as the app really paints them.
struct Pair: CustomTestStringConvertible {
    var name: String
    var foreground: RGB
    var background: RGB
    var minimum: Double

    var testDescription: String { name }
    var ratio: Double { Contrast.ratio(foreground, background) }
}

struct ContrastMathTests {
    @Test func blackOnWhiteIs21() {
        #expect(abs(Contrast.ratio(RGB(hex: 0x000000), RGB(hex: 0xFFFFFF)) - 21) < 0.001)
    }

    @Test func sameColorIs1() {
        #expect(abs(Contrast.ratio(RGB(hex: 0x8E2A23), RGB(hex: 0x8E2A23)) - 1) < 0.001)
    }

    @Test func isSymmetric() {
        let (a, b) = (RGB(hex: 0xF2B33D), RGB(hex: 0x17120F))
        #expect(Contrast.ratio(a, b) == Contrast.ratio(b, a))
    }

    @Test func matchesAKnownValue() {
        // #767676 on white is the classic 4.54:1.
        #expect(abs(Contrast.ratio(RGB(hex: 0x767676), RGB(hex: 0xFFFFFF)) - 4.54) < 0.01)
    }

    @Test func compositesOverTheBackground() {
        let mixed = RGB(hex: 0xFFFFFF).over(RGB(hex: 0x000000), opacity: 0.5)
        #expect(abs(mixed.red - 0.5) < 0.0001)
    }
}

/// Every token pair the app uses for text (4.5:1), for large text and for graphics (3:1), in
/// each world and in the shell. A new pair in a view goes here.
struct ContrastTokenTests {
    private static let small = Contrast.smallText
    private static let large = Contrast.largeTextAndGraphics

    private static func pair(_ name: String, _ foreground: Color, _ background: Color, _ minimum: Double) -> Pair {
        Pair(name: name, foreground: RGB(foreground), background: RGB(background), minimum: minimum)
    }

    static let truco: [Pair] = {
        typealias W = TrucoWorld
        return [
            pair("Truco ink on ground", W.ink, W.ground, small),
            pair("Truco ink on ground2", W.ink, W.ground2, small),
            pair("Truco accent (leading score) on ground", W.accent, W.ground, large),
            pair("Truco accent on ground2", W.accent, W.ground2, large),
            pair("Truco accent (title, buttons) on ground", W.accent, W.ground, small),
            pair("Truco dim on ground", W.dim, W.ground, small),
            pair("Truco dim on ground2", W.dim, W.ground2, small),
            pair("Truco end on ground", W.end, W.ground, small),
            pair("Truco end on ground2", W.end, W.ground2, small),
            pair("Truco +1 label (ground on ink)", W.ground, W.ink, small),
            pair("Truco Rematch label (ink on ground)", W.ink, W.ground, small),
            pair("Truco end screen text (ground on paper)", W.ground, TrucoWorld.paper, small),
            pair("Truco matchstick head on ground", W.head, W.ground, large),
            pair("Truco matchstick wood on ground", W.wood, W.ground, large),
        ]
    }()

    static let generala: [Pair] = {
        typealias W = GeneralaWorld
        let felts = [("felt", W.felt), ("feltLight", W.feltLight), ("feltDark", W.feltDark)]
        var pairs: [Pair] = []
        for (name, felt) in felts {
            pairs.append(pair("Generala ink on \(name)", W.ink, felt, small))
            pairs.append(pair("Generala dim on \(name)", W.dim, felt, small))
            pairs.append(pair("Generala brass (large text, borders) on \(name)", W.brass, felt, large))
        }
        pairs.append(pair("Generala end on feltDark (cell sheet)", W.end, W.feltDark, small))
        pairs.append(pair("Generala Turn badge (feltDark on brass)", W.feltDark, W.brass, small))
        pairs.append(pair("Generala Rematch label (feltDark on brass)", W.feltDark, W.brass, small))
        return pairs
    }()

    static let burako: [Pair] = {
        typealias W = BurakoWorld
        let surface = RGB(Color.white).over(RGB(W.ground), opacity: 0.07)
        var pairs: [Pair] = []
        for (name, ground) in [("ground", W.ground), ("ground2", W.ground2)] {
            pairs.append(pair("Burako ink on \(name)", W.ink, ground, small))
            pairs.append(pair("Burako dim on \(name)", W.dim, ground, small))
            pairs.append(pair("Burako action on \(name)", W.action, ground, small))
            pairs.append(pair("Burako end on \(name)", W.end, ground, small))
        }
        pairs.append(Pair(name: "Burako dim on surface", foreground: RGB(W.dim), background: surface, minimum: small))
        pairs.append(Pair(name: "Burako ink on surface", foreground: RGB(W.ink), background: surface, minimum: small))
        pairs.append(Pair(name: "Burako action on surface", foreground: RGB(W.action), background: surface, minimum: small))
        pairs.append(pair("Burako button label (ground on action)", W.ground, W.action, small))
        for (index, color) in W.tileColors.enumerated() {
            pairs.append(pair("Burako tile color \(index) on ivory", color, W.ivory, small))
        }
        pairs.append(pair("Burako ivory tile on ground", W.ivory, W.ground, large))
        return pairs
    }()

    private static func shell(_ style: UIUserInterfaceStyle) -> [Pair] {
        let name = style == .dark ? "dark" : "light"
        // The system backgrounds the shell is drawn over (list, grouped, elevated).
        let backgrounds: [(String, UIColor)] = [
            ("systemBackground", .systemBackground),
            ("secondarySystemBackground", .secondarySystemBackground),
            ("systemGroupedBackground", .systemGroupedBackground),
            ("secondarySystemGroupedBackground", .secondarySystemGroupedBackground),
        ]
        var pairs: [Pair] = []
        for (backgroundName, background) in backgrounds {
            let resolved = background.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            let color = Color(resolved)
            pairs.append(Pair(
                name: "Shell brand on \(backgroundName) (\(name))",
                foreground: RGB(Color.brand, style: style),
                background: RGB(color, style: style),
                minimum: small
            ))
        }
        pairs.append(Pair(
            name: "Shell onBrand on brandFill (\(name))",
            foreground: RGB(Color.onBrand, style: style),
            background: RGB(Color.brandFill, style: style),
            minimum: small
        ))
        return pairs
    }

    static let shellLight = shell(.light)
    static let shellDark = shell(.dark)

    @Test(arguments: truco) func trucoPairsPass(pair: Pair) {
        #expect(pair.ratio >= pair.minimum, "\(pair.name): \(pair.ratio)")
    }

    @Test(arguments: generala) func generalaPairsPass(pair: Pair) {
        #expect(pair.ratio >= pair.minimum, "\(pair.name): \(pair.ratio)")
    }

    @Test(arguments: burako) func burakoPairsPass(pair: Pair) {
        #expect(pair.ratio >= pair.minimum, "\(pair.name): \(pair.ratio)")
    }

    @Test(arguments: shellLight) func shellLightPairsPass(pair: Pair) {
        #expect(pair.ratio >= pair.minimum, "\(pair.name): \(pair.ratio)")
    }

    @Test(arguments: shellDark) func shellDarkPairsPass(pair: Pair) {
        #expect(pair.ratio >= pair.minimum, "\(pair.name): \(pair.ratio)")
    }
}
