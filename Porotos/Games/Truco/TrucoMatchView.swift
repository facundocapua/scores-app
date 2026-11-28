import SwiftData
import SwiftUI

/// The Truco Match screen (SPEC §5.3, `DESIGN.md` Truco): two columns of matchsticks, +1 and −
/// per Team, Undo and "⋯" at the top, and "Terminar partida" isolated at the bottom. On the
/// end it inverts with "¡Ganaron …!".
struct TrucoMatchView: View {
    @Bindable var match: Match
    var onRematch: () -> Void
    var onHome: () -> Void
    /// Leaves and deletes the Match (it is deleted once the screen is gone).
    var onDiscard: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingDetails = false
    @State private var endingOptions = false
    @State private var confirmingDiscard = false
    @State private var pointTick = 0
    @State private var undoTick = 0

    private var variant: Truco.Variant { (try? match.variant(Truco.self)) ?? Truco.standardVariant }
    private var outcome: Outcome { (try? match.outcome(Truco.self)) ?? .inProgress([0, 0]) }
    private var names: [String] { match.orderedParticipants.map(\.name) }
    private var isFinished: Bool { match.status == .finished }

    private var animation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.3)
    }

    var body: some View {
        let outcome = outcome
        NavigationStack {
            ZStack {
                if isFinished {
                    TrucoEndView(
                        names: names,
                        outcome: outcome,
                        onRematch: onRematch,
                        onHome: onHome
                    )
                    .transition(.opacity)
                } else {
                    board(scores: outcome.scores)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.35), value: isFinished)
            .toolbar { toolbar }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(isFinished ? .light : .dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(isFinished ? TrucoWorld.ground : TrucoWorld.accent)
        .environment(\.colorScheme, .dark)
        .keepsScreenOn(!isFinished)
        .sensoryFeedback(.impact(weight: .light), trigger: pointTick)
        .sensoryFeedback(.warning, trigger: undoTick)
        .sensoryFeedback(.success, trigger: isFinished) { old, new in !old && new }
        .sheet(isPresented: $showingDetails) {
            TrucoDetailsSheet(match: match)
        }
    }

    // MARK: - Board

    private func board(scores: [Int]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { team in
                    if team == 1 {
                        Rectangle()
                            .fill(TrucoWorld.ink.opacity(0.18))
                            .frame(width: 1)
                            .padding(.vertical, 8)
                    }
                    column(team, scores: scores)
                }
            }
            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { team in
                    buttons(team, scores: scores)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            Button("Terminar partida") { endingOptions = true }
                .foregroundStyle(TrucoWorld.end)
                .frame(minHeight: 44)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .confirmationDialog("Terminar partida", isPresented: $endingOptions, titleVisibility: .visible) {
                    Button("Terminar con este resultado") { try? match.endEarly() }
                    Button("Descartar partida", role: .destructive) { confirmingDiscard = true }
                }
                .confirmationDialog("¿Descartar la partida?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                    Button("Descartar partida", role: .destructive, action: onDiscard)
                }
        }
        .foregroundStyle(TrucoWorld.ink)
        .background(TrucoWorld.background)
    }

    private func column(_ team: Int, scores: [Int]) -> some View {
        let score = scores[team]
        let isLeading = score > scores[1 - team]
        let tally = TrucoTally(score: score, variant: variant)
        let name = names.indices.contains(team) ? names[team] : ""

        return VStack(spacing: 0) {
            Text(name)
                .font(DisplayFont.bevan.scaled(24, relativeTo: .title2))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Text("\(score)")
                .font(DisplayFont.bevan.fixed(isLeading ? 72 : 52))
                .monospacedDigit()
                .foregroundStyle(isLeading ? TrucoWorld.accent : TrucoWorld.dim)
                .frame(height: 80, alignment: .bottom)
                .contentTransition(reduceMotion ? .opacity : .numericText(value: Double(score)))
                .padding(.bottom, 6)

            if variant.hasHalves {
                halfLabel("Malas")
                MatchstickBlock(points: tally.malas)
                Line()
                    .stroke(TrucoWorld.ink.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .frame(height: 2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                halfLabel("Buenas")
                MatchstickBlock(points: tally.buenas)
            } else {
                MatchstickBlock(points: tally.malas)
            }
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture { add(1, to: team, score: score) }
        .animation(animation, value: score)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(tally.spokenValue(score: score, variant: variant))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: add(1, to: team, score: score)
            case .decrement: add(-1, to: team, score: score)
            @unknown default: break
            }
        }
    }

    private func halfLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.medium))
            .tracking(1.2)
            .foregroundStyle(TrucoWorld.dim)
            .padding(.vertical, 3)
            .accessibilityHidden(true)
    }

    private func buttons(_ team: Int, scores: [Int]) -> some View {
        let score = scores[team]
        let name = names.indices.contains(team) ? names[team] : ""
        let minus = Button { add(-1, to: team, score: score) } label: {
            Image(systemName: "minus")
                .font(.title2)
                .frame(width: 58, height: 58)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(TrucoWorld.ink.opacity(0.3), lineWidth: 1.5))
        }
        .disabled(!Truco.canSubtract(from: score))
        .accessibilityLabel("Restar a \(name)")

        let plus = Button { add(1, to: team, score: score) } label: {
            Text("+1")
                .font(DisplayFont.bevan.fixed(24))
                .foregroundStyle(TrucoWorld.ground)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(TrucoWorld.ink, in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!Truco.canAdd(to: score, variant: variant))
        .accessibilityLabel("Sumar a \(name)")

        return HStack(spacing: 8) {
            if team == 0 { minus; plus } else { plus; minus }
        }
        .buttonStyle(.plain)
        .foregroundStyle(TrucoWorld.ink)
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
                Text("Truco a \(variant.target)")
                    .font(.headline)
                    .foregroundStyle(TrucoWorld.ink)
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Deshacer", action: undo)
                .disabled(!match.canUndo(Truco.self))
            if !isFinished {
                Menu {
                    Button("Detalles", systemImage: "info.circle") { showingDetails = true }
                } label: {
                    Label("Más", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Actions

    private func add(_ points: Int, to team: Int, score: Int) {
        guard !isFinished else { return }
        let allowed = points > 0 ? Truco.canAdd(to: score, variant: variant) : Truco.canSubtract(from: score)
        guard allowed else { return }
        try? match.modify(Truco.self) { $0.add(.init(team: team, points: points)) }
        pointTick += 1
    }

    private func undo() {
        guard match.canUndo(Truco.self) else { return }
        try? match.undo(Truco.self)
        undoTick += 1
    }
}

/// A horizontal line, for the dotted line between malas and buenas.
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// The Truco end (SPEC §5.4): the screen inverts, with "¡Ganaron …!", the final score,
/// "Revancha" and "Inicio". Undo stays in the navigation bar.
struct TrucoEndView: View {
    static let paper = Color(hex: 0xF3E9D8)

    var names: [String]
    var outcome: Outcome
    var onRematch: () -> Void
    var onHome: () -> Void

    private var headline: String {
        let winners = outcome.winners.compactMap { names.indices.contains($0) ? names[$0] : nil }
        guard winners.count == 1, let winner = winners.first else { return "Empate" }
        return "¡Ganaron \(winner)!"
    }

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text(headline)
                .font(DisplayFont.bevan.scaled(44, relativeTo: .largeTitle))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .accessibilityAddTraits(.isHeader)
            Text(outcome.scores.map(String.init).joined(separator: " a "))
                .font(.title3)
                .monospacedDigit()
                .accessibilityLabel(zip(names, outcome.scores).map { "\($0), \($1)" }.joined(separator: "; "))
            Spacer()
            VStack(spacing: 12) {
                Button(action: onRematch) {
                    Text("Revancha")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .foregroundStyle(TrucoWorld.ink)
                        .background(TrucoWorld.ground, in: RoundedRectangle(cornerRadius: 16))
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
        .padding(.horizontal, 24)
        .foregroundStyle(TrucoWorld.ground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Self.paper.ignoresSafeArea())
        .environment(\.colorScheme, .light)
    }
}

#Preview("In progress") {
    let container = try! Store.container(inMemory: true)
    let match = try! Match.create(Truco.self, variant: .to30, participants: Truco.initialParticipants, in: container.mainContext)
    for _ in 0..<18 { try! match.modify(Truco.self) { $0.add(.init(team: 0, points: 1)) } }
    for _ in 0..<11 { try! match.modify(Truco.self) { $0.add(.init(team: 1, points: 1)) } }
    return TrucoMatchView(match: match, onRematch: {}, onHome: {}, onDiscard: {}).modelContainer(container)
}

#Preview("To 15") {
    let container = try! Store.container(inMemory: true)
    let match = try! Match.create(Truco.self, variant: .to15, participants: Truco.initialParticipants, in: container.mainContext)
    for _ in 0..<7 { try! match.modify(Truco.self) { $0.add(.init(team: 1, points: 1)) } }
    return TrucoMatchView(match: match, onRematch: {}, onHome: {}, onDiscard: {}).modelContainer(container)
}
