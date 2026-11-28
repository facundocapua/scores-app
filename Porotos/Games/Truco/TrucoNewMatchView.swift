import SwiftData
import SwiftUI

/// The New Match screen for Truco (SPEC §5.2): the two Team names, "Agregar Jugadores" as a
/// secondary action, the 15/30 segmented control and "Empezar" fixed at the bottom. It
/// preloads the setup it is given (the remembered one, or a Rematch's).
struct TrucoNewMatchView: View {
    var onStart: (Match) -> Void
    var onCancel: () -> Void

    @Environment(\.modelContext) private var context
    @State private var names: [String]
    @State private var players: [[Player]]
    @State private var target: Int
    @State private var showsPlayers: Bool
    @State private var pickingFor: PickingTeam?

    private struct PickingTeam: Identifiable {
        var id: Int
    }

    init(setup: MatchSetup<Truco.Variant>, onStart: @escaping (Match) -> Void, onCancel: @escaping () -> Void) {
        self.onStart = onStart
        self.onCancel = onCancel
        let drafts = (0..<2).map { setup.participants.indices.contains($0) ? setup.participants[$0] : Truco.initialParticipants[$0] }
        let players = drafts.map { $0.players.compactMap { $0 } }
        _names = State(initialValue: drafts.enumerated().map { $1.teamName ?? Truco.teamNames[$0] })
        _players = State(initialValue: players)
        _target = State(initialValue: setup.variant.target)
        _showsPlayers = State(initialValue: players.contains { !$0.isEmpty })
    }

    private var chosen: Set<PersistentIdentifier> {
        Set(players.flatMap { $0 }.map(\.persistentModelID))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Equipos") {
                    ForEach(0..<2, id: \.self) { team in
                        TextField(Truco.teamNames[team], text: nameBinding(team))
                            .submitLabel(.done)
                    }
                    if !showsPlayers {
                        Button("Agregar Jugadores") { showsPlayers = true }
                    }
                }

                if showsPlayers {
                    ForEach(0..<2, id: \.self) { team in
                        Section(TeamName.resolved(names[team], default: Truco.teamNames[team])) {
                            ForEach(players[team]) { player in
                                Text(player.name)
                            }
                            .onDelete { players[team].remove(atOffsets: $0) }
                            Button("Agregar jugador") { pickingFor = PickingTeam(id: team) }
                        }
                    }
                }

                Section("Variante") {
                    Picker("Puntos", selection: $target) {
                        ForEach(Truco.Variant.all, id: \.target) { option in
                            Text("A \(option.target)").tag(option.target)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            .navigationTitle("Truco")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCancel)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: start) {
                    Text("Empezar")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                // The red fill carries light text in both modes (the dark-mode brand tint is for text).
                .tint(Color.brandFill)
                .controlSize(.large)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
                .disabled(!Truco.canStart(with: drafts))
            }
            .sheet(item: $pickingFor) { picking in
                PlayerPicker(excluded: chosen) { players[picking.id].append($0) }
            }
        }
    }

    private var drafts: [ParticipantDraft] {
        (0..<2).map { team in
            .team(TeamName.resolved(names[team], default: Truco.teamNames[team]), players: players[team])
        }
    }

    private func nameBinding(_ team: Int) -> Binding<String> {
        Binding(
            get: { names[team] },
            set: { names[team] = TeamName.limited($0) }
        )
    }

    private func start() {
        do {
            let match = try Match.create(Truco.self, variant: Truco.Variant(target: target), participants: drafts, in: context)
            onStart(match)
        } catch {
            assertionFailure("Could not create the Match: \(error)")
        }
    }
}

#Preview {
    TrucoNewMatchView(
        setup: MatchSetup(variant: Truco.standardVariant, participants: Truco.initialParticipants),
        onStart: { _ in },
        onCancel: {}
    )
    .modelContainer(try! Store.container(inMemory: true))
}
