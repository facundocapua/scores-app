import SwiftUI

/// El shell: tab bar Jugar · Historial · Jugadores (SPEC §5).
struct RaizView: View {
    var body: some View {
        TabView {
            InicioView()
                .tabItem { Label("Jugar", systemImage: "die.face.5") }
            HistorialView()
                .tabItem { Label("Historial", systemImage: "clock.arrow.circlepath") }
            JugadoresView()
                .tabItem { Label("Jugadores", systemImage: "person.2") }
        }
        .tint(.porotoColorado)
    }
}

/// Inicio (SPEC §5.1). Por ahora, el wordmark y las tarjetas de Juego sin acción: las
/// Partidas En curso y Crear Partida llegan con el primer Juego.
struct InicioView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Nueva partida") {
                    ForEach(TipoDeJuego.allCases, id: \.self) { tipo in
                        Text(tipo.nombre)
                            .font(.title3.weight(.semibold))
                            .padding(.vertical, 12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Porotos")
                        .font(FuenteDeDisplay.shrikhand.escalable(28, relativoA: .title))
                        .foregroundStyle(Color.porotoColorado)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
    }
}

/// Historial (SPEC §5.5). Por ahora, solo el estado vacío.
struct HistorialView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Todavía no terminaron ninguna partida",
                systemImage: "clock.arrow.circlepath"
            )
            .navigationTitle("Historial")
        }
    }
}

/// Jugadores (SPEC §5.6). Por ahora, solo el estado vacío.
struct JugadoresView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Acá va a estar la barra", systemImage: "person.2")
                .navigationTitle("Jugadores")
        }
    }
}

#Preview {
    RaizView()
        .modelContainer(try! Almacen.contenedor(enMemoria: true))
}
