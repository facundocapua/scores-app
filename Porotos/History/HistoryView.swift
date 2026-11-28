import SwiftData
import SwiftUI

/// History (SPEC §5.5): the Finished Matches grouped by month, newest first, with a Game
/// filter, swipe to delete (with confirmation, no trash) and a read-only detail.
struct HistoryView: View {
    /// "Empezar una": goes to the Play tab.
    var onStartOne: () -> Void

    @Query(filter: #Predicate<Match> { $0.statusRaw == "finished" })
    private var finished: [Match]
    @State private var filter = HistoryFilter.all
    @State private var path: [UUID] = []
    @State private var flow: MatchFlowStart?
    @State private var pendingDelete: Match?

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Historial")
                .toolbar {
                    if !finished.isEmpty {
                        ToolbarItem(placement: .topBarTrailing) { filterMenu }
                    }
                }
                .navigationDestination(for: UUID.self) { id in
                    if let match = finished.first(where: { $0.id == id }), let entry = HistoryEntry(match) {
                        MatchDetailView(
                            entry: entry,
                            match: match,
                            onPlayAgain: { flow = match.playAgain() },
                            onDelete: {
                                path.removeAll()
                                try? match.delete()
                            }
                        )
                    }
                }
        }
        .matchFlowCover($flow)
    }

    @ViewBuilder private var content: some View {
        let months = History.months(finished, filter: filter)
        if finished.isEmpty {
            ContentUnavailableView {
                Label("Todavía no terminaron ninguna partida", systemImage: "clock.arrow.circlepath")
            } actions: {
                Button("Empezar una", action: onStartOne)
                    .buttonStyle(.borderedProminent)
            }
        } else if months.isEmpty {
            ContentUnavailableView(
                "No hay partidas de \(filterName)",
                systemImage: "clock.arrow.circlepath"
            )
        } else {
            List {
                ForEach(months) { month in
                    Section(History.monthTitle(month.start)) {
                        ForEach(month.matches) { match in
                            if let entry = HistoryEntry(match) {
                                NavigationLink(value: match.id) { HistoryRow(entry: entry) }
                                    .swipeActions {
                                        Button("Eliminar partida", systemImage: "trash", role: .destructive) {
                                            pendingDelete = match
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .confirmationDialog(
                "¿Eliminar la partida?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { match in
                Button("Eliminar partida", role: .destructive) { try? match.delete() }
            }
        }
    }

    private var filterName: String {
        if case .game(let kind) = filter { return kind.displayName }
        return ""
    }

    private var filterMenu: some View {
        Menu {
            Picker("Juego", selection: $filter) {
                Text("Todos").tag(HistoryFilter.all)
                ForEach(GameKind.allCases, id: \.self) { kind in
                    Text(kind.displayName).tag(HistoryFilter.game(kind))
                }
            }
        } label: {
            Label(
                "Filtrar por juego",
                systemImage: filter == .all
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }
}

/// A Finished Match in the list: the Game, the date, the Participants with the Winners
/// highlighted and the "Empate" and "Terminada antes" labels.
struct HistoryRow: View {
    var entry: HistoryEntry

    private var summary: Text {
        entry.participants.enumerated().reduce(Text("")) { text, item in
            let (offset, participant) = item
            let part = Text("\(participant.name) \(participant.score)")
            let styled = participant.isWinner
                ? part.bold().foregroundStyle(Color.primary)
                : part.foregroundStyle(Color.secondary)
            return offset == 0 ? styled : text + Text("  ·  ").foregroundStyle(Color.secondary) + styled
        }
    }

    private var spoken: String {
        var parts = [entry.kind.displayName, History.fullDate(entry.finishedAt)]
        for participant in entry.participants {
            parts.append("\(participant.name), \(participant.score)" + (participant.isWinner ? ", ganó" : ""))
        }
        if entry.isTie { parts.append("Empate") }
        if entry.endedEarly { parts.append("Terminada antes") }
        return parts.joined(separator: ". ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.kind.displayName)
                Spacer()
                Text(History.shortDate(entry.finishedAt))
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            summary
                .font(.headline)
            if entry.isTie || entry.endedEarly {
                HStack(spacing: 6) {
                    if entry.isTie { HistoryLabel(text: "Empate") }
                    if entry.endedEarly { HistoryLabel(text: "Terminada antes") }
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

struct HistoryLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
    }
}
