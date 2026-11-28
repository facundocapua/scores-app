import SwiftData
import SwiftUI

/// What Home opens full screen: the New Match screen of a Game, or a Match to keep playing.
enum MatchFlowStart: Identifiable {
    case newMatch(GameKind)
    case open(Match)

    var id: String {
        switch self {
        case .newMatch(let kind): "new-\(kind.rawValue)"
        case .open(let match): "match-\(match.id)"
        }
    }
}

/// The full-screen flow, from the New Match screen to the end and the Rematch (SPEC §5.2–§5.4).
/// It dispatches to each Game's screens.
struct MatchFlowView: View {
    var onClose: () -> Void
    /// Leaves the flow and deletes the Match once the flow is gone.
    var onDiscard: (Match) -> Void

    @Environment(\.modelContext) private var context
    @State private var stage: Stage

    private enum Stage {
        /// The New Match screen, with the remembered setup.
        case newMatch(GameKind)
        /// The New Match screen with a Rematch's setup, when someone is missing.
        case rematchSetup(Match)
        case playing(Match)
    }

    init(start: MatchFlowStart, onClose: @escaping () -> Void, onDiscard: @escaping (Match) -> Void) {
        self.onClose = onClose
        self.onDiscard = onDiscard
        switch start {
        case .newMatch(let kind): _stage = State(initialValue: .newMatch(kind))
        case .open(let match): _stage = State(initialValue: .playing(match))
        }
    }

    var body: some View {
        switch stage {
        case .newMatch(.truco):
            TrucoNewMatchView(
                setup: (try? RememberedSetup.last(Truco.self, in: context))
                    ?? MatchSetup(variant: Truco.standardVariant, participants: Truco.initialParticipants),
                onStart: { stage = .playing($0) },
                onCancel: onClose
            )
        case .rematchSetup(let finished) where finished.kind == .truco:
            TrucoNewMatchView(
                setup: (try? finished.rematchSetup(Truco.self))
                    ?? MatchSetup(variant: Truco.standardVariant, participants: Truco.initialParticipants),
                onStart: { stage = .playing($0) },
                onCancel: onClose
            )
        case .playing(let match) where match.kind == .truco:
            TrucoMatchView(
                match: match,
                onRematch: { rematch(match, Truco.self) },
                onHome: onClose,
                onDiscard: { onDiscard(match) }
            )
            .id(match.id)
        case .newMatch(.burako):
            BurakoNewMatchView(
                setup: (try? RememberedSetup.last(Burako.self, in: context))
                    ?? MatchSetup(variant: Burako.standardVariant, participants: Burako.initialParticipants),
                onStart: { stage = .playing($0) },
                onCancel: onClose
            )
        case .rematchSetup(let finished) where finished.kind == .burako:
            BurakoNewMatchView(
                setup: (try? finished.rematchSetup(Burako.self))
                    ?? MatchSetup(variant: Burako.standardVariant, participants: Burako.initialParticipants),
                onStart: { stage = .playing($0) },
                onCancel: onClose
            )
        case .playing(let match) where match.kind == .burako:
            BurakoMatchView(
                match: match,
                onRematch: { rematch(match, Burako.self) },
                onHome: onClose,
                onDiscard: { onDiscard(match) }
            )
            .id(match.id)
        default:
            // Generala arrives in its own slice: its card is disabled for now.
            Color.clear.onAppear(perform: onClose)
        }
    }

    private func rematch<R: GameRules>(_ match: Match, _ rules: R.Type) {
        if let next = try? match.startRematch(rules) {
            stage = .playing(next)
        } else {
            stage = .rematchSetup(match)
        }
    }
}

extension View {
    /// Keeps the screen on while `active` and the view is shown (SPEC §5.3). In the shell,
    /// the History and the end screen, normal behavior returns.
    func keepsScreenOn(_ active: Bool) -> some View {
        modifier(KeepsScreenOn(active: active))
    }
}

private struct KeepsScreenOn: ViewModifier {
    var active: Bool
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { update() }
            .onChange(of: active) { update() }
            .onChange(of: scenePhase) { update() }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func update() {
        UIApplication.shared.isIdleTimerDisabled = active && scenePhase == .active
    }
}
