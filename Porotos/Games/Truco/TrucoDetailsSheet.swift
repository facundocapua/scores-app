import SwiftData
import SwiftUI

/// The "⋯" details of a Truco Match (SPEC §5.3, §6.4): the Variant, which can be changed
/// unless it would end the Match on the spot, and the Teams, whose names can be edited.
/// Players are fixed once the Match has started.
struct TrucoDetailsSheet: View {
    @Bindable var match: Match
    @Environment(\.dismiss) private var dismiss
    @State private var teamNames: [String] = []

    private var variant: Truco.Variant { (try? match.variant(Truco.self)) ?? Truco.standardVariant }

    var body: some View {
        NavigationStack {
            Form {
                Section("Variante") {
                    ForEach(Truco.Variant.all, id: \.target) { option in
                        let allowed = option == variant || match.allows(option, Truco.self)
                        Button {
                            try? match.changeVariant(Truco.self, to: option)
                        } label: {
                            HStack {
                                Text("A \(option.target)")
                                    .foregroundStyle(Color.primary)
                                    .opacity(allowed ? 1 : 0.4)
                                Spacer()
                                if option == variant {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .disabled(!allowed)
                        .accessibilityAddTraits(option == variant ? .isSelected : [])
                    }
                }

                Section("Equipos") {
                    ForEach(Array(match.orderedParticipants.enumerated()), id: \.offset) { index, team in
                        VStack(alignment: .leading, spacing: 4) {
                            TextField(Truco.defaultTeamName(at: index, players: []), text: binding(for: index))
                                .submitLabel(.done)
                                .onSubmit { commit(index) }
                            let players = team.orderedSeats.map(\.name)
                            if !players.isEmpty {
                                Text(players.joined(separator: ", "))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .onAppear {
                teamNames = match.orderedParticipants.map(\.name)
            }
            .onDisappear {
                for index in teamNames.indices { commit(index) }
            }
        }
        .environment(\.colorScheme, .dark)
        .presentationDetents([.medium, .large])
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { teamNames.indices.contains(index) ? teamNames[index] : "" },
            set: { newValue in
                guard teamNames.indices.contains(index) else { return }
                teamNames[index] = TeamName.limited(newValue)
            }
        )
    }

    private func commit(_ index: Int) {
        guard teamNames.indices.contains(index) else { return }
        try? match.renameTeam(at: index, to: teamNames[index], Truco.self)
        teamNames[index] = match.orderedParticipants[index].name
    }
}
