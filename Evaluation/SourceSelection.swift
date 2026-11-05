import Foundation

/// Strict parser for the passage selector's JSON response.
public enum SourceSelection {
    private struct Payload: Decodable {
        let lines: [Int]
        private enum CodingKeys: String, CodingKey { case lines }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let keys = try decoder.container(keyedBy: AnyKey.self)
            guard keys.allKeys.count == 1, keys.allKeys.first?.stringValue == "lines" else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Expected exactly one top-level key: lines."))
            }
            lines = try container.decode([Int].self, forKey: .lines)
        }
    }
    private struct AnyKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }
    /// Returns sorted, one-based source passage numbers. Invalid or ambiguous output fails closed.
    public static func parse(response: String, passageCount: Int) -> [Int]? {
        guard passageCount >= 0, let data = response.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        let lines = payload.lines
        guard Set(lines).count == lines.count,
              lines.allSatisfy({ $0 >= 1 && $0 <= passageCount }) else { return nil }
        return lines.sorted()
    }
}


/// Conservative English meeting-note rules. nil delegates ambiguity to the model.
/// These rules select source passages; they never synthesize task wording.
public enum ActionLanguage {
    public static func decision(at index: Int, in passages: [String]) -> Bool? {
        let text = passages[index].lowercased().replacingOccurrences(of: "’", with: "'")
        func matches(_ pattern: String, _ value: String) -> Bool {
            value.range(of: pattern, options: .regularExpression) != nil
        }
        // Withdrawals apply to the immediately preceding proposal, not every
        // unrelated task in the note. Ambiguous references still need review.
        if index + 1 < passages.count {
            let next = passages[index + 1].lowercased().replacingOccurrences(of: "’", with: "'")
            if matches(#"\b(cancel(?:led)? (?:that|this)|correction|don't change|do not change)\b"#, next) { return false }
        }
        if matches(#"\b(customer (?:said|wrote)|pasted (?:document|comment)|quoted customer|one pasted comment)\b"#, text) { return false }
        if matches(#"^(?:actually,? |later we )?(?:cancel(?:led)?|do not|don't)\b|\b(no decision|not decided|no one has volunteered|undecided|leave the roadmap)\b"#, text) { return false }
        if matches(#"^(?:maybe|it might)\b|\b(?:said she|said he|said they|i|we|\w+) (?:already )?(?:sent|finished|completed)\b"#, text) { return false }
        if matches(#"\b(?:can|could) (?:speak|read|understand|code)\b"#, text) { return false }
        if matches(#"\b(?:moved to|is still failing|is (?:blue|red|green))\b"#, text) { return false }
        let verb = #"(?:send|email|book|circulate|review|check|renew|inspect|call|schedule|arrange|summarize|prepare|test|share|ask|decide|submit|grab|put|update|confirm|contact|draft|finish|deliver|investigate|fix|write|create|publish)\b"#
        if matches(#"\b(?:will|'ll|to|please|should|must|need to|can you|could you|can we|could we)\s+"# + verb, text) { return true }
        if matches(#"\bsaid (?:she|he|they|i|we) can\s+"# + verb, text) { return true }
        if matches(#"^(?:before [^,]+,\s*)?"# + verb, text) { return true }
        if matches(#"^[^:]+:\s*"# + verb, text) { return true }
        if matches(#"\bcan (?:write|speak|read|understand|code)\b"#, text) { return false }
        return nil
    }
}
