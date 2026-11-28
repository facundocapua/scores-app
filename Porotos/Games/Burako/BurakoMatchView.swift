import SwiftData
import SwiftUI

/// The Burako Match screen (SPEC §5.3, `DESIGN.md` Burako): the race toward the Target score,
/// with a rack of tiles per Participant and the Hands as chips. "Anotar mano N" opens the
/// calculator, and tapping a chip opens that Hand to correct it. Undo and "⋯" are at the top.
struct BurakoMatchView: View {
    @Bindable var match: Match
    var onRematch: () -> Void
    var onHome: () -> Void
    /// Leaves and deletes the Match (it is deleted once the screen is gone).
    var onDiscard: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var calculator: BurakoCalculatorMode?
    @State private var showingDetails = false
    @State private var endingOptions = false
    @State private var confirmingDiscard = false
    @State private var restoredDraft = false
    @State private var handTick = 0
    @State private var undoTick = 0

    private var variant: Burako.Variant { (try? match.variant(Burako.self)) ?? Burako.standardVariant }
    private var names: [String] { match.orderedParticipants.map(\.name) }
    private var hands: [Burako.Hand] { (try? match.log(Burako.self).entries) ?? [] }
    private var isFinished: Bool { match.status == .finished }

    private var outcome: Outcome {
        (try? match.outcome(Burako.self)) ?? .inProgress(Array(repeating: 0, count: names.count))
    }

    private var animation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35)
    }

    var body: some View {
        let outcome = outcome
        NavigationStack {
            ZStack {
                if isFinished {
                    BurakoEndView(
                        names: names,
                        outcome: outcome,
                        endedEarly: match.endedEarly,
                        handCount: hands.count,
                        onOpenHand: { calculator = .view($0) },
                        onRematch: onRematch,
                        onHome: onHome
                    )
                    .transition(.opacity)
                } else {
                    race(scores: outcome.scores)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.35), value: isFinished)
            .background(BurakoWorld.background)
            .toolbar { toolbar }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(BurakoWorld.action)
        .environment(\.colorScheme, .dark)
        .keepsScreenOn(!isFinished)
        .sensoryFeedback(.impact(weight: .light), trigger: handTick)
        .sensoryFeedback(.warning, trigger: undoTick)
        .sensoryFeedback(.success, trigger: isFinished) { old, new in !old && new }
        .sheet(item: $calculator) { mode in
            BurakoCalculatorView(match: match, mode: mode, onSaved: { handTick += 1 })
        }
        .sheet(isPresented: $showingDetails) {
            BurakoDetailsSheet(match: match)
        }
        .confirmationDialog("Terminar partida", isPresented: $endingOptions, titleVisibility: .visible) {
            Button("Terminar con este resultado") { try? match.endEarly() }
            Button("Descartar partida", role: .destructive) { confirmingDiscard = true }
        }
        .confirmationDialog("¿Descartar la partida?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
            Button("Descartar partida", role: .destructive, action: onDiscard)
        }
        .task {
            // A half-entered Hand comes back where it was left (SPEC §6.5).
            guard !restoredDraft, !isFinished else { return }
            restoredDraft = true
            if let draft = try? match.draft(Burako.Draft.self), !draft.hand.isBlank {
                calculator = .new
            }
        }
    }

    // MARK: - Race

    private func race(scores: [Int]) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(names.indices, id: \.self) { index in
                    rack(name: names[index], score: scores.indices.contains(index) ? scores[index] : 0)
                }
                if !hands.isEmpty {
                    handChips
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .foregroundStyle(BurakoWorld.ink)
        .safeAreaInset(edge: .bottom) {
            Button { calculator = .new } label: {
                Text("Anotar mano \(hands.count + 1)")
                    .font(DisplayFont.alfaSlabOne.scaled(22, relativeTo: .title2))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .foregroundStyle(BurakoWorld.ground2)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(BurakoWorld.action, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial.opacity(0.6))
        }
    }

    /// A Participant's rack: the name, the total in tiles, the progress toward the Target score
    /// and "faltan N".
    private func rack(name: String, score: Int) -> some View {
        let remaining = Burako.remaining(score: score, target: variant.target)
        return VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    Text(name).font(DisplayFont.alfaSlabOne.scaled(20, relativeTo: .title3))
                    Spacer(minLength: 8)
                    Text("faltan \(Burako.grouped(remaining))")
                        .font(.subheadline)
                        .foregroundStyle(BurakoWorld.dim)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(DisplayFont.alfaSlabOne.scaled(20, relativeTo: .title3))
                    Text("faltan \(Burako.grouped(remaining))")
                        .font(.subheadline)
                        .foregroundStyle(BurakoWorld.dim)
                }
            }
            TileNumber(value: score, height: 54)
                .animation(animation, value: score)
            RaceBar(score: score, target: variant.target)
                .animation(animation, value: score)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BurakoWorld.surface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(Burako.spokenTotal(score: score, target: variant.target))
    }

    private var handChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Manos")
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(BurakoWorld.dim)
                .accessibilityAddTraits(.isHeader)
            HandChips(count: hands.count) { calculator = .edit($0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Deshacer", action: undo)
                .disabled(!match.canUndo(Burako.self))
            if !isFinished {
                Menu {
                    Button("Detalles", systemImage: "info.circle") { showingDetails = true }
                    Button("Terminar partida", systemImage: "flag.checkered", role: .destructive) {
                        endingOptions = true
                    }
                } label: {
                    Label("Más", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    private func undo() {
        guard match.canUndo(Burako.self) else { return }
        try? match.undo(Burako.self)
        undoTick += 1
    }
}

/// The Hands played, as tiles: tapping one opens it.
struct HandChips: View {
    var count: Int
    var action: (Int) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Button { action(index) } label: {
                    Text("\(index + 1)")
                        .font(DisplayFont.alfaSlabOne.fixed(20))
                        .foregroundStyle(BurakoWorld.tileColors[index % BurakoWorld.tileColors.count])
                        .frame(minWidth: 48, minHeight: 48)
                        .background(BurakoWorld.ivory, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(BurakoWorld.ivoryEdge, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mano \(index + 1)")
            }
        }
    }
}

/// The Burako end (SPEC §5.4), in its world: the Winners (or "Empate"), everyone's final
/// score with positions when there are more than two Participants, the Hands to look at,
/// "Revancha" and "Inicio". Undo stays in the navigation bar.
struct BurakoEndView: View {
    var names: [String]
    var outcome: Outcome
    var endedEarly: Bool
    var handCount: Int
    var onOpenHand: (Int) -> Void
    var onRematch: () -> Void
    var onHome: () -> Void

    private var headline: String {
        let winners = outcome.winners.compactMap { names.indices.contains($0) ? names[$0] : nil }
        guard winners.count == 1, let winner = winners.first else { return "Empate" }
        return "¡Ganó \(winner)!"
    }

    /// Participants from the highest score to the lowest, keeping their order on a tie.
    private var ranking: [Int] {
        names.indices.sorted { outcome.scores[$0] > outcome.scores[$1] }
    }

    var body: some View {
        let positions = outcome.positions()
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(headline)
                        .font(DisplayFont.alfaSlabOne.scaled(36, relativeTo: .largeTitle))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    if endedEarly {
                        Text("Terminada antes")
                            .font(.subheadline)
                            .foregroundStyle(BurakoWorld.dim)
                    }
                }
                .padding(.top, 12)

                VStack(spacing: 10) {
                    ForEach(ranking, id: \.self) { index in
                        row(index, position: positions[index])
                    }
                }

                if handCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manos")
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .foregroundStyle(BurakoWorld.dim)
                            .accessibilityAddTraits(.isHeader)
                        HandChips(count: handCount, action: onOpenHand)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .foregroundStyle(BurakoWorld.ink)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                Button(action: onRematch) {
                    Text("Revancha")
                        .font(DisplayFont.alfaSlabOne.scaled(22, relativeTo: .title2))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundStyle(BurakoWorld.ground2)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(BurakoWorld.action, in: RoundedRectangle(cornerRadius: 18))
                }
                Button(action: onHome) {
                    Text("Inicio")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial.opacity(0.6))
        }
    }

    private func row(_ index: Int, position: Int) -> some View {
        let isWinner = outcome.winners.contains(index)
        let score = outcome.scores[index]
        return HStack(spacing: 12) {
            if names.count > 2 {
                Text(Outcome.ordinal(position))
                    .font(.headline)
                    .foregroundStyle(isWinner ? BurakoWorld.action : BurakoWorld.dim)
                    .frame(minWidth: 40, alignment: .leading)
            }
            Text(names[index])
                .font(DisplayFont.alfaSlabOne.scaled(18, relativeTo: .headline))
                .foregroundStyle(isWinner ? BurakoWorld.action : BurakoWorld.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            TileNumber(value: score, height: 34)
        }
        .padding(12)
        .background(BurakoWorld.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(names.count > 2 ? "\(Outcome.ordinal(position)), \(names[index])" : names[index])
        .accessibilityValue(score < 0 ? "menos \(Burako.grouped(-score))" : Burako.grouped(score))
    }
}

#Preview("Race") {
    let container = try! Store.container(inMemory: true)
    let match = try! Match.create(
        Burako.self,
        variant: Burako.standardVariant,
        participants: [.team("Facu y Caro"), .team("Juli y Beto")],
        in: container.mainContext
    )
    var hand = Burako.Hand(participantCount: 2)
    hand.lines[0] = .init(cleanCanastas: 2, dirtyCanastas: 1, tilesMelded: 340, tilesInHand: 20, wentOut: true, tookMuerto: true)
    hand.lines[1] = .init(dirtyCanastas: 1, tilesMelded: 120, tilesInHand: 60, tookMuerto: true)
    try! match.modify(Burako.self) { $0.add(hand) }
    return BurakoMatchView(match: match, onRematch: {}, onHome: {}, onDiscard: {}).modelContainer(container)
}
