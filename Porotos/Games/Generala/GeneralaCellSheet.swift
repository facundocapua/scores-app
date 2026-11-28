import SwiftData
import SwiftUI

/// A Scoresheet cell being edited: a Player and a category.
struct GeneralaCell: Identifiable, Equatable {
    var participant: Int
    var category: Generala.Category

    var id: String { "\(participant)-\(category.rawValue)" }
}

/// The native sheet of a cell (SPEC §5.3): the category's possible values, the Served one when
/// it applies, and "Tachar". A filled cell opens the same sheet to change the value, Scratch
/// it or clear it. Nothing is saved until a value is picked.
struct GeneralaCellSheet: View {
    @Bindable var match: Match
    var cell: GeneralaCell
    /// Called after a cell was changed, so the screen can give feedback.
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var variant: Generala.Variant { (try? match.variant(Generala.self)) ?? .standard }
    private var entries: [Generala.Entry] { (try? match.log(Generala.self).entries) ?? [] }
    private var existing: Generala.Entry? { Generala.entry(of: cell.participant, cell.category, in: entries) }
    private var name: String {
        let participants = match.orderedParticipants
        return participants.indices.contains(cell.participant) ? participants[cell.participant].name : ""
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Generala.options(for: cell.category, variant: variant), id: \.self) { option in
                        let mark = Generala.Mark.points(option.points)
                        row(
                            option.label(for: cell.category, variant: variant),
                            isCurrent: existing?.mark == mark && existing?.served == option.served,
                            rejected: rejection(placing: mark) != nil
                        ) {
                            place(mark, served: option.served)
                        }
                    }
                } footer: {
                    if let notice { Text(notice) }
                }

                Section {
                    row("Tachar", isCurrent: existing?.mark == .scratched, rejected: rejection(placing: .scratched) != nil) {
                        place(.scratched)
                    }
                    if existing != nil {
                        row("Borrar", isCurrent: false, rejected: rejection(placing: nil) != nil, destructive: true) {
                            place(nil)
                        }
                    }
                }
            }
            .navigationTitle("\(cell.category.title) · \(name)")
            .scrollContentBackground(.hidden)
            .background(GeneralaWorld.feltDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .tint(GeneralaWorld.brass)
        .presentationDetents([.medium, .large])
        .presentationBackground(GeneralaWorld.feltDark)
    }

    private func row(
        _ title: String,
        isCurrent: Bool,
        rejected: Bool,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(destructive ? GeneralaWorld.end : Color.primary)
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(GeneralaWorld.brass)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
        }
        .disabled(rejected)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func rejection(placing mark: Generala.Mark?) -> Generala.Rejection? {
        Generala.rejection(placing: mark, in: cell.category, of: cell.participant, entries: entries)
    }

    /// Explains why some values are disabled (the Double Generala rule).
    private var notice: String? {
        switch cell.category {
        case .doubleGenerala where rejection(placing: .points(100)) != nil:
            "Para anotar la Doble Generala hace falta la Generala con puntos. Si no, solo se puede tachar."
        case .generala where rejection(placing: .scratched) != nil:
            "La Generala no se puede tachar ni borrar mientras la Doble Generala tenga puntos. Primero tachá o borrá la Doble."
        default:
            nil
        }
    }

    private func place(_ mark: Generala.Mark?, served: Bool = false) {
        let unchanged = mark.map { existing == Generala.Entry(participant: cell.participant, category: cell.category, mark: $0, served: served) }
            ?? (existing == nil)
        if !unchanged {
            try? match.modify(Generala.self) {
                Generala.place(mark, served: served, in: cell.category, of: cell.participant, log: &$0)
            }
            onChange()
        }
        dismiss()
    }
}

