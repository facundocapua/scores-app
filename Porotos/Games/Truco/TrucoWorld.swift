import SwiftUI

/// The Truco world tokens: matchsticks on a night table (`DESIGN.md`, Truco).
enum TrucoWorld {
    static let ground = Color(hex: 0x17120F)
    static let ground2 = Color(hex: 0x221A15)
    static let wood = Color(hex: 0xE8CF9C)
    static let woodDark = Color(hex: 0xB99560)
    static let head = Color(hex: 0xC23B22)
    static let headShine = Color(hex: 0xE2664B)
    static let ink = Color(hex: 0xF3E9D8)
    static let dim = Color(hex: 0xA8998A)
    static let accent = Color(hex: 0xF2B33D)
    static let end = Color(hex: 0xE8826F)
    /// The inverted end screen background.
    static let paper = Color(hex: 0xF3E9D8)

    static var background: some View {
        RadialGradient(
            colors: [ground2, ground],
            center: UnitPoint(x: 0.5, y: 0.3),
            startRadius: 0,
            endRadius: 700
        )
        .ignoresSafeArea()
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// A group of up to five matchsticks: a square (left, top, right, bottom) plus the diagonal.
/// Drawn on a 66 × 66 grid and scaled to fit.
struct MatchstickGroup: View {
    var count: Int

    private static let sticks: [(CGPoint, CGPoint, headAtEnd: Bool)] = [
        (CGPoint(x: 8, y: 10), CGPoint(x: 8, y: 56), false),
        (CGPoint(x: 10, y: 8), CGPoint(x: 56, y: 8), true),
        (CGPoint(x: 58, y: 10), CGPoint(x: 58, y: 56), true),
        (CGPoint(x: 10, y: 58), CGPoint(x: 56, y: 58), false),
        (CGPoint(x: 14, y: 52), CGPoint(x: 52, y: 14), true),
    ]

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 66
            context.scaleBy(x: scale, y: scale)
            for (start, end, headAtEnd) in Self.sticks.prefix(count) {
                var line = Path()
                line.move(to: start)
                line.addLine(to: end)
                context.stroke(line, with: .color(TrucoWorld.woodDark), style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                context.stroke(line, with: .color(TrucoWorld.wood), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
                let head = headAtEnd ? end : start
                context.fill(Path(ellipseIn: CGRect(x: head.x - 5, y: head.y - 5, width: 10, height: 10)), with: .color(TrucoWorld.head))
                context.fill(
                    Path(ellipseIn: CGRect(x: head.x - 3.2, y: head.y - 3.2, width: 4, height: 4)),
                    with: .color(TrucoWorld.headShine.opacity(0.8))
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// A block of three group slots: the malas, the buenas, or the whole score when playing to 15.
struct MatchstickBlock: View {
    var points: Int

    var body: some View {
        let groups = TrucoTally.groups(points)
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { slot in
                MatchstickGroup(count: slot < groups.count ? groups[slot] : 0)
            }
        }
        .frame(maxWidth: 66)
    }
}

#Preview {
    HStack {
        MatchstickBlock(points: 12)
        MatchstickBlock(points: 15)
    }
    .padding()
    .background(TrucoWorld.ground)
}
