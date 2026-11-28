import SwiftData
import SwiftUI

/// The Players tab (SPEC §5.6): alphabetical list with "+", and a sheet to rename or delete.
/// There is no Player profile and there are no counters.
struct PlayersView: View {
    @Query private var players: [Player]
    @State private var editing: PlayerEditor.Mode?

    private var sorted: [Player] {
        players.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if players.isEmpty {
                    ContentUnavailableView {
                        Label("Acá va a estar la barra", systemImage: "person.2")
                    } actions: {
                        Button("Agregar jugador") { editing = .add }
                            .buttonStyle(.borderedProminent)
                            // The red fill carries light text in both modes (the dark-mode brand tint is for text).
                            .tint(Color.brandFill)
                    }
                } else {
                    List(sorted) { player in
                        Button {
                            editing = .edit(player)
                        } label: {
                            Text(player.name)
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .accessibilityHint("Cambiar el nombre o borrar")
                    }
                }
            }
            .navigationTitle("Jugadores")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { editing = .add } label: {
                        Label("Agregar jugador", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editing) { mode in
                PlayerEditor(mode: mode)
            }
        }
    }
}

/// The sheet to add, rename or delete a Player.
struct PlayerEditor: View {
    enum Mode: Identifiable {
        case add
        case edit(Player)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let player): "\(player.persistentModelID.hashValue)"
            }
        }
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var confirmingDelete = false
    @FocusState private var focused: Bool

    init(mode: Mode) {
        self.mode = mode
        if case .edit(let player) = mode {
            _name = State(initialValue: player.name)
        } else {
            _name = State(initialValue: "")
        }
    }

    private var player: Player? {
        if case .edit(let player) = mode { return player }
        return nil
    }

    private var problem: PlayerNameError? {
        if let player { return player.renameProblem(name) }
        let existing = ((try? context.fetch(FetchDescriptor<Player>())) ?? []).map(\.name)
        if case .failure(let error) = PlayerName.validate(name, existing: existing) { return error }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre", text: $name)
                        .focused($focused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(save)
                        .onChange(of: name) { _, newValue in
                            let limited = PlayerName.limited(newValue)
                            if limited != newValue { name = limited }
                        }
                } footer: {
                    if case .taken = problem {
                        Label("Ya hay un jugador con ese nombre", systemImage: "exclamationmark.circle")
                            .foregroundStyle(Color.red)
                    }
                }

                if player != nil {
                    Section {
                        Button("Borrar jugador", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .navigationTitle(player == nil ? "Nuevo jugador" : "Jugador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save)
                        .disabled(problem != nil)
                }
            }
            .confirmationDialog(
                "¿Borrar a \(player?.name ?? "")?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Borrar", role: .destructive, action: delete)
            } message: {
                if player?.isPlayingMatchInProgress == true {
                    Text("Está jugando una partida en curso")
                }
            }
            .onAppear { focused = player == nil }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard problem == nil else { return }
        do {
            if let player {
                try player.rename(to: name)
            } else {
                try Player.add(named: name, in: context)
            }
            dismiss()
        } catch {
            assertionFailure("Could not save the Player: \(error)")
        }
    }

    private func delete() {
        do {
            try player?.delete()
            dismiss()
        } catch {
            assertionFailure("Could not delete the Player: \(error)")
        }
    }
}

#Preview("With Players") {
    let container = try! Store.container(inMemory: true)
    for name in ["Facu", "Caro", "Ángel", "beto"] {
        container.mainContext.insert(Player(name: name))
    }
    return PlayersView().modelContainer(container)
}

#Preview("Empty") {
    PlayersView().modelContainer(try! Store.container(inMemory: true))
}
