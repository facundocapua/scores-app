import SwiftData
import SwiftUI

/// The "⋯" details of a Burako Match (SPEC §5.3, §6.4): the Variant, whose options that would
/// end the Match on the spot are disabled, and the Team names of a Match in pairs. Players are
/// fixed once the Match has started.
struct BurakoDetailsSheet: View {
    @Bindable var match: Match
    @Environment(\.dismiss) private var dismiss
    @State private var teamNames: [String] = []
    @State private var otherText = ""
    @FocusState private var otherFocused: Bool

    private var variant: Burako.Variant { (try? match.variant(Burako.self)) ?? Burako.standardVariant }
    private var scores: [Int] { (try? match.outcome(Burako.self).scores) ?? [] }
    private var isPairs: Bool { match.orderedParticipants.first?.isTeam ?? false }

    private func allowsTarget(_ target: Int) -> Bool {
        target == variant.target
            || (Burako.canSetTarget(target, scores: scores)
                && match.allows(Burako.Variant(target: target, muerto: variant.muerto), Burako.self))
    }

    private func allowsMuerto(_ muerto: Burako.Muerto) -> Bool {
        muerto == variant.muerto || match.allows(Burako.Variant(target: variant.target, muerto: muerto), Burako.self)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meta") {
                    ForEach(Burako.Variant.presets, id: \.self) { preset in
                        option(String(preset), isSelected: variant.target == preset, allowed: allowsTarget(preset)) {
                            setTarget(preset)
                        }
                    }
                    HStack {
                        Text("Otra")
                            .opacity(0.9)
                        TextField("3000", text: $otherText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($otherFocused)
                            .foregroundStyle(otherIsInvalid ? Color.red : Color.primary)
                            .onChange(of: otherText) { _, text in
                                let digits = String(text.filter(\.isNumber).prefix(5))
                                if digits != text { otherText = digits }
                            }
                            .onSubmit(applyOther)
                            .accessibilityLabel("Meta")
                        if !Burako.Variant.presets.contains(variant.target) {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor).accessibilityHidden(true)
                        }
                    }
                    .frame(minHeight: 44)
                }

                Section("Muerto") {
                    ForEach(Burako.Muerto.allCases, id: \.self) { muerto in
                        option(muerto.displayName, isSelected: variant.muerto == muerto, allowed: allowsMuerto(muerto)) {
                            try? match.changeVariant(Burako.self, to: Burako.Variant(target: variant.target, muerto: muerto))
                        }
                    }
                }

                if isPairs {
                    Section("Equipos") {
                        ForEach(Array(match.orderedParticipants.enumerated()), id: \.offset) { index, team in
                            VStack(alignment: .leading, spacing: 4) {
                                TextField(
                                    Burako.defaultTeamName(at: index, players: team.orderedSeats.map(\.name)),
                                    text: binding(for: index)
                                )
                                .submitLabel(.done)
                                .onSubmit { commit(index) }
                                .frame(minHeight: 44)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        applyOther()
                        otherFocused = false
                    }
                }
            }
            .onAppear {
                teamNames = match.orderedParticipants.map(\.name)
                if !Burako.Variant.presets.contains(variant.target) { otherText = String(variant.target) }
            }
            .onDisappear {
                applyOther()
                for index in teamNames.indices { commit(index) }
            }
        }
        .environment(\.colorScheme, .dark)
        .presentationDetents([.medium, .large])
    }

    private var otherIsInvalid: Bool {
        guard let value = Int(otherText) else { return false }
        return !allowsTarget(value)
    }

    private func option(_ title: String, isSelected: Bool, allowed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(Color.primary)
                    .opacity(allowed ? 1 : 0.4)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .disabled(!allowed)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func setTarget(_ target: Int) {
        try? match.changeVariant(Burako.self, to: Burako.Variant(target: target, muerto: variant.muerto))
        otherText = ""
    }

    /// A free Target score is applied only if it wouldn't end the Match on the spot.
    private func applyOther() {
        guard let value = Int(otherText), value != variant.target, allowsTarget(value) else { return }
        setTarget(value)
        otherText = String(value)
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { teamNames.indices.contains(index) ? teamNames[index] : "" },
            set: { newValue in
                guard teamNames.indices.contains(index) else { return }
                teamNames[index] = TeamName.limited(newValue)
            }
        )
    }

    private func commit(_ index: Int) {
        guard teamNames.indices.contains(index) else { return }
        try? match.renameTeam(at: index, to: teamNames[index], Burako.self)
        teamNames[index] = match.orderedParticipants[index].name
    }
}
