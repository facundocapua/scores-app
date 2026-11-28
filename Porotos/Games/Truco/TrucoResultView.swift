import SwiftUI

/// The Truco result in the History detail: the end screen's paper and ink, "¡Ganaron …!" and
/// the final score.
struct TrucoResultView: View {
    var entry: HistoryEntry

    private var headline: String {
        entry.winners.count == 1 ? "¡Ganaron \(entry.winners[0].name)!" : "Empate"
    }

    var body: some View {
        WorldResultCard(
            entry: entry,
            headline: headline,
            style: ResultStyle(
                background: AnyShapeStyle(TrucoEndView.paper),
                ink: TrucoWorld.ground,
                dim: Color(hex: 0x6B5D4E),
                highlight: TrucoWorld.head,
                headlineFont: DisplayFont.bevan.scaled(30, relativeTo: .title),
                nameFont: .title3
            )
        ) { score in
            Text("\(score)")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .environment(\.colorScheme, .light)
    }
}
