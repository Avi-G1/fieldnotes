import Foundation

/// The output contract requested from the model. Optional fields should be JSON null when
/// the notes do not state them.
public struct FieldnotesExtraction: Decodable {
    public struct Action: Decodable {
        public let task: String
        public let owner: String?
        public let deadline: String?
        public let quote: String
    }

    public let summary: String?
    public let actions: [Action]
}

public struct GroundedEvaluationReport {
    public enum Status: String { case valid, invalidJSON, invalidEvidence }
    public let status: Status
    public let actionCount: Int
    public let validatedActionCount: Int
    public let issues: [String]

    public var allActionsPassTextChecks: Bool { actionCount == validatedActionCount }
}

/// Checks structure and whether every action's evidence quote occurs verbatim in its source.
/// This deliberately cannot prove that task/owner/deadline claims are semantically entailed.
public enum GroundedEvaluation {
    public static func evaluate(source: String, responseJSON: String) -> GroundedEvaluationReport {
        guard let data = responseJSON.data(using: .utf8),
              let result = try? JSONDecoder().decode(FieldnotesExtraction.self, from: data) else {
            return GroundedEvaluationReport(status: .invalidJSON, actionCount: 0,
                                            validatedActionCount: 0,
                                            issues: ["Output does not match the required JSON schema."])
        }

        var issues: [String] = []
        var grounded = 0
        for (index, action) in result.actions.enumerated() {
            let task = action.task.trimmingCharacters(in: .whitespacesAndNewlines)
            let quote = action.quote
            if task.isEmpty { issues.append("Action \(index + 1): task is empty.") }
            func appears(_ value: String, in text: String) -> Bool {
                !value.isEmpty && text.range(of: value, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
            if quote.isEmpty || !source.contains(quote) {
                issues.append("Action \(index + 1): evidence quote is not an exact substring of the notes.")
            }
            if !appears(task, in: quote) { issues.append("Action \(index + 1): task wording is absent from its quote.") }
            if let owner = action.owner, !appears(owner.trimmingCharacters(in: .whitespacesAndNewlines), in: quote) {
                issues.append("Action \(index + 1): owner is absent from its quote.")
            }
            if let deadline = action.deadline, !appears(deadline.trimmingCharacters(in: .whitespacesAndNewlines), in: quote) {
                issues.append("Action \(index + 1): deadline is absent from its quote.")
            }
            if quote.isEmpty || !source.contains(quote) || !appears(task, in: quote) ||
                (action.owner.map { !appears($0.trimmingCharacters(in: .whitespacesAndNewlines), in: quote) } ?? false) ||
                (action.deadline.map { !appears($0.trimmingCharacters(in: .whitespacesAndNewlines), in: quote) } ?? false) {
                continue
            }
            grounded += 1
        }
        let status: GroundedEvaluationReport.Status = issues.isEmpty ? .valid : .invalidEvidence
        return GroundedEvaluationReport(status: status, actionCount: result.actions.count,
                                        validatedActionCount: grounded, issues: issues)
    }
}
