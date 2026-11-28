import SwiftUI

extension View {
    /// Presents the full-screen Match flow for `flow`, from Home and from History. A Match
    /// discarded inside the flow is deleted once the flow is gone.
    func matchFlowCover(_ flow: Binding<MatchFlowStart?>) -> some View {
        modifier(MatchFlowCover(flow: flow))
    }
}

private struct MatchFlowCover: ViewModifier {
    @Binding var flow: MatchFlowStart?
    @State private var pendingDiscard: Match?

    func body(content: Content) -> some View {
        content.fullScreenCover(item: $flow, onDismiss: deletePendingDiscard) { start in
            MatchFlowView(
                start: start,
                onClose: { flow = nil },
                onDiscard: { match in
                    pendingDiscard = match
                    flow = nil
                }
            )
        }
    }

    private func deletePendingDiscard() {
        guard let match = pendingDiscard else { return }
        pendingDiscard = nil
        try? match.delete()
    }
}
