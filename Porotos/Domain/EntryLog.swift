import Foundation

/// A Match's Entries, in order, plus the change history used by Undo.
///
/// Undo reverts the last change, without limit (SPEC §3.4): an added Entry is removed, and an
/// edited or removed Entry gets its previous value back. The history is stored with the Match,
/// so Undo keeps working after the app is reopened. It exists only for Undo: scores are
/// computed from `entries` (ADR 0001).
struct EntryLog<Entry: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    private(set) var entries: [Entry] = []
    private var changes: [Change] = []

    private enum Change: Codable, Equatable, Sendable {
        case added
        case edited(index: Int, previous: Entry)
        case removed(index: Int, previous: Entry)
    }

    init() {}

    var canUndo: Bool { !changes.isEmpty }

    mutating func add(_ entry: Entry) {
        entries.append(entry)
        changes.append(.added)
    }

    /// Replaces an earlier Entry (a Generala cell, a Burako Hand).
    mutating func edit(at index: Int, with newEntry: Entry) {
        precondition(entries.indices.contains(index), "No Entry at \(index)")
        let previous = entries[index]
        guard previous != newEntry else { return }
        entries[index] = newEntry
        changes.append(.edited(index: index, previous: previous))
    }

    /// Removes an earlier Entry (for example, clearing a Generala cell).
    mutating func remove(at index: Int) {
        precondition(entries.indices.contains(index), "No Entry at \(index)")
        let previous = entries.remove(at: index)
        changes.append(.removed(index: index, previous: previous))
    }

    /// Reverts the last change. Returns `false` if there was nothing to undo.
    @discardableResult
    mutating func undo() -> Bool {
        guard let last = changes.popLast() else { return false }
        switch last {
        case .added:
            entries.removeLast()
        case let .edited(index, previous):
            entries[index] = previous
        case let .removed(index, previous):
            entries.insert(previous, at: index)
        }
        return true
    }
}
