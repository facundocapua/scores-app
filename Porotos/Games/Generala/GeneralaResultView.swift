import SwiftUI

/// The Generala result in the History detail: the end screen's felt and brass, the final
/// scores and the Scoresheet to look at, read-only.
struct GeneralaResultView: View {
    var entry: HistoryEntry
    var variant: Generala.Variant
    var entries: [Generala.Entry]

    @State private var showingSheet = false

    private var headline: String {
        entry.winners.count == 1 ? "Ganó \(entry.winners[0].name)" : "Empate"
    }

    var body: some View {
        WorldResultCard(
            entry: entry,
            headline: headline,
            style: ResultStyle(
                background: AnyShapeStyle(GeneralaWorld.felt),
                ink: GeneralaWorld.ink,
                dim: GeneralaWorld.dim,
                highlight: GeneralaWorld.brass,
                headlineFont: DisplayFont.abrilFatface.scaled(30, relativeTo: .title),
                nameFont: .title3
            ),
            score: { score in
                Text("\(score)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            },
            extra: {
                Button("Ver planilla") { showingSheet = true }
                    .frame(minHeight: 44)
                    .tint(GeneralaWorld.brass)
            }
        )
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                ZStack {
                    GeneralaWorld.background
                    GeneralaScoresheet(
                        names: entry.participants.map(\.name),
                        entries: entries,
                        variant: variant,
                        turn: nil,
                        onSelect: nil
                    )
                }
                .navigationTitle("Planilla")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Listo") { showingSheet = false }
                    }
                }
            }
            .environment(\.colorScheme, .dark)
            .tint(GeneralaWorld.brass)
        }
    }
}
