import SwiftData
import SwiftUI

/// The "⋯" details of a Generala Match (SPEC §5.3, §6.4): the Variant, which can be changed
/// unless it would end the Match on the spot, and the Players in Turn order. Participants and
/// the Turn order are fixed once the Match has started.
struct GeneralaDetailsSheet: View {
    @Bindable var match: Match
    @Environment(\.dismiss) private var dismiss

    private var variant: Generala.Variant { (try? match.variant(Generala.self)) ?? .standard }

    var body: some View {
        NavigationStack {
            Form {
                Section("Variante") {
                    Toggle("Generala servida gana", isOn: Binding(
                        get: { variant.servedGeneralaWins },
                        set: { try? match.changeVariant(Generala.self, to: Generala.Variant(servedGeneralaWins: $0)) }
                    ))
                    .disabled(!allowsToggling)
                }

                Section("Jugadores") {
                    ForEach(Array(match.orderedParticipants.enumerated()), id: \.offset) { index, participant in
                        HStack {
                            Text("\(index + 1)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .frame(minWidth: 24, alignment: .leading)
                                .accessibilityHidden(true)
                            Text(participant.name)
                        }
                    }
                }
            }
            .navigationTitle("Detalles")
            .scrollContentBackground(.hidden)
            .background(GeneralaWorld.feltDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .tint(GeneralaWorld.brass)
        .presentationDetents([.medium, .large])
        .presentationBackground(GeneralaWorld.feltDark)
    }

    /// Turning the option on is disabled if a Served Generala has already happened, because it
    /// would end the Match on the spot (SPEC §6.4).
    private var allowsToggling: Bool {
        let flipped = Generala.Variant(servedGeneralaWins: !variant.servedGeneralaWins)
        return match.allows(flipped, Generala.self)
    }
}
