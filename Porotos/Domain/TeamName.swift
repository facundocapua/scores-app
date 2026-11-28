import Foundation

/// The rules for a Team's name (SPEC §3.3): up to 30 characters and never empty. If it is
/// cleared, it goes back to the default name. The two Teams of a Match can share a name.
enum TeamName {
    static let maxLength = 30

    /// Cuts what is being typed to the maximum length.
    static func limited(_ text: String) -> String {
        String(text.prefix(maxLength))
    }

    /// The name to save: trimmed, or the default one if nothing is left.
    static func resolved(_ text: String, default defaultName: String) -> String {
        let cleaned = limited(text).trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? defaultName : cleaned
    }
}
