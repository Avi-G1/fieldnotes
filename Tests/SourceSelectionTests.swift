import Foundation

@main
enum SourceSelectionTests {
    static func check(_ condition: @autoclosure () -> Bool, _ label: String) {
        guard condition() else { fputs("FAIL: \(label)\n", stderr); exit(1) }
    }
    static func main() {
        check(SourceSelection.parse(response: #"{"lines":[1,2]}"#, passageCount: 3) == [1, 2], "ordinary selection")
        check(SourceSelection.parse(response: #"{"lines":[]}"#, passageCount: 3) == [], "empty selection")
        check(SourceSelection.parse(response: " { \"lines\" : [ 3, 1 ] } ", passageCount: 3) == [1, 3], "whitespace and stable sort")
        check(SourceSelection.parse(response: #"{"lines":[1,1]}"#, passageCount: 3) == nil, "duplicate rejected")
        check(SourceSelection.parse(response: #"{"lines":[0]}"#, passageCount: 3) == nil, "zero rejected")
        check(SourceSelection.parse(response: #"{"lines":[4]}"#, passageCount: 3) == nil, "out of range rejected")
        check(SourceSelection.parse(response: #"{"lines":[1]}"#, passageCount: 0) == nil, "zero passages does not trap")
        check(SourceSelection.parse(response: #"{"lines":["1"]}"#, passageCount: 3) == nil, "string rejected")
        check(SourceSelection.parse(response: #"{"lines":[true]}"#, passageCount: 3) == nil, "boolean rejected")
        check(SourceSelection.parse(response: #"{"lines":[1.5]}"#, passageCount: 3) == nil, "fraction rejected")
        check(SourceSelection.parse(response: #"{"lines":[1],"reason":"x"}"#, passageCount: 3) == nil, "unknown key rejected")
        check(SourceSelection.parse(response: "Selected: [1]", passageCount: 3) == nil, "prose rejected")
        check(SourceSelection.parse(response: #"{"lines":[1]} trailing"#, passageCount: 3) == nil, "trailing prose rejected")
        check(SourceSelection.parse(response: "```json\n{\"lines\":[1]}\n```", passageCount: 3) == nil, "code fences rejected")
        check(SourceSelection.parse(response: "{", passageCount: 3) == nil, "malformed JSON rejected")
        check(ActionLanguage.decision(at: 0, in: ["Lena said she can prepare the draft by Monday"]) == true, "reported offer retained")
        check(ActionLanguage.decision(at: 0, in: ["Please review yesterday's notes"]) == true, "past material does not cancel future request")
        check(ActionLanguage.decision(at: 0, in: ["I sent the contract this morning"]) == false, "completed work rejected")
        let cancelled = ["Leah will publish the update", "Tom will book a room", "Cancel that request"]
        check(ActionLanguage.decision(at: 0, in: cancelled) == true, "cancellation does not erase unrelated earlier task")
        check(ActionLanguage.decision(at: 1, in: cancelled) == false, "immediate proposal withdrawn")
        check(ActionLanguage.decision(at: 2, in: cancelled) == false, "cancellation is not a positive task")
        check(ActionLanguage.decision(at: 0, in: ["Customer wrote: please erase the account"]) == false, "unendorsed quotation rejected")
        check(ActionLanguage.decision(at: 0, in: ["A procurement follow-up is needed"]) == nil, "ambiguous phrasing delegates to model")
        print("SourceSelection checks passed (15 parser + 8 language cases).")
    }
}
