import Foundation

/// The rules for a Player's name (SPEC §3.3): unique, compared ignoring case, accents and
/// surrounding spaces, and up to 20 characters. Pure logic, with no persistence.
enum PlayerName {
    static let maxLength = 20

    /// The name as it is saved: without surrounding spaces.
    static func cleaned(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The form used to compare names: "Ángel " and "angel" give the same key.
    static func key(_ name: String) -> String {
        cleaned(name).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_AR"))
    }

    static func isSame(_ lhs: String, _ rhs: String) -> Bool {
        key(lhs) == key(rhs)
    }

    /// Whether `query` is found inside `name`, with the same comparison. An empty query matches all.
    static func matches(_ name: String, query: String) -> Bool {
        let query = key(query)
        return query.isEmpty || key(name).contains(query)
    }

    /// Cuts what is being typed to the maximum length.
    static func limited(_ text: String) -> String {
        String(text.prefix(maxLength))
    }

    /// Checks a new name against the existing ones. Returns the cleaned name to save.
    static func validate(_ name: String, existing: [String]) -> Result<String, PlayerNameError> {
        let cleaned = cleaned(name)
        if cleaned.isEmpty { return .failure(.empty) }
        if cleaned.count > maxLength { return .failure(.tooLong) }
        if let taken = existing.first(where: { isSame($0, cleaned) }) { return .failure(.taken(taken)) }
        return .success(cleaned)
    }
}

enum PlayerNameError: Error, Equatable {
    case empty
    case tooLong
    /// Another Player already has this name (the existing name is included).
    case taken(String)
}
