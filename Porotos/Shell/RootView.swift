import SwiftUI

/// The shell: a tab bar with Play · History · Players (SPEC §5). UI copy is Spanish.
struct RootView: View {
    private enum Tab: Hashable {
        case play, history, players
    }

    @State private var selection = Tab.play

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Jugar", systemImage: "die.face.5") }
                .tag(Tab.play)
            HistoryView(onStartOne: { selection = .play })
                .tabItem { Label("Historial", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)
            PlayersView()
                .tabItem { Label("Jugadores", systemImage: "person.2") }
                .tag(Tab.players)
        }
        .tint(.brand)
    }
}

#Preview {
    RootView()
        .modelContainer(try! Store.container(inMemory: true))
}
