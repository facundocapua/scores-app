import SwiftData
import SwiftUI

/// What the Player picker shows for a search (SPEC §5.2). Kept apart from the view so it can
/// be tested.
struct PlayerPickerOptions {
    /// The Players to choose from: the exact match first, then those who played most
    /// recently. Those already in the Match are left out.
    var players: [Player]
    /// The name for "Agregar «Nombre»", which creates the Player and picks them. `nil` when
    /// nothing is typed or the name is taken (then the existing Player is offered instead,
    /// unless they are already in the Match).
    var nameToAdd: String?

    /// - Parameter players: every Player, most recently played first.
    init(players: [Player], query: String, excluded: Set<PersistentIdentifier>) {
        let available = players.filter { !excluded.contains($0.persistentModelID) }
        let found = available.filter { PlayerName.matches($0.name, query: query) }
        let cleaned = PlayerName.cleaned(PlayerName.limited(query))

        self.players = found
        self.nameToAdd = nil
        guard !cleaned.isEmpty else { return }
        if let exact = players.first(where: { PlayerName.isSame($0.name, cleaned) }) {
            if !excluded.contains(exact.persistentModelID) {
                self.players = [exact] + found.filter { $0.persistentModelID != exact.persistentModelID }
            }
        } else {
            self.nameToAdd = cleaned
        }
    }
}

/// The reusable Player picker for the New Match screen (SPEC §5.2): search, most recently
/// played first, "Agregar «Nombre»", and those already chosen hidden. It is shown in a sheet
/// and closes on picking.
struct PlayerPicker: View {
    /// The Players already in the Match.
    var excluded: Set<PersistentIdentifier> = []
    var onPick: (Player) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allPlayers: [Player]
    @State private var query = ""

    private var options: PlayerPickerOptions {
        let ordered = (try? Player.byMostRecentlyPlayed(in: context)) ?? allPlayers
        return PlayerPickerOptions(players: ordered, query: query, excluded: excluded)
    }

    var body: some View {
        NavigationStack {
            let options = options
            List {
                if let name = options.nameToAdd {
                    Button {
                        add(name)
                    } label: {
                        Label("Agregar «\(name)»", systemImage: "plus.circle.fill")
                    }
                }

                ForEach(options.players) { player in
                    Button {
                        pick(player)
                    } label: {
                        Text(player.name)
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar o agregar"
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .onChange(of: query) { _, newValue in
                let limited = PlayerName.limited(newValue)
                if limited != newValue { query = limited }
            }
            .onSubmit(of: .search) {
                if let name = options.nameToAdd {
                    add(name)
                } else if let first = options.players.first, PlayerName.isSame(first.name, query) {
                    pick(first)
                }
            }
            .navigationTitle("Elegir jugador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func add(_ name: String) {
        do {
            pick(try Player.add(named: name, in: context))
        } catch {
            assertionFailure("Could not add the Player: \(error)")
        }
    }

    private func pick(_ player: Player) {
        onPick(player)
        dismiss()
    }
}

/// A stand-in for the New Match screen, to try the picker in isolation.
private struct PlayerPickerPreview: View {
    @State private var chosen: [Player] = []
    @State private var picking = false

    var body: some View {
        NavigationStack {
            List {
                Section("Elegidos") {
                    ForEach(chosen) { Text($0.name) }
                        .onDelete { chosen.remove(atOffsets: $0) }
                }
                Button("Agregar jugador") { picking = true }
            }
            .navigationTitle("Nueva partida")
            .sheet(isPresented: $picking) {
                PlayerPicker(excluded: Set(chosen.map(\.persistentModelID))) { chosen.append($0) }
            }
        }
    }
}

#Preview("Player picker") {
    let container = try! Store.container(inMemory: true)
    for name in ["Facu", "Caro", "Ángel", "Beto", "Juli"] {
        container.mainContext.insert(Player(name: name))
    }
    return PlayerPickerPreview().modelContainer(container)
}

#Preview("Player picker, no Players") {
    PlayerPickerPreview().modelContainer(try! Store.container(inMemory: true))
}
