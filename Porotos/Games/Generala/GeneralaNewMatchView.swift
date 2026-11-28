import SwiftData
import SwiftUI

/// The New Match screen for Generala (SPEC §5.2): 2 to 6 Players picked with the Player
/// picker, dragged into Turn order (there is no draw), the "Generala servida gana" switch and
/// "Empezar" fixed at the bottom. It preloads the setup it is given (the remembered one, or a
/// Rematch's).
struct GeneralaNewMatchView: View {
    var onStart: (Match) -> Void
    var onCancel: () -> Void

    @Environment(\.modelContext) private var context
    @State private var players: [Player]
    @State private var servedGeneralaWins: Bool
    @State private var picking = false

    init(setup: MatchSetup<Generala.Variant>, onStart: @escaping (Match) -> Void, onCancel: @escaping () -> Void) {
        self.onStart = onStart
        self.onCancel = onCancel
        _players = State(initialValue: setup.participants.compactMap { $0.players.compactMap { $0 }.first })
        _servedGeneralaWins = State(initialValue: setup.variant.servedGeneralaWins)
    }

    private var drafts: [ParticipantDraft] {
        players.map { .player($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Jugadores") {
                    ForEach(players) { player in
                        Text(player.name)
                    }
                    .onMove { players.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { players.remove(atOffsets: $0) }
                    if players.count < Generala.maximumPlayers {
                        Button("Agregar jugador") { picking = true }
                            .frame(minHeight: 44)
                    }
                }

                Section("Variante") {
                    Toggle("Generala servida gana", isOn: $servedGeneralaWins)
                }
            }
            // The Turn order is dragged, so the handles are always visible.
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Generala")
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
                .controlSize(.large)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
                .disabled(!Generala.canStart(with: drafts))
            }
            .sheet(isPresented: $picking) {
                PlayerPicker(excluded: Set(players.map(\.persistentModelID))) { players.append($0) }
            }
        }
    }

    private func start() {
        do {
            let variant = Generala.Variant(servedGeneralaWins: servedGeneralaWins)
            let match = try Match.create(Generala.self, variant: variant, participants: drafts, in: context)
            onStart(match)
        } catch {
            assertionFailure("Could not create the Match: \(error)")
        }
    }
}

#Preview {
    GeneralaNewMatchView(
        setup: MatchSetup(variant: Generala.standardVariant, participants: Generala.initialParticipants),
        onStart: { _ in },
        onCancel: {}
    )
    .modelContainer(try! Store.container(inMemory: true))
}
