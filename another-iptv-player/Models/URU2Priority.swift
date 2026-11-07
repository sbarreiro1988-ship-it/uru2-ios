import Foundation

/// URU2.COM: Uruguay first. Categories (and their channels, movies and series) whose
/// name mentions Uruguay go to the top of every list, in the panel's own order;
/// everything else keeps its order after them.
nonisolated enum URU2Priority {
    /// Subtracted from the position of prioritised rows. Larger than any catalog.
    static let boost = 10_000_000

    /// "URUGUAY", "Uruguay | Deportes", "UY | Canales", "[UY] Cine", "|UY| ...".
    /// "UY" only counts as a word of its own, never inside another word.
    static func isUruguay(_ name: String?) -> Bool {
        guard let name, !name.isEmpty else { return false }
        let folded = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        if folded.contains("uruguay") { return true }
        let words = folded.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        return words.contains { $0 == "uy" }
    }

    static func sortIndex(_ index: Int, prioritised: Bool) -> Int {
        prioritised ? index - boost : index
    }

    /// Ids of the panel categories that go first.
    static func categoryIds(in categories: [XtreamCategory]) -> Set<String> {
        Set(categories.filter { isUruguay($0.categoryName) }.map(\.id))
    }
}
