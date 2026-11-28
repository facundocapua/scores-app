import SwiftUI

/// The detail of a Finished Match (SPEC §5.5). It is always read-only: no Undo, no reopening.
/// It shows the date, the duration, the Variant, the Participants with their Players and the
/// result in the Game's world, and offers "Jugar de nuevo" and Delete.
struct MatchDetailView: View {
    var entry: HistoryEntry
    var match: Match
    var onPlayAgain: () -> Void
    /// Called once the deletion is confirmed. The caller leaves this screen and deletes.
    var onDelete: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        List {
            Section {
                result
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Fecha", value: History.fullDate(entry.finishedAt))
                LabeledContent(
                    "Duración",
                    value: History.duration(from: entry.startedAt, to: entry.finishedAt)
                )
                ForEach(Array(entry.variantRows.enumerated()), id: \.offset) { _, row in
                    LabeledContent(row.label, value: row.value)
                }
            }

            Section("Participantes") {
                ForEach(entry.participants) { participant in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(participant.name)
                        if participant.isTeam, !participant.players.isEmpty {
                            Text(participant.players.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            Section {
                Button("Eliminar partida", role: .destructive) { confirmingDelete = true }
            }
        }
        .navigationTitle(entry.kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: onPlayAgain) {
                Text("Jugar de nuevo")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.brandFill, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .confirmationDialog("¿Eliminar la partida?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Eliminar partida", role: .destructive, action: onDelete)
        }
    }

    @ViewBuilder private var result: some View {
        switch entry.detail {
        case .truco:
            TrucoResultView(entry: entry)
        case .generala(let variant, let entries):
            GeneralaResultView(entry: entry, variant: variant, entries: entries)
        case .burako(_, let handCount):
            BurakoResultView(entry: entry, match: match, handCount: handCount)
        }
    }
}
