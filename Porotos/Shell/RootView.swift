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

/// History (SPEC §5.5). For now, only the empty state.
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Todavía no terminaron ninguna partida", systemImage: "clock.arrow.circlepath")
                .navigationTitle("Historial")
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! Store.container(inMemory: true))
}
