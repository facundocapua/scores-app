import SwiftData
import SwiftUI

/// Home, the Jugar tab (SPEC §5.1): the Matches In progress (the last one scored first, up to
/// 3 plus "Ver todas") and the Game cards below.
struct HomeView: View {
    static let visibleMatches = 3

    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<Match> { $0.statusRaw == "inProgress" },
        sort: \Match.lastEntryAt,
        order: .reverse
    )
    private var inProgress: [Match]
    @State private var flow: MatchFlowStart?
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                if !inProgress.isEmpty {
                    Section {
                        InProgressRows(matches: Array(inProgress.prefix(Self.visibleMatches))) { flow = .open($0) }
                        if inProgress.count > Self.visibleMatches {
                            NavigationLink("Ver todas") {
                                InProgressList { flow = .open($0) }
                            }
                        }
                    }
                }

                Section("Nueva partida") {
                    ForEach(GameKind.allCases, id: \.self) { kind in
                        GameCard(kind: kind) { flow = .newMatch(kind) }
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Porotos")
                        .font(DisplayFont.shrikhand.scaled(28, relativeTo: .title))
                        .foregroundStyle(Color.brand)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Acerca de Porotos", systemImage: "info.circle") { showingAbout = true }
                        .labelStyle(.iconOnly)
                }
            }
        }
        .sheet(isPresented: $showingAbout) { AboutView() }
        .matchFlowCover($flow)
    }
}

/// The rows of the Matches In progress, with swipe to delete and confirmation (the same as
/// Discard, SPEC §6.3).
struct InProgressRows: View {
    var matches: [Match]
    var onOpen: (Match) -> Void
    @State private var discarding: Match?

    var body: some View {
        ForEach(matches) { match in
            InProgressRow(match: match) { onOpen(match) }
                .swipeActions {
                    Button("Descartar partida", systemImage: "trash", role: .destructive) { discarding = match }
                }
        }
        .confirmationDialog(
            "¿Descartar la partida?",
            isPresented: Binding(get: { discarding != nil }, set: { if !$0 { discarding = nil } }),
            titleVisibility: .visible,
            presenting: discarding
        ) { match in
            Button("Descartar partida", role: .destructive) { try? match.delete() }
        }
    }
}

/// "Ver todas": every Match In progress.
struct InProgressList: View {
    var onOpen: (Match) -> Void
    @Query(
        filter: #Predicate<Match> { $0.statusRaw == "inProgress" },
        sort: \Match.lastEntryAt,
        order: .reverse
    )
    private var inProgress: [Match]

    var body: some View {
        List {
            InProgressRows(matches: inProgress, onOpen: onOpen)
        }
        .navigationTitle("Partidas en curso")
    }
}

/// A Match In progress: Game, Participants, score and "Seguir".
struct InProgressRow: View {
    var match: Match
    var onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var summary: String {
        let names = match.orderedParticipants.map(\.name)
        guard let rules = GameCatalog.rules(for: match.kind),
              let outcome = try? match.outcome(using: rules)
        else { return names.joined(separator: " · ") }
        return zip(names, outcome.scores).map { "\($0) \($1)" }.joined(separator: " · ")
    }

    var body: some View {
        // At accessibility sizes the button goes below the text, so neither is squeezed.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(match.kind.displayName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(summary)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onContinue) {
                Text("Seguir")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.onBrand)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, minHeight: 44)
                    .background(Color.brandFill, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onContinue)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Seguir", onContinue)
    }
}

/// A Game card that previews its world (`DESIGN.md`, Shell). The Games still to be built are
/// shown disabled.
struct GameCard: View {
    var kind: GameKind
    var action: () -> Void

    private var isAvailable: Bool { GameCatalog.rules(for: kind) != nil }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                background
                art
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(14)
                VStack(alignment: .leading, spacing: 6) {
                    Text(kind.displayName)
                        .font(titleFont)
                        .foregroundStyle(titleColor)
                    Text(tagline)
                        .font(.footnote)
                        // On the lightest felt, 85% ink falls to 4.3:1, so Generala keeps full ink.
                        .opacity(kind == .generala ? 1 : 0.85)
                }
                .foregroundStyle(ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .frame(minHeight: 132)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.5)
    }

    private var tagline: String {
        switch kind {
        case .truco: "A 15 o a 30, con fósforos"
        case .generala: "De 2 a 6 jugadores, con planilla"
        case .burako: "En parejas o de a uno"
        }
    }

    private var titleFont: Font {
        switch kind {
        case .truco: DisplayFont.bevan.scaled(30, relativeTo: .title)
        case .generala: DisplayFont.abrilFatface.scaled(30, relativeTo: .title)
        case .burako: DisplayFont.alfaSlabOne.scaled(30, relativeTo: .title)
        }
    }

    private var titleColor: Color {
        kind == .generala ? GeneralaWorld.brass : ink
    }

    private var ink: Color {
        switch kind {
        case .truco: TrucoWorld.ink
        case .generala: GeneralaWorld.ink
        case .burako: BurakoWorld.ink
        }
    }

    @ViewBuilder private var background: some View {
        switch kind {
        case .truco: TrucoWorld.ground
        case .generala:
            RadialGradient(colors: [GeneralaWorld.feltLight, GeneralaWorld.feltDark], center: UnitPoint(x: 0.3, y: 0.2), startRadius: 0, endRadius: 400)
        case .burako: BurakoWorld.ground
        }
    }

    @ViewBuilder private var art: some View {
        if kind == .truco {
            MatchstickGroup(count: 5)
                .frame(height: 70)
        }
    }
}

#Preview {
    let container = try! Store.container(inMemory: true)
    let match = try! Match.create(Truco.self, variant: .to30, participants: Truco.initialParticipants, in: container.mainContext)
    try! match.modify(Truco.self) { $0.add(.init(team: 0, points: 1)) }
    return HomeView().modelContainer(container)
}
