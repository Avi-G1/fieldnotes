import SwiftUI
import Foundation

private struct EvaluationFixture: Decodable {
    struct Expected: Decodable { let actions: [Action] }
    let id: String
    let notes: String
    let expected: Expected
    let why: String
}

private struct FixtureRun: Encodable {
    struct Review: Encodable { let semanticAccuracyReviewed: Bool; let reviewerNotes: String }
    let id: String
    let notes: String
    let expectedActionCount: Int
    let expectedRationale: String
    let actualActions: [Action]
    let rawResponse: String
    let metrics: String
    let quoteChecks: [String]
    let error: String?
    let review: Review
}

@main struct FieldnotesApp: App {
    init() {
        let arguments = CommandLine.arguments
        if arguments.contains("--evaluate"), let input = Self.value(after: "--evaluate", in: arguments), let output = Self.value(after: "--results", in: arguments) {
            #if os(macOS)
            Task { @MainActor in await Self.runEvaluation(input: input, output: output) }
            #else
            fputs("--evaluate is supported on macOS only.\n", stderr)
            exit(2)
            #endif
        } else if arguments.contains("--smoke") {
            Task { @MainActor in
                do {
                    let result = try await FieldnotesRuntime.shared.extract("Maya said she can send the revised onboarding flow by Thursday. I’ll ask design to review it Friday morning. We should decide whether to include the offline model download step before the next release.") { state in print(state) }
                    guard result.actions.count == 3,
                          result.actions.contains(where: { $0.task.hasPrefix("Maya said") }) else {
                        print("SMOKE FAILURE: Expected all three source actions, including Maya.")
                        #if os(macOS)
                        exit(1)
                        #else
                        return
                        #endif
                    }
                    print("SMOKE SUCCESS: \(result.metrics)")
                    for action in result.actions { print("ACTION: \(action.task) | QUOTE: \(action.quote)") }
                    // iOS apps stay alive after a smoke run. Calling exit()
                    // tears down global Metal state while the model is loaded.
                    #if os(macOS)
                    exit(0)
                    #endif
                } catch {
                    print("SMOKE FAILURE: \(error.localizedDescription)")
                    #if os(macOS)
                    exit(1)
                    #endif
                }
            }
        }
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    @MainActor private static func runEvaluation(input: String, output: String) async {
        do {
            let fixtures = try JSONDecoder().decode([EvaluationFixture].self, from: Data(contentsOf: URL(fileURLWithPath: input)))
            var runs: [FixtureRun] = []
            func savePartial() throws {
                let data = try JSONEncoder.pretty.encode(runs)
                try data.write(to: URL(fileURLWithPath: output), options: .atomic)
            }
            for fixture in fixtures {
                print("\n[\(fixture.id)] Running real local inference…")
                do {
                    let result = try await FieldnotesRuntime.shared.extract(fixture.notes) { print($0) }
                    runs.append(FixtureRun(id: fixture.id, notes: fixture.notes,
                        expectedActionCount: fixture.expected.actions.count, expectedRationale: fixture.why,
                        actualActions: result.actions, rawResponse: result.rawResponse, metrics: result.metrics,
                        quoteChecks: result.actions.map { $0.quote }, error: nil,
                        review: .init(semanticAccuracyReviewed: false, reviewerNotes: "")))
                } catch {
                    runs.append(FixtureRun(id: fixture.id, notes: fixture.notes,
                        expectedActionCount: fixture.expected.actions.count, expectedRationale: fixture.why,
                        actualActions: [], rawResponse: "", metrics: "", quoteChecks: [],
                        error: error.localizedDescription,
                        review: .init(semanticAccuracyReviewed: false, reviewerNotes: "")))
                }
                try savePartial()
            }
            print("Wrote \(runs.count) real inference runs to \(output). Semantic review is pending.")
            exit(runs.contains(where: { $0.error != nil }) ? 1 : 0)
        } catch {
            fputs("Evaluation runner failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    var body: some Scene {
        WindowGroup { NotebookView() }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; return encoder }
}
