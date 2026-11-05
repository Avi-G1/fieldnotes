import SwiftUI
#if os(macOS)
import AppKit
#endif

struct Action: Identifiable, Codable {
    let id: UUID
    let task: String
    let owner: String?
    let deadline: String?
    let quote: String

    init(id: UUID = UUID(), task: String, owner: String?, deadline: String?, quote: String) {
        self.id = id
        self.task = task
        self.owner = owner
        self.deadline = deadline
        self.quote = quote
    }

    enum CodingKeys: String, CodingKey { case task, owner, deadline, quote }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        task = try container.decode(String.self, forKey: .task)
        owner = try container.decodeIfPresent(String.self, forKey: .owner)
        deadline = try container.decodeIfPresent(String.self, forKey: .deadline)
        quote = try container.decode(String.self, forKey: .quote)
    }
}

@MainActor @Observable final class NotebookModel {
    var note = "Maya said she can send the revised onboarding flow by Thursday. I’ll ask design to review it Friday morning. We should decide whether to include the offline model download step before the next release."
    var actions: [Action] = []
    var phase = "Ready"
    var error: String?
    var busy = false
    var metrics: String?
    var rawResponse: String?
    var hasRun = false
    var sourceCount: Int { note.count }

    func invalidateResults() {
        guard !busy else { return }
        actions = []
        metrics = nil
        rawResponse = nil
        error = nil
        hasRun = false
        phase = "Ready"
    }

    func extract() async {
        guard !busy, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, note.count <= 4000 else { return }
        let sourceSnapshot = note
        busy = true
        error = nil
        actions = []
        metrics = nil
        rawResponse = nil
        phase = "Preparing model…"
        defer { busy = false }

        do {
            let result = try await FieldnotesRuntime.shared.extract(sourceSnapshot) { [weak self] state in
                self?.phase = state
            }
            actions = result.actions
            metrics = result.metrics
            rawResponse = result.rawResponse
            phase = "Generated locally"
            hasRun = true
        } catch {
            self.error = error.localizedDescription
            phase = "Could not run locally"
            hasRun = true
        }
    }
}

struct NotebookView: View {
    @State private var model = NotebookModel()
    @State private var kept: Set<UUID> = []
    @State private var showingDetails = false
    @State private var activeSource: UUID?
    @State private var revising = false
    @State private var sourceReveal = 0
    private var reviewing: Bool { !model.actions.isEmpty && !revising }
    private var sourceAction: Action? { model.actions.first { $0.id == activeSource } }
    @State private var sourceExpanded = false

    private var highlightedNote: AttributedString {
        var text = AttributedString(model.note)
        guard let quote = sourceAction?.quote, !quote.isEmpty else { return text }
        var search = model.note.startIndex..<model.note.endIndex
        while let match = model.note.range(of: quote, range: search) {
            if let start = AttributedString.Index(match.lowerBound, within: text),
               let end = AttributedString.Index(match.upperBound, within: text) {
                text[start..<end].backgroundColor = Color(red: 0.90, green: 0.78, blue: 0.51)
                text[start..<end].foregroundColor = Color(red: 0.10, green: 0.10, blue: 0.12)
            }
            search = match.upperBound..<model.note.endIndex
        }
        return text
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var editing: Bool
    @Environment(\.colorScheme) private var colorScheme
    private let accent = Color(red: 0.25, green: 0.39, blue: 0.82)
    private var ink: Color { colorScheme == .dark ? Color(red: 0.97, green: 0.96, blue: 0.93) : Color(red: 0.08, green: 0.09, blue: 0.11) }
    private var mutedInk: Color { colorScheme == .dark ? Color(red: 0.83, green: 0.82, blue: 0.79) : Color(red: 0.32, green: 0.35, blue: 0.40) }
    private var linkInk: Color { colorScheme == .dark ? Color(red: 0.65, green: 0.77, blue: 0.95) : Color(red: 0.17, green: 0.34, blue: 0.78) }

    private var canvas: Color { colorScheme == .dark ? Color(red: 0.105, green: 0.102, blue: 0.098) : Color(red: 0.95, green: 0.94, blue: 0.91) }
    private var chrome: Color { colorScheme == .dark ? Color(red: 0.135, green: 0.13, blue: 0.12) : .white }


    private var canRun: Bool {
        !model.busy && !model.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && model.sourceCount <= 4000
    }
    private var shareText: String {
        model.actions.filter { kept.contains($0.id) }.map { "• \($0.task)" }.joined(separator: "\n")
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 760
            VStack(spacing: 0) {
                toolbar(compact: compact)
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        if compact {
                            VStack(alignment: .leading, spacing: 24) {
                                editor(compact: true).id("source-note")
                                review(compact: true)
                            }.padding(20)
                        } else {
                            HStack(alignment: .top, spacing: 40) {
                                VStack(alignment: .leading, spacing: 18) {
                                    editor(compact: false).id("source-note")
                                    actionBar(compact: false)
                                }.frame(width: min(320, geometry.size.width * 0.34))
                                review(compact: false).frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                            .padding(32)
                            .frame(maxWidth: 1040)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: sourceReveal) { _, _ in
                        if compact && activeSource != nil {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                                proxy.scrollTo("source-note", anchor: .top)
                            }
                        }
                    }
                }
                if compact {
                    Divider()
                    actionBar(compact: true)
                }
            }
            .background(canvas)
            .foregroundStyle(ink)
            .tint(linkInk)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.hasRun)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: kept)
            .onChange(of: model.note) { _, _ in
                model.invalidateResults()
                kept.removeAll()
                activeSource = nil
            }
            .onChange(of: model.busy) { _, busy in
                if busy { kept.removeAll(); activeSource = nil; revising = false }
            }
            .sheet(isPresented: $showingDetails) { details }
        }
        #if os(macOS)
        .frame(minWidth: 360, idealWidth: 1040, minHeight: 620, idealHeight: 760)
        #endif
    }

    private func toolbar(compact: Bool) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .foregroundStyle(colorScheme == .dark ? Color(red: 0.90, green: 0.78, blue: 0.51) : Color(red: 0.48, green: 0.35, blue: 0.14))
                    .font(.system(size: 19, weight: .medium))
                    .accessibilityHidden(true)
                Text("Fieldnotes").font(.subheadline.weight(.semibold))
                if !compact {
                    Text("/").foregroundStyle(mutedInk)
                    Text("Meeting notes").font(.subheadline).foregroundStyle(mutedInk)
                }
            }
            Spacer()
            Button { showingDetails = true } label: {
                Image(systemName: "info.circle").font(.system(size: 18))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(mutedInk)
            .accessibilityLabel("About local processing")
        }
        .padding(.leading, 24).padding(.trailing, 12).padding(.vertical, 2)
        .background(chrome)
    }

    private func editor(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Meeting notes").font(.system(compact ? .title : .title2, design: .default, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !model.actions.isEmpty {
                    Button(revising ? "Review note" : "Edit note") {
                        revising.toggle()
                        editing = revising
                        activeSource = nil
                    }
                    .font(.subheadline.weight(.medium)).buttonStyle(.plain)
                    .foregroundStyle(linkInk).frame(minHeight: 44)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                if reviewing {
                    HStack {
                        Text("SOURCE NOTE").font(.caption2.weight(.semibold)).tracking(1.2).foregroundStyle(mutedInk)
                        Spacer()
                        if compact {
                        Button(sourceExpanded ? "Show less" : "Show full note") { sourceExpanded.toggle() }
                            .font(.caption.weight(.medium)).buttonStyle(.plain).foregroundStyle(linkInk)
                            .frame(minHeight: 44)
                        }
                    }
                    Text(highlightedNote)
                        .font(.subheadline).lineSpacing(4)
                        .lineLimit(compact && !sourceExpanded ? 3 : nil)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Source note. " + model.note)
                    if let action = sourceAction,
                       let number = model.actions.firstIndex(where: { $0.id == action.id }) {
                        Text("Source for action \(number + 1)")
                            .font(.caption.weight(.medium)).foregroundStyle(linkInk)
                    }
                } else {
                ZStack(alignment: .topLeading) {
                    if model.note.isEmpty {
                        Text("Paste or type your notes here…")
                            .foregroundStyle(mutedInk).padding(.top, 8).padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $model.note)
                        .scrollIndicators(.hidden)
                        #if os(macOS)
                        .background(EditorScrollerHider())
                        #endif
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(ink)
                        .focused($editing)
                        .disabled(model.busy)
                        .accessibilityLabel("Meeting notes")
                        .accessibilityHint("Type or paste notes to find actions")
                }
                .font(.body).lineSpacing(7)
                .frame(height: compact ? 160 : 180)
                }
                if !reviewing {
                Divider()
                HStack {
                    Text("\(model.sourceCount.formatted()) / 4,000")
                        .monospacedDigit()
                        .foregroundStyle(model.sourceCount > 4000 ? Color.red : mutedInk)
                    Spacer()
                    Label("On-device", systemImage: "lock").foregroundStyle(mutedInk)
                }
                .font(.caption)
                if model.sourceCount > 4000 {
                    Text("Shorten your note").font(.caption).foregroundStyle(.red)
                }
                }
            }
            .padding(compact ? 14 : 18)
            .background(colorScheme == .dark ? Color(red: 0.18, green: 0.175, blue: 0.165) : Color.white,
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(reviewing ? Color.clear : editing ? linkInk : (colorScheme == .dark
                        ? Color(red: 0.38, green: 0.40, blue: 0.44)
                        : Color(red: 0.58, green: 0.61, blue: 0.66)), lineWidth: editing ? 2 : 1)
                    .allowsHitTesting(false)
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: editing)

        }
        .foregroundStyle(ink)

    }

    private func review(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.actions.isEmpty ? "Actions" : "Review actions")
                    .font(.system(compact ? .title2 : .largeTitle, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !model.actions.isEmpty {
                    Text("\(kept.count) of \(model.actions.count) selected").font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(linkInk)
                        .padding(.vertical, 5)
                }
            }
            if model.busy {
                HStack(alignment: .top, spacing: 12) {
                    ProgressView().controlSize(.small)
                    Text(model.phase).font(.subheadline).foregroundStyle(mutedInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 20)
                .accessibilityElement(children: .combine)
            } else if model.error != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Couldn’t finish", systemImage: "exclamationmark.circle")
                        .font(.headline)
                    Text("Try again, or open run details to see what happened.")
                        .font(.subheadline).foregroundStyle(mutedInk)
                    Button("Run details") { showingDetails = true }.padding(.vertical, 6)
                }
            } else if model.actions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 28, weight: .light)).foregroundStyle(mutedInk)
                    Text(model.hasRun ? "No actions found" : "No suggestions yet")
                        .font(.headline)
                    Text(model.hasRun ? "Check your note for anything the model missed." : "Find actions, check the wording, then select the ones to keep.")
                        .font(.subheadline).foregroundStyle(mutedInk).lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(colorScheme == .dark ? Color(red: 0.15, green: 0.16, blue: 0.18) : Color(red: 0.94, green: 0.95, blue: 0.97), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Select actions to share. View source to check the original note.")
                    .font(.subheadline).foregroundStyle(mutedInk)
                VStack(spacing: 0) {
                    ForEach(model.actions) { action in
                        ActionReviewRow(action: action, isActive: activeSource == action.id,
                                        showSource: { activeSource = action.id; sourceExpanded = true; sourceReveal += 1; revising = false; editing = false },
                                        isKept: Binding(
                            get: { kept.contains(action.id) },
                            set: { if $0 { kept.insert(action.id) } else { kept.remove(action.id) } }
                        ))
                        Divider()
                    }
                }
                if kept.isEmpty {
                    Label("Select an action to share", systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(mutedInk).padding(.vertical, 8)
                } else if !compact {
                ShareLink(item: shareText) {
                    Label(kept.isEmpty ? "Select actions to share" : "Share selected (\(kept.count))", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44).padding(.horizontal, 18)
                        .foregroundStyle(Color.white)
                        .background(accent, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
        .transition(.opacity)
    }

    private func actionBar(compact: Bool) -> some View {
        HStack(spacing: 16) {
            if !compact {
                Spacer(minLength: 0)
            }
            if compact && !kept.isEmpty {
                Button("Find again") {
                    editing = false
                    Task { await model.extract() }
                }
                .font(.subheadline).frame(minHeight: 44)
                .buttonStyle(.plain).foregroundStyle(linkInk)
                ShareLink(item: shareText) {
                    Label("Share selected (\(kept.count))", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.borderedProminent).tint(accent)
            } else {
            Button {
                editing = false
                Task { await model.extract() }
            } label: {
                HStack(spacing: 10) {
                    if model.busy { ProgressView().tint(.white).controlSize(.small) }
                    Text(model.busy ? "Working…" : (model.hasRun ? "Find actions again" : "Find actions"))
                        .font(.body.weight(.semibold))
                    if !model.busy { Image(systemName: "arrow.right").font(.subheadline.weight(.semibold)) }
                }
                .frame(maxWidth: compact ? .infinity : nil)
                .padding(.horizontal, 20).frame(minHeight: 46)
                .foregroundStyle(model.hasRun && !model.busy ? linkInk : .white)
                .background(model.hasRun && !model.busy ? chrome : (canRun || model.busy ? accent : Color.secondary.opacity(0.35)), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(QuietPressStyle())
            .disabled(!canRun)
            .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .padding(.horizontal, compact ? 22 : 0).padding(.vertical, compact ? 14 : 0)
        .frame(maxWidth: .infinity)
        .background(compact ? chrome : Color.clear)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Local processing").font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { showingDetails = false }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Fieldnotes downloads a 1.93 GB model on first use. After download, your note is processed on this device.")
                    Text("Suggestions can be wrong. Review them before sharing. Notes and selections are kept only for this session.")
                        .foregroundStyle(mutedInk)
                    Divider()
                    LabeledContent("Model", value: "Qwen2.5 3B · Q4_K_M")
                    LabeledContent("Runtime", value: "RunAnywhere · llama.cpp")
                    if let metrics = model.metrics { Text(metrics).font(.caption.monospaced()).textSelection(.enabled) }
                    if let error = model.error { Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
                    if let raw = model.rawResponse {
                        DisclosureGroup("Model response") {
                            Text(raw).font(.caption.monospaced()).textSelection(.enabled).padding(.top, 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .frame(minWidth: 300, idealWidth: 480, minHeight: 400, idealHeight: 500)
    }
}

private struct ActionReviewRow: View {
    let action: Action
    let isActive: Bool
    let showSource: () -> Void
    @Binding var isKept: Bool
    @Environment(\.colorScheme) private var colorScheme
    private var link: Color { colorScheme == .dark ? Color(red: 0.65, green: 0.77, blue: 0.95) : Color(red: 0.17, green: 0.34, blue: 0.78) }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button { isKept.toggle() } label: {
                Image(systemName: isKept ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20)).foregroundStyle(link)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(QuietPressStyle())
            .accessibilityLabel(isKept ? "Remove action from selection" : "Keep action")
            .accessibilityValue(action.task)
            .accessibilityAddTraits(isKept ? .isSelected : [])
            Button(action: showSource) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(action.task).font(.body.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? Color(red: 0.97, green: 0.96, blue: 0.93) : Color.primary)
                        .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                    Text(isActive ? "Source highlighted" : "View source")
                        .font(.caption.weight(.medium)).foregroundStyle(link)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.vertical, 8).contentShape(Rectangle())
            }
            .buttonStyle(QuietPressStyle())
            .accessibilityLabel("View source for " + action.task)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(isActive ? Color(red: 0.90, green: 0.78, blue: 0.51).opacity(colorScheme == .dark ? 0.09 : 0.13) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct QuietPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#if os(macOS)
/// SwiftUI TextEditor does not consistently forward scroll-indicator visibility on macOS.
private struct EditorScrollerHider: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak view] in
            guard let view else { return }
            func editorScroll(in node: NSView) -> NSScrollView? {
                if let scroll = node as? NSScrollView {
                    func containsText(_ v: NSView) -> Bool {
                        v is NSTextView || v.subviews.contains(where: containsText)
                    }
                    if let document = scroll.documentView, containsText(document) { return scroll }
                }
                for child in node.subviews {
                    if let match = editorScroll(in: child) { return match }
                }
                return nil
            }
            var ancestor = view.superview
            while let node = ancestor {
                if let scroll = editorScroll(in: node) {
                    scroll.hasVerticalScroller = false
                    scroll.hasHorizontalScroller = false
                    return
                }
                ancestor = node.superview
            }
        }
    }
}
#endif
