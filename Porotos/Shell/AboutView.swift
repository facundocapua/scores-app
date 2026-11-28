import SwiftUI

/// "Acerca de Porotos" (SPEC §5.1): privacy policy, support, contact and version. No preferences.
struct AboutView: View {
    var info: AppInfo = .current
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 6) {
                        Text("Porotos")
                            .font(DisplayFont.shrikhand.scaled(44, relativeTo: .largeTitle))
                            .foregroundStyle(Color.brand)
                            .accessibilityAddTraits(.isHeader)
                        Text("Anotador de juegos de mesa")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section {
                    if let url = info.privacyURL {
                        Link(destination: url) { Label("Política de privacidad", systemImage: "hand.raised") }
                    }
                    if let url = info.supportURL {
                        Link(destination: url) { Label("Soporte", systemImage: "questionmark.circle") }
                    }
                    if let url = info.mailtoURL {
                        Link(destination: url) {
                            LabeledContent("Contacto", value: info.supportEmail)
                        }
                    }
                } footer: {
                    Text("Porotos no recopila ningún dato: todo queda en tu teléfono.")
                }

                Section {
                    LabeledContent("Versión", value: info.versionText)
                }
            }
            .navigationTitle("Acerca de")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
        .tint(.brand)
    }
}

#Preview {
    AboutView()
}
