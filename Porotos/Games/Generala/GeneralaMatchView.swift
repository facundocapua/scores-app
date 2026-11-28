import SwiftData
import SwiftUI

/// The Generala Match screen (SPEC §5.3, `DESIGN.md` Generala): the Scoresheet on casino felt,
/// with Undo and "⋯" (details and "Terminar partida") in the navigation bar. On the end it
/// shows the Winners, the final scores, "Revancha" and "Inicio".
struct GeneralaMatchView: View {
    @Bindable var match: Match
    var onRematch: () -> Void
    var onHome: () -> Void
    /// Leaves and deletes the Match (it is deleted once the screen is gone).
    var onDiscard: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editing: GeneralaCell?
    @State private var showingDetails = false
    @State private var endingOptions = false
    @State private var confirmingDiscard = false
    @State private var cellTick = 0
    @State private var undoTick = 0

    private var variant: Generala.Variant { (try? match.variant(Generala.self)) ?? .standard }
    private var entries: [Generala.Entry] { (try? match.log(Generala.self).entries) ?? [] }
    private var names: [String] { match.orderedParticipants.map(\.name) }
    private var isFinished: Bool { match.status == .finished }

    var body: some View {
        let outcome = (try? match.outcome(Generala.self)) ?? .inProgress(Array(repeating: 0, count: names.count))
        NavigationStack {
            ZStack {
                GeneralaWorld.background
                if isFinished {
                    GeneralaEndView(
                        names: names,
                        entries: entries,
                        variant: variant,
                        outcome: outcome,
                        onRematch: onRematch,
                        onHome: onHome
                    )
                    .transition(.opacity)
                } else {
                    GeneralaScoresheet(
                        names: names,
                        entries: entries,
                        variant: variant,
                        turn: Generala.turn(participantCount: names.count, entries: entries),
                        onSelect: { editing = GeneralaCell(participant: $0, category: $1) }
                    )
                    .transition(.opacity)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.35), value: isFinished)
            .foregroundStyle(GeneralaWorld.ink)
            .toolbar { toolbar }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Terminar partida", isPresented: $endingOptions, titleVisibility: .visible) {
                Button("Terminar con este resultado") { try? match.endEarly() }
                Button("Descartar partida", role: .destructive) { confirmingDiscard = true }
            }
            .confirmationDialog("¿Descartar la partida?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Descartar partida", role: .destructive, action: onDiscard)
            }
        }
        .tint(GeneralaWorld.brass)
        .environment(\.colorScheme, .dark)
        .keepsScreenOn(!isFinished)
        .sensoryFeedback(.impact(weight: .light), trigger: cellTick)
        .sensoryFeedback(.warning, trigger: undoTick)
        .sensoryFeedback(.success, trigger: isFinished) { old, new in !old && new }
        .sheet(item: $editing) { cell in
            GeneralaCellSheet(match: match, cell: cell) { cellTick += 1 }
        }
        .sheet(isPresented: $showingDetails) {
            GeneralaDetailsSheet(match: match)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if !isFinished {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onHome) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                        Text("Inicio")
                    }
                }
                .accessibilityLabel("Inicio")
            }
            ToolbarItem(placement: .principal) {
                Text("Generala")
                    .font(DisplayFont.abrilFatface.scaled(22, relativeTo: .title2))
                    .foregroundStyle(GeneralaWorld.brass)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Deshacer", action: undo)
                .disabled(!match.canUndo(Generala.self))
            if !isFinished {
                Menu {
                    Button("Detalles", systemImage: "info.circle") { showingDetails = true }
                    Button("Terminar partida", systemImage: "flag.checkered") { endingOptions = true }
                } label: {
                    Label("Más", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    private func undo() {
        guard match.canUndo(Generala.self) else { return }
        try? match.undo(Generala.self)
        undoTick += 1
    }
}

/// The Generala end (SPEC §5.4): the Winners or "Empate", everyone's final score (with
/// positions when there are more than two Players), "Revancha" and "Inicio". The Scoresheet
/// can be viewed read-only. Undo stays in the navigation bar.
struct GeneralaEndView: View {
    var names: [String]
    var entries: [Generala.Entry]
    var variant: Generala.Variant
    var outcome: Outcome
    var onRematch: () -> Void
    var onHome: () -> Void

    @State private var showingSheet = false

    private var winnerNames: [String] {
        outcome.winners.compactMap { names.indices.contains($0) ? names[$0] : nil }
    }

    private var isTie: Bool { winnerNames.count != 1 }

    /// Everyone, best first; ties keep the Turn order. Whoever won by a Served Generala is
    /// first even without the highest total.
    private var ranking: [(index: Int, position: Int)] {
        let positions = outcome.scores.indices.map { index -> Int in
            if outcome.winners.contains(index) { return 1 }
            let others = outcome.scores.indices.filter { !outcome.winners.contains($0) }
            return 1 + outcome.winners.count + others.filter { outcome.scores[$0] > outcome.scores[index] }.count
        }
        return names.indices
            .sorted { (positions[$0], $0) < (positions[$1], $1) }
            .map { ($0, positions[$0]) }
    }

    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                if !isTie {
                    Text("Ganó")
                        .font(.title3)
                        .foregroundStyle(GeneralaWorld.dim)
                }
                Text(isTie ? "Empate" : winnerNames[0])
                    .font(DisplayFont.abrilFatface.scaled(48, relativeTo: .largeTitle))
                    .foregroundStyle(GeneralaWorld.brass)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .accessibilityAddTraits(.isHeader)
                if isTie {
                    Text(winnerNames.joined(separator: " · "))
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            ScrollView {
                scores
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button("Ver planilla") { showingSheet = true }
                .frame(minHeight: 44)

            VStack(spacing: 12) {
                Button(action: onRematch) {
                    Text("Revancha")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .foregroundStyle(GeneralaWorld.feltDark)
                        .background(GeneralaWorld.brass, in: RoundedRectangle(cornerRadius: 16))
                }
                Button(action: onHome) {
                    Text("Inicio")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(GeneralaWorld.ink)
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                ZStack {
                    GeneralaWorld.background
                    GeneralaScoresheet(names: names, entries: entries, variant: variant, turn: nil, onSelect: nil)
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

    private var scores: some View {
        VStack(spacing: 0) {
            ForEach(ranking, id: \.index) { row in
                HStack(spacing: 12) {
                    if names.count > 2 {
                        Text(Outcome.ordinal(row.position))
                            .font(.headline)
                            .foregroundStyle(GeneralaWorld.dim)
                            .frame(minWidth: 36, alignment: .leading)
                    }
                    Text(names[row.index])
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(outcome.scores[row.index])")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(GeneralaWorld.brass.opacity(0.25)).frame(height: 1)
                }
            }
        }
    }
}

#Preview("In progress") {
    let container = try! Store.container(inMemory: true)
    let people = ["Ana", "Beto", "Caro", "Facundo", "Lu", "Martín"].map { Player(name: $0) }
    people.forEach { container.mainContext.insert($0) }
    let match = try! Match.create(Generala.self, variant: .standard, participants: people.map { .player($0) }, in: container.mainContext)
    try! match.modify(Generala.self) { Generala.place(.points(30), in: .fullHouse, of: 0, log: &$0) }
    try! match.modify(Generala.self) { Generala.place(.scratched, in: .straight, of: 1, log: &$0) }
    return GeneralaMatchView(match: match, onRematch: {}, onHome: {}, onDiscard: {}).modelContainer(container)
}
