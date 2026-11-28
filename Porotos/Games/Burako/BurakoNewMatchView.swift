import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// A seat being dragged on the New Match screen: its position in the list of Players (in
/// individual) or among the four spots (in Pairs).
private struct SeatDrag: Codable, Transferable {
    var index: Int

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

/// The New Match screen for Burako (SPEC §5.2): "Individual" or "Parejas", the Players (swapped
/// by dragging in Pairs, ordered by dragging in individual), the automatic Team names, the
/// Target score and the Muerto, with "Empezar" fixed at the bottom. It preloads the setup it is
/// given (the remembered one, or a Rematch's).
struct BurakoNewMatchView: View {
    var onStart: (Match) -> Void
    var onCancel: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPairs: Bool
    /// The Players in individual, in order.
    @State private var individual: [Player]
    /// The four spots in Pairs: 1 and 2 against 3 and 4.
    @State private var spots: [Player?]
    /// A Team name edited by hand. `nil` means the automatic one.
    @State private var customNames: [String?]
    /// A preset Target score, or `Self.otherTarget`.
    @State private var targetChoice: Int
    @State private var otherTarget: String
    @State private var muerto: Burako.Muerto
    @State private var picking: Picking?
    @FocusState private var otherFocused: Bool

    private static let otherTarget = 0

    private enum Picking: Identifiable {
        case individual
        case spot(Int)

        var id: Int {
            switch self {
            case .individual: -1
            case .spot(let index): index
            }
        }
    }

    init(setup: MatchSetup<Burako.Variant>, onStart: @escaping (Match) -> Void, onCancel: @escaping () -> Void) {
        self.onStart = onStart
        self.onCancel = onCancel

        let pairs = Burako.isPairs(setup.participants)
        var spots: [Player?] = Array(repeating: nil, count: 4)
        var custom: [String?] = [nil, nil]
        var individual: [Player] = []
        if pairs {
            for pair in 0..<2 where setup.participants.indices.contains(pair) {
                let draft = setup.participants[pair]
                for seat in 0..<2 where draft.players.indices.contains(seat) {
                    spots[pair * 2 + seat] = draft.players[seat]
                }
                let automatic = Burako.defaultTeamName(at: pair, players: spots[pair * 2...pair * 2 + 1].compactMap { $0?.name })
                if let name = draft.teamName, !name.isEmpty, name != automatic { custom[pair] = name }
            }
        } else {
            individual = Array(setup.participants.flatMap(\.players).compactMap { $0 }.prefix(Burako.maxPlayers))
        }
        _isPairs = State(initialValue: pairs)
        _spots = State(initialValue: spots)
        _customNames = State(initialValue: custom)
        _individual = State(initialValue: individual)

        let target = setup.variant.target
        _targetChoice = State(initialValue: Burako.Variant.presets.contains(target) ? target : Self.otherTarget)
        _otherTarget = State(initialValue: Burako.Variant.presets.contains(target) ? "" : String(target))
        _muerto = State(initialValue: setup.variant.muerto)
    }

    // MARK: - Derived

    private var chosen: Set<PersistentIdentifier> {
        let players = isPairs ? spots.compactMap { $0 } : individual
        return Set(players.map(\.persistentModelID))
    }

    private func automaticName(_ pair: Int) -> String {
        let names = spots[pair * 2...pair * 2 + 1].compactMap { $0?.name }
        return Burako.defaultTeamName(at: pair, players: names)
    }

    private func teamName(_ pair: Int) -> String {
        TeamName.resolved(customNames[pair] ?? "", default: automaticName(pair))
    }

    private var drafts: [ParticipantDraft] {
        if isPairs {
            return (0..<2).map { .team(teamName($0), players: [spots[$0 * 2], spots[$0 * 2 + 1]]) }
        }
        return individual.map { .player($0) }
    }

    private var target: Int? {
        let value = targetChoice == Self.otherTarget ? Int(otherTarget) : targetChoice
        guard let value, Burako.Variant.isValidTarget(value) else { return nil }
        return value
    }

    private var canStart: Bool {
        target != nil && Burako.canStart(with: drafts)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    modePicker
                }

                if isPairs {
                    ForEach(0..<2, id: \.self) { pair in
                        pairSection(pair)
                    }
                } else {
                    individualSection
                }

                variantSection
            }
            .navigationTitle("Burako")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCancel)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { otherFocused = false }
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
                .disabled(!canStart)
            }
            .sheet(item: $picking) { picking in
                PlayerPicker(excluded: chosen) { player in
                    switch picking {
                    case .individual: individual.append(player)
                    case .spot(let index): setSpot(index, to: player)
                    }
                }
            }
        }
    }

    // MARK: - Mode

    private var modePicker: some View {
        Picker("Modo", selection: Binding(get: { isPairs }, set: setPairs)) {
            Text("Individual").tag(false)
            Text("Parejas").tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("Modo")
    }

    /// Switching modes keeps the chosen Players: the pairs are formed as 1 and 2 against 3
    /// and 4 (SPEC §5.2).
    private func setPairs(_ pairs: Bool) {
        guard pairs != isPairs else { return }
        if pairs {
            let players = Array(individual.prefix(4))
            spots = (0..<4).map { players.indices.contains($0) ? players[$0] : nil }
            customNames = [nil, nil]
        } else {
            individual = spots.compactMap { $0 }
        }
        isPairs = pairs
    }

    // MARK: - Individual

    private var individualSection: some View {
        Section("Jugadores") {
            ForEach(Array(individual.enumerated()), id: \.element.persistentModelID) { index, player in
                seatRow(
                    name: player.name,
                    remove: { individual.remove(at: index) },
                    index: index,
                    targets: [
                        index > 0 ? ("Subir", index - 1) : nil,
                        index < individual.count - 1 ? ("Bajar", index + 1) : nil,
                    ].compactMap { $0 },
                    move: moveIndividual
                )
            }
            if individual.count < Burako.maxPlayers {
                Button("Agregar jugador") { picking = .individual }
                    .frame(minHeight: 44, alignment: .leading)
            }
        }
    }

    private func moveIndividual(_ source: Int, _ destination: Int) {
        guard individual.indices.contains(source), individual.indices.contains(destination), source != destination else { return }
        individual.insert(individual.remove(at: source), at: destination)
    }

    // MARK: - Pairs

    private func pairSection(_ pair: Int) -> some View {
        Section("Pareja \(pair + 1)") {
            TextField(automaticName(pair), text: nameBinding(pair))
                .submitLabel(.done)
                .accessibilityLabel("Nombre de la pareja \(pair + 1)")
            ForEach(0..<2, id: \.self) { seat in
                let index = pair * 2 + seat
                if let player = spots[index] {
                    seatRow(
                        name: player.name,
                        remove: { setSpot(index, to: nil) },
                        index: index,
                        targets: (0..<4).filter { $0 != index }.map { ("Intercambiar con \(spots[$0]?.name ?? "lugar vacío")", $0) },
                        move: swapSpots
                    )
                } else {
                    Button("Agregar jugador") { picking = .spot(index) }
                        .frame(minHeight: 44, alignment: .leading)
                        .dropDestination(for: SeatDrag.self) { items, _ in
                            guard let item = items.first else { return false }
                            swapSpots(item.index, index)
                            return true
                        }
                }
            }
        }
    }

    private func setSpot(_ index: Int, to player: Player?) {
        spots[index] = player
        customNames[index / 2] = nil
    }

    /// Swaps two spots (a Player with another, or with an empty one). A pair that changes
    /// goes back to its automatic name (SPEC §3.3).
    private func swapSpots(_ first: Int, _ second: Int) {
        guard spots.indices.contains(first), spots.indices.contains(second), first != second else { return }
        spots.swapAt(first, second)
        customNames[first / 2] = nil
        customNames[second / 2] = nil
    }

    private func nameBinding(_ pair: Int) -> Binding<String> {
        Binding(
            get: { customNames[pair] ?? automaticName(pair) },
            set: { text in
                let limited = TeamName.limited(text)
                let cleaned = limited.trimmingCharacters(in: .whitespacesAndNewlines)
                customNames[pair] = (cleaned.isEmpty || limited == automaticName(pair)) ? nil : limited
            }
        )
    }

    // MARK: - Rows

    /// A Player's row: draggable, removable, with accessibility actions for moving it (no
    /// hidden gestures, SPEC §8).
    private func seatRow(
        name: String,
        remove: @escaping () -> Void,
        index: Int,
        targets: [(title: String, index: Int)],
        move: @escaping (_ from: Int, _ to: Int) -> Void
    ) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: remove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quitar a \(name)")
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .draggable(SeatDrag(index: index))
        .dropDestination(for: SeatDrag.self) { items, _ in
            guard let item = items.first else { return false }
            move(item.index, index)
            return true
        }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            ForEach(targets, id: \.index) { target in
                Button(target.title) { move(index, target.index) }
            }
        }
    }

    // MARK: - Variant

    /// Segmented, or a menu at accessibility sizes, where the segments don't fit.
    @ViewBuilder
    private var targetPicker: some View {
        let picker = Picker("Meta", selection: $targetChoice) {
            ForEach(Burako.Variant.presets, id: \.self) { preset in
                Text(String(preset)).tag(preset)
            }
            Text("Otra").tag(Self.otherTarget)
        }
        if dynamicTypeSize.isAccessibilitySize {
            picker.pickerStyle(.menu)
        } else {
            picker.pickerStyle(.segmented)
        }
    }

    private var variantSection: some View {
        Section("Variante") {
            targetPicker

            if targetChoice == Self.otherTarget {
                HStack {
                    Text("Otra")
                    TextField("3000", text: $otherTarget)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($otherFocused)
                        .onChange(of: otherTarget) { _, text in
                            let digits = String(text.filter(\.isNumber).prefix(5))
                            if digits != text { otherTarget = digits }
                        }
                        .accessibilityLabel("Meta")
                }
                .frame(minHeight: 44)
            }

            Picker("Muerto", selection: $muerto) {
                ForEach(Burako.Muerto.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - Start

    private func start() {
        guard let target else { return }
        do {
            let match = try Match.create(
                Burako.self,
                variant: Burako.Variant(target: target, muerto: muerto),
                participants: drafts,
                in: context
            )
            onStart(match)
        } catch {
            assertionFailure("Could not create the Match: \(error)")
        }
    }
}

#Preview("First time") {
    BurakoNewMatchView(
        setup: MatchSetup(variant: Burako.standardVariant, participants: Burako.initialParticipants),
        onStart: { _ in },
        onCancel: {}
    )
    .modelContainer(try! Store.container(inMemory: true))
}
