import SwiftUI

/// The shell: a tab bar with Play · History · Players (SPEC §5). UI copy is Spanish.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Jugar", systemImage: "die.face.5") }
            HistoryView()
                .tabItem { Label("Historial", systemImage: "clock.arrow.circlepath") }
            PlayersView()
                .tabItem { Label("Jugadores", systemImage: "person.2") }
        }
        .tint(.brand)
    }
}

/// Home (SPEC §5.1). For now, the wordmark and the Game cards without actions: in-progress
/// Matches and the New Match screen arrive with the first Game.
struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Nueva partida") {
                    ForEach(GameKind.allCases, id: \.self) { kind in
                        Text(kind.displayName)
                            .font(.title3.weight(.semibold))
                            .padding(.vertical, 12)
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
            }
        }
    }
}

/// History (SPEC §5.5). For now, only the empty state.
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Todavía no terminaron ninguna partida", systemImage: "clock.arrow.circlepath")
                .navigationTitle("Historial")
        }
    }
}

/// Players (SPEC §5.6). For now, only the empty state.
struct PlayersView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Acá va a estar la barra", systemImage: "person.2")
                .navigationTitle("Jugadores")
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! Store.container(inMemory: true))
}
