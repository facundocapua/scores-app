import SwiftUI

/// The Burako world tokens: ivory tiles on a petrol-green table (`DESIGN.md`, Burako).
enum BurakoWorld {
    static let ground = Color(hex: 0x123B40)
    static let ground2 = Color(hex: 0x0C2C30)
    static let ink = Color(hex: 0xEAF2F0)
    static let dim = Color(hex: 0x9DB9B6)
    static let action = Color(hex: 0xF2C14E)
    static let ivory = Color(hex: 0xF7F2E6)
    static let ivoryEdge = Color(hex: 0xD9CFB8)
    /// A faint surface over the table, for racks and rows.
    static let surface = Color.white.opacity(0.07)
    /// The destructive color, readable on the table.
    static let end = Color(hex: 0xE8826F)

    /// The four tile colors, in the order the digits alternate. The yellow is `#946409`
    /// (4.6:1 on the ivory, WCAG AA).
    static let tileColors = [
        Color(hex: 0xC62828),
        Color(hex: 0x1E5BB8),
        Color(hex: 0x1F1F1F),
        Color(hex: 0x946409),
    ]

    static var background: some View {
        LinearGradient(colors: [ground, ground2], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

/// One ivory tile with a single character.
struct Tile: View {
    var text: String
    var color: Color
    var height: CGFloat

    var body: some View {
        Text(text)
            .font(DisplayFont.alfaSlabOne.fixed(height * 0.62))
            .foregroundStyle(color)
            .frame(width: height * 0.76, height: height)
            .background(
                RoundedRectangle(cornerRadius: height * 0.16)
                    .fill(BurakoWorld.ivory)
                    .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: height * 0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: height * 0.16)
                    .strokeBorder(BurakoWorld.ivoryEdge, lineWidth: 1)
            )
    }
}

/// A score written with tiles: one digit per tile, alternating the four tile colors. It does
/// not scale with Dynamic Type (SPEC §8) and reads as a number.
struct TileNumber: View {
    var value: Int
    var height: CGFloat
    /// Shows a "+" tile before a positive number (a Hand's result).
    var signed = false
    /// What VoiceOver reads. By default, the number.
    var spoken: String?

    private var characters: [String] {
        var characters = String(abs(value)).map(String.init)
        if value < 0 {
            characters.insert("−", at: 0)
        } else if signed, value > 0 {
            characters.insert("+", at: 0)
        }
        return characters
    }

    var body: some View {
        HStack(spacing: height * 0.08) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                Tile(text: character, color: BurakoWorld.tileColors[index % BurakoWorld.tileColors.count], height: height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken ?? (value < 0 ? "menos \(Burako.grouped(-value))" : Burako.grouped(value)))
    }
}

/// A progress bar toward the Target score.
struct RaceBar: View {
    var score: Int
    var target: Int

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(max(Double(score) / Double(target), 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(BurakoWorld.ink.opacity(0.14))
                Capsule()
                    .fill(BurakoWorld.action)
                    .frame(width: max(proxy.size.width * fraction, fraction > 0 ? 8 : 0))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

/// Lays its children out in rows, wrapping to the next one when they don't fit.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(in: bounds.width, subviews: subviews)
        for (subview, origin) in zip(subviews, result.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }
        return (CGSize(width: usedWidth, height: y + rowHeight), origins)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        TileNumber(value: 1240, height: 52)
        TileNumber(value: -150, height: 40)
        TileNumber(value: 520, height: 30, signed: true)
        RaceBar(score: 1240, target: 3000)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(BurakoWorld.ground)
}
