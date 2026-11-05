import Foundation

@main
enum GroundedEvaluationTests {
    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fputs("FAIL: \(message)\n", stderr); exit(1) }
    }

    static func main() {
        let source = "Maya: send the revised deck by Friday. Maybe explore a podcast later. The launch moved to June 12."
        let good = #"{"summary":"The launch moved to June 12.","actions":[{"task":"send the revised deck","owner":"Maya","deadline":"Friday","quote":"Maya: send the revised deck by Friday."}]}"#
        let valid = GroundedEvaluation.evaluate(source: source, responseJSON: good)
        check(valid.status == .valid && valid.validatedActionCount == 1, "explicit action and text checks")

        let absentOwner = #"{"actions":[{"task":"Review launch plan","owner":null,"deadline":null,"quote":"The launch moved to June 12."}]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: absentOwner).status == .invalidEvidence, "unsupported task text rejected")

        let fabricatedQuote = #"{"actions":[{"task":"Book a venue","owner":null,"deadline":null,"quote":"Book a venue tomorrow."}]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: fabricatedQuote).status == .invalidEvidence, "fabricated claim evidence rejected")

        let malformed = GroundedEvaluation.evaluate(source: source, responseJSON: "not json")
        check(malformed.status == .invalidJSON, "malformed JSON rejected")

        let noActions = #"{"summary":"Maybe explore a podcast later.","actions":[]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: noActions).status == .valid, "empty action set accepted")

        let unrelated = #"{"actions":[{"task":"Follow up","owner":null,"deadline":null,"quote":"Maya: send the revised deck by Friday."}]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: unrelated).status == .invalidEvidence, "unrelated task text rejected")

        let emptyTask = #"{"actions":[{"task":"  ","owner":null,"deadline":null,"quote":"Maya: send the revised deck by Friday."}]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: emptyTask).status == .invalidEvidence, "empty task rejected")

        let nearMatch = #"{"actions":[{"task":"send the revised deck","owner":"Maya","deadline":"Friday","quote":"Maya send the revised deck by Friday."}]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: nearMatch).validatedActionCount == 0, "near-match quote rejected")

        let inventedDeadline = #"{"actions":[{"task":"send the revised deck","owner":"Maya","deadline":"tomorrow","quote":"Maya: send the revised deck by Friday."}]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: inventedDeadline).status == .invalidEvidence, "deadline absent from quote rejected")
        let inventedOwner = #"{"actions":[{"task":"send the revised deck","owner":"Nina","deadline":"Friday","quote":"Maya: send the revised deck by Friday."}]}"#
        check(GroundedEvaluation.evaluate(source: source, responseJSON: inventedOwner).status == .invalidEvidence, "owner absent from quote rejected")

        print("GroundedEvaluation checks passed (10 structural/text checks; semantic entailment is not proven).")
    }
}
