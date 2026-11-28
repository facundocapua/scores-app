import SwiftUI

/// The Burako result in the History detail: the end screen's petrol table, the scores in
/// tiles and the Hands as chips, each opening read-only.
struct BurakoResultView: View {
    var entry: HistoryEntry
    var match: Match
    var handCount: Int

    @State private var calculator: BurakoCalculatorMode?

    private var headline: String {
        entry.winners.count == 1 ? "¡Ganó \(entry.winners[0].name)!" : "Empate"
    }

    var body: some View {
        WorldResultCard(
            entry: entry,
            headline: headline,
            style: ResultStyle(
                background: AnyShapeStyle(BurakoWorld.ground),
                ink: BurakoWorld.ink,
                dim: BurakoWorld.dim,
                highlight: BurakoWorld.action,
                headlineFont: DisplayFont.alfaSlabOne.scaled(26, relativeTo: .title),
                nameFont: DisplayFont.alfaSlabOne.scaled(18, relativeTo: .headline)
            ),
            score: { TileNumber(value: $0, height: 34) },
            extra: {
                if handCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manos")
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .foregroundStyle(BurakoWorld.dim)
                            .accessibilityAddTraits(.isHeader)
                        HandChips(count: handCount) { calculator = .view($0) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        )
        .sheet(item: $calculator) { mode in
            BurakoCalculatorView(match: match, mode: mode)
                .environment(\.colorScheme, .dark)
                .tint(BurakoWorld.action)
        }
    }
}
