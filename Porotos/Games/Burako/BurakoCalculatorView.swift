import SwiftData
import SwiftUI

/// What the calculator is open for.
enum BurakoCalculatorMode: Identifiable, Hashable {
    /// "Anotar mano N": the next Hand, with its draft saved continuously.
    case new
    /// Correcting a Hand, from its chip.
    case edit(Int)
    /// Looking at a Hand of a Finished Match, read-only.
    case view(Int)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let index): "edit-\(index)"
        case .view(let index): "view-\(index)"
        }
    }
}

/// The Burako calculator (SPEC §4.3, §5.3): a segmented control per Participant and the
/// native controls of the Hand (steppers, number fields and switches), with the tile values as
/// a hint, the Hand's result in tiles and what the total would become.
///
/// A new Hand's draft is saved with the Match on every change, so it comes back after iOS
/// kills the app (SPEC §6.5). A correction is rejected if it would end the Match before the
/// last Hand (SPEC §6.1).
struct BurakoCalculatorView: View {
    @Bindable var match: Match
    var mode: BurakoCalculatorMode
    /// Called after a Hand is scored or corrected.
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: Burako.Draft
    @FocusState private var focused: Field?

    private enum Field {
        case melded
        case inHand
    }

    /// What the Values hint says (SPEC §4.3).
    static let tileValues = "Comodín 50 · 2 = 20 · 1 = 15 · 8 a 13 = 10 · 3 a 7 = 5"

    init(match: Match, mode: BurakoCalculatorMode, onSaved: @escaping () -> Void = {}) {
        self.match = match
        self.mode = mode
        self.onSaved = onSaved
        let count = match.participants.count
        let entries = (try? match.log(Burako.self).entries) ?? []
        switch mode {
        case .new:
            let saved = try? match.draft(Burako.Draft.self)
            if let saved, saved.hand.lines.count == count {
                _draft = State(initialValue: saved)
            } else {
                _draft = State(initialValue: Burako.Draft(hand: Burako.Hand(participantCount: count), participant: 0))
            }
        case .edit(let index), .view(let index):
            let hand = entries.indices.contains(index) ? entries[index] : Burako.Hand(participantCount: count)
            _draft = State(initialValue: Burako.Draft(hand: hand, participant: 0))
        }
    }

    // MARK: - Derived

    private var variant: Burako.Variant { (try? match.variant(Burako.self)) ?? Burako.standardVariant }
    private var entries: [Burako.Hand] { (try? match.log(Burako.self).entries) ?? [] }
    private var names: [String] { match.orderedParticipants.map(\.name) }
    private var participant: Int { min(draft.participant, max(names.count - 1, 0)) }
    private var line: Burako.Line { draft.hand.lines[participant] }
    private var isReadOnly: Bool { if case .view = mode { true } else { false } }

    /// The Hand's position, starting at 0.
    private var handIndex: Int {
        switch mode {
        case .new: entries.count
        case .edit(let index), .view(let index): index
        }
    }

    /// The totals without the Hand being entered.
    private var baseScores: [Int] {
        let others = entries.enumerated().filter { mode == .new || $0.offset != handIndex }.map(\.element)
        return names.indices.map { participant in
            others.reduce(0) { $0 + $1.result(for: participant, variant) }
        }
    }

    private var isAccepted: Bool {
        guard draft.hand.isValid else { return false }
        guard case .edit(let index) = mode else { return true }
        return Burako.canCorrect(
            handAt: index,
            to: draft.hand,
            variant: variant,
            participantCount: names.count,
            entries: entries
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !dynamicTypeSize.isAccessibilitySize { header }
                Form {
                    if dynamicTypeSize.isAccessibilitySize {
                        header.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                    }
                    canastasSection
                    tilesSection
                    switchesSection
                    resultSection
                }
                .scrollContentBackground(.hidden)
                .disabled(isReadOnly)
                .scrollDismissesKeyboard(.interactively)
            }
            .background(BurakoWorld.background)
            .navigationTitle("Mano \(handIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isReadOnly {
                        Button("Cancelar", action: cancel)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isReadOnly {
                        Button("Listo") { dismiss() }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { focused = nil }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isReadOnly {
                    confirmButton
                }
            }
            .onChange(of: draft) { _, newValue in saveDraft(newValue) }
        }
        .environment(\.colorScheme, .dark)
        .tint(BurakoWorld.action)
        .interactiveDismissDisabled(!isReadOnly)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2),
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(names.indices, id: \.self) { index in
                    let total = baseScores[index] + draft.hand.result(for: index, variant)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(draft.hand.lines[index].wentOut ? "\(names[index]) · Cerró" : names[index])
                            .font(.caption)
                            .foregroundStyle(BurakoWorld.dim)
                            .lineLimit(1)
                        TileNumber(value: total, height: 24, spoken: Burako.grouped(total))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(names[index])
                    .accessibilityValue(total < 0 ? "menos \(Burako.grouped(-total))" : Burako.grouped(total))
                }
            }

            participantPicker

            if !isAccepted, case .edit = mode {
                Text("Con este cambio alguien llegaría a la meta antes de la última mano.")
                    .font(.footnote)
                    .foregroundStyle(BurakoWorld.end)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .foregroundStyle(BurakoWorld.ink)
    }

    @ViewBuilder
    private var participantPicker: some View {
        let picker = Picker("Participante", selection: $draft.participant) {
            ForEach(names.indices, id: \.self) { index in
                Text(names[index]).tag(index)
            }
        }
        if dynamicTypeSize.isAccessibilitySize || names.count > 3 && names.contains(where: { $0.count > 12 }) {
            picker.pickerStyle(.menu)
        } else {
            picker.pickerStyle(.segmented)
        }
    }

    // MARK: - Sections

    private var canastasSection: some View {
        Section {
            counter("Canastas limpias", value: line.cleanCanastas, worth: Burako.Line.cleanCanastaValue, binding: binding(\.cleanCanastas))
            counter("Canastas sucias", value: line.dirtyCanastas, worth: Burako.Line.dirtyCanastaValue, binding: binding(\.dirtyCanastas))
        }
        .listRowBackground(BurakoWorld.surface)
    }

    /// A Stepper with its label. At accessibility sizes the control goes below the label, so
    /// the title doesn't wrap into a narrow column.
    @ViewBuilder private func counter(_ title: String, value: Int, worth: Int, binding: Binding<Int>) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                stepperLabel(title, value: value, worth: worth)
                    .accessibilityHidden(true)
                Stepper(title, value: binding, in: 0...20)
                    .labelsHidden()
            }
        } else {
            Stepper(value: binding, in: 0...20) {
                stepperLabel(title, value: value, worth: worth)
            }
        }
    }

    private func stepperLabel(_ title: String, value: Int, worth: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(BurakoWorld.action)
            }
            Text("× \(worth)")
                .font(.footnote)
                .foregroundStyle(BurakoWorld.dim)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)")
    }

    private var tilesSection: some View {
        Section {
            numberField("Fichas en mesa", field: .melded, value: binding(\.tilesMelded))
            numberField("Fichas en mano", field: .inHand, value: binding(\.tilesInHand))
        } footer: {
            Text(Self.tileValues)
                .foregroundStyle(BurakoWorld.dim)
        }
        .listRowBackground(BurakoWorld.surface)
    }

    private func numberField(_ title: String, field: Field, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: Binding(
                get: { value.wrappedValue == 0 ? "" : String(value.wrappedValue) },
                set: { text in
                    let digits = text.filter(\.isNumber).prefix(5)
                    value.wrappedValue = Int(digits) ?? 0
                }
            ), prompt: Text("0").foregroundStyle(BurakoWorld.dim))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .font(.title3.weight(.semibold))
            .monospacedDigit()
            .frame(maxWidth: 110)
            .focused($focused, equals: field)
            .accessibilityLabel(title)
        }
        .frame(minHeight: 44)
    }

    private var switchesSection: some View {
        Section {
            Toggle("Cerró", isOn: Binding(
                get: { line.wentOut },
                set: { isOn in
                    // At most one Participant goes out in a Hand (SPEC §4.3).
                    if isOn {
                        for index in draft.hand.lines.indices { draft.hand.lines[index].wentOut = false }
                    }
                    draft.hand.lines[participant].wentOut = isOn
                }
            ))
            .frame(minHeight: 44)
            Toggle("Tomó el muerto", isOn: binding(\.tookMuerto))
                .frame(minHeight: 44)
        }
        .listRowBackground(BurakoWorld.surface)
    }

    private var resultSection: some View {
        let result = draft.hand.result(for: participant, variant)
        let total = baseScores[participant] + result
        return Section {
            HStack {
                Text("Esta mano")
                Spacer()
                TileNumber(value: result, height: 30, signed: true)
            }
            .frame(minHeight: 44)
            HStack {
                Text("Total")
                Spacer()
                TileNumber(value: total, height: 30)
            }
            .frame(minHeight: 44)
        }
        .listRowBackground(BurakoWorld.surface)
    }

    private var confirmButton: some View {
        Button(action: save) {
            Text(mode == .new ? "Anotar mano \(handIndex + 1)" : "Guardar mano \(handIndex + 1)")
                .font(DisplayFont.alfaSlabOne.scaled(20, relativeTo: .title3))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(BurakoWorld.ground2)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(BurakoWorld.action, in: RoundedRectangle(cornerRadius: 16))
                .opacity(isAccepted ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isAccepted)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Actions

    private func binding<Value>(_ keyPath: WritableKeyPath<Burako.Line, Value>) -> Binding<Value> {
        Binding(
            get: { draft.hand.lines[participant][keyPath: keyPath] },
            set: { draft.hand.lines[participant][keyPath: keyPath] = $0 }
        )
    }

    /// The draft of a new Hand is saved on every change; a blank one is not kept.
    private func saveDraft(_ draft: Burako.Draft) {
        guard mode == .new else { return }
        try? match.saveDraft(draft.hand.isBlank ? nil : draft)
    }

    private func save() {
        guard isAccepted else { return }
        let hand = draft.hand
        switch mode {
        case .new:
            try? match.modify(Burako.self) { $0.add(hand) }
            try? match.saveDraft(Optional<Burako.Draft>.none)
        case .edit(let index):
            try? match.modify(Burako.self) { $0.edit(at: index, with: hand) }
        case .view:
            break
        }
        onSaved()
        dismiss()
    }

    private func cancel() {
        if mode == .new {
            try? match.saveDraft(Optional<Burako.Draft>.none)
        }
        dismiss()
    }
}
