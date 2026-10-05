import SwiftUI

/// Prompt Builder home: pick what you want to do, then answer a few questions.
struct PromptBuilderView: View {
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(PromptLibrary.self) private var library
    @State private var showPaywall = false
    @State private var selectedGoal: PromptGoal?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                NavigationLink {
                    SavedPromptsView()
                } label: {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(Theme.gold)
                        Text("My saved prompts")
                            .font(.rounded(.headline, weight: .semibold))
                        Spacer()
                        Text("\(library.prompts.count)")
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .card()
                }
                .buttonStyle(.plain)

                Text("What do you want Claude to help with?")
                    .font(.rounded(.title3, weight: .bold))

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(PromptCatalog.goals) { goal in
                        Button {
                            Haptics.tap()
                            if goal.isFree || subscriptions.hasAccess {
                                selectedGoal = goal
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            GoalTile(goal: goal, locked: !goal.isFree && !subscriptions.hasAccess)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Prompt Builder")
        .navigationDestination(item: $selectedGoal) { goal in
            PromptWizardView(goal: goal)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Not sure what to type? Answer a few easy questions and we'll write a great prompt for you.")
                .font(.rounded(.body))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                StepPill(number: 1, text: "Pick a goal")
                StepPill(number: 2, text: "Answer")
                StepPill(number: 3, text: "Copy to Claude")
            }
        }
    }
}

private struct StepPill: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Text("\(number)")
                .font(.rounded(.caption, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Theme.gold, in: Circle())
            Text(text)
                .font(.rounded(.caption, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke))
    }
}

private struct GoalTile: View {
    let goal: PromptGoal
    let locked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(goal.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.gold)
                        .accessibilityLabel("Pro")
                }
            }
            Text(goal.title)
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Text(goal.subtitle)
                .font(.rounded(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .card(padding: 14)
        .opacity(locked ? 0.75 : 1)
    }
}

// MARK: - Wizard

struct PromptWizardView: View {
    enum Step: Int, CaseIterable {
        case task, context, audience, tone, format, extras, review

        var title: String {
            switch self {
            case .task: "Your task"
            case .context: "Background"
            case .audience: "Audience"
            case .tone: "Tone"
            case .format: "Format & length"
            case .extras: "Finishing touches"
            case .review: "Your prompt"
            }
        }
    }

    @Environment(ProgressStore.self) private var progress
    @Environment(PromptLibrary.self) private var library
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @State private var draft: PromptDraft
    @State private var step: Step = .task
    @State private var finalText = ""
    @State private var toast: String?
    @State private var newBadges: [Badge] = []
    @State private var hasRecorded = false
    @State private var showSaveAlert = false
    @State private var saveTitle = ""
    @FocusState private var editorFocused: Bool

    init(goal: PromptGoal) {
        _draft = State(initialValue: PromptDraft(goal: goal))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                        .font(.rounded(.caption, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(step.title)
                        .font(.rounded(.caption, weight: .bold))
                        .foregroundStyle(draft.goal.tint)
                }
                ProgressBar(progress: Double(step.rawValue + 1) / Double(Step.allCases.count),
                            tint: draft.goal.tint, height: 6)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    stepContent
                    if step != .review && step != .task {
                        PromptPeek(text: draft.assembled)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)

            bottomBar
        }
        .background(Theme.background)
        .navigationTitle(draft.goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) { toastView }
        .overlay { if !newBadges.isEmpty { ConfettiView().ignoresSafeArea() } }
        .alert("Save prompt", isPresented: $showSaveAlert) {
            TextField("Name", text: $saveTitle)
            Button("Save") { save() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give this prompt a name so you can find it later.")
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .task:
            QuestionHeader(title: draft.goal.taskQuestion,
                           hint: "Be specific. \"Write an email\" is OK — \"Ask my manager for Friday off\" is much better.")
            TextEditorCard(text: $draft.task, placeholder: draft.goal.taskPlaceholder)
                .focused($editorFocused)
            Text("Or tap an example to start:")
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(.secondary)
            FlowLayout {
                ForEach(draft.goal.taskExamples, id: \.self) { example in
                    Button { draft.task = example; Haptics.tap() } label: {
                        ChipView(title: example, isSelected: draft.task == example)
                    }
                    .buttonStyle(.plain)
                }
            }

        case .context:
            QuestionHeader(title: "What should Claude know?",
                           hint: "Context is the #1 secret to great answers. Share the situation, details, or limits — like you'd brief a helpful colleague. (Optional)")
            TextEditorCard(text: $draft.context, placeholder: draft.goal.contextPlaceholder)
                .focused($editorFocused)
            TipRow(text: "Never share passwords, bank details, or private information about other people.")

        case .audience:
            QuestionHeader(title: "Who is this for?",
                           hint: "Claude writes differently for your boss than for a friend.")
            ChipPicker(options: draft.goal.audiences, selection: Binding(
                get: { draft.audience.isEmpty ? [] : [draft.audience] },
                set: { draft.audience = $0.last ?? "" }
            ), allowsCustom: true, customPlaceholder: "Someone else…")

        case .tone:
            QuestionHeader(title: "How should it sound?",
                           hint: "Pick up to two.")
            ChipPicker(options: PromptCatalog.tones, selection: Binding(
                get: { draft.tones },
                set: { draft.tones = Array($0.suffix(2)) }
            ))

        case .format:
            QuestionHeader(title: "What shape should the answer take?",
                           hint: "Asking for a format saves you from reformatting later.")
            ChipPicker(options: draft.goal.formats, selection: Binding(
                get: { draft.format.isEmpty ? [] : [draft.format] },
                set: { draft.format = $0.last ?? "" }
            ), allowsCustom: true, customPlaceholder: "Another format…")

            Text("Length")
                .font(.rounded(.headline, weight: .bold))
                .padding(.top, 6)
            Picker("Length", selection: $draft.lengthIndex) {
                ForEach(PromptCatalog.lengths.indices, id: \.self) { index in
                    Text(PromptCatalog.lengths[index].label).tag(index)
                }
            }
            .pickerStyle(.segmented)

        case .extras:
            QuestionHeader(title: "Any finishing touches?",
                           hint: "These small requests make a big difference. We've turned on our favorite.")
            VStack(spacing: 10) {
                ForEach(draft.allExtras, id: \.self) { extra in
                    Toggle(isOn: Binding(
                        get: { draft.extras.contains(extra) },
                        set: { isOn in
                            if isOn { draft.extras.insert(extra) } else { draft.extras.remove(extra) }
                        }
                    )) {
                        Text(extra).font(.rounded(.body))
                    }
                    .tint(draft.goal.tint)
                    .card(padding: 14)
                }
            }

        case .review:
            reviewContent
        }
    }

    @ViewBuilder
    private var reviewContent: some View {
        StrengthMeter(draft: draft) { checkID in
            switch checkID {
            case "task": step = .task
            case "context": step = .context
            case "audience": step = .audience
            case "tone": step = .tone
            default: step = .format
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your prompt")
                    .font(.rounded(.headline, weight: .bold))
                Spacer()
                Text("Tap to edit")
                    .font(.rounded(.caption))
                    .foregroundStyle(.secondary)
            }
            TextEditor(text: $finalText)
                .font(.system(.body, design: .default))
                .frame(minHeight: 260)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke))
                .focused($editorFocused)
        }

        VStack(spacing: 10) {
            Button {
                copy()
                recordUse()
                openURL(AppConfig.claudeURL(prefill: finalText))
            } label: {
                Label("Copy & open Claude", systemImage: "arrow.up.forward.app.fill")
            }
            .buttonStyle(PrimaryButtonStyle(tint: draft.goal.tint))

            HStack(spacing: 10) {
                Button {
                    copy()
                    recordUse()
                    showToast("Copied! Paste it into Claude.")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    saveTitle = String(draft.task.prefix(40))
                    showSaveAlert = true
                } label: {
                    Label("Save", systemImage: "bookmark")
                }
                .buttonStyle(SecondaryButtonStyle())

                ShareLink(item: finalText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .labelStyle(.titleAndIcon)
        }

        TipRow(text: "In Claude, if the answer isn't quite right, just reply with what to change — like \"shorter\" or \"more friendly\". You don't have to start over.")
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .task {
                Button {
                    editorFocused = false
                    if let previous = Step(rawValue: step.rawValue - 1) { step = previous }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 54, height: 54)
                        .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel("Back")
            }

            if step == .review {
                Button("Start a new prompt") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
            } else {
                Button(nextLabel) {
                    editorFocused = false
                    Haptics.tap()
                    if let next = Step(rawValue: step.rawValue + 1) {
                        if next == .review { finalText = draft.assembled }
                        step = next
                    }
                }
                .buttonStyle(PrimaryButtonStyle(tint: draft.goal.tint))
                .disabled(step == .task && draft.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(.bar)
    }

    private var nextLabel: String {
        switch step {
        case .context where draft.context.isEmpty: "Skip"
        case .audience where draft.audience.isEmpty: "Skip"
        case .tone where draft.tones.isEmpty: "Skip"
        case .extras: "Build my prompt ✨"
        default: "Next"
        }
    }

    // MARK: Actions

    private func copy() {
        UIPasteboard.general.string = finalText
        Haptics.success()
    }

    private func recordUse() {
        guard !hasRecorded else { return }
        hasRecorded = true
        let badges = progress.recordPromptBuilt(savedCount: library.prompts.count)
        if !badges.isEmpty {
            newBadges = badges
            showToast("🏅 Badge unlocked: \(badges.map(\.title).joined(separator: ", "))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { newBadges = [] }
        }
    }

    private func save() {
        let title = saveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        library.add(SavedPrompt(title: title.isEmpty ? draft.goal.title : title,
                                goalID: draft.goal.id, text: finalText))
        Haptics.success()
        hasRecorded = false // every save re-checks the "Prompt Collector" badge
        recordUse()
        if newBadges.isEmpty { showToast("Saved to your library") }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut) { if toast == message { toast = nil } }
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Theme.brandDeep.opacity(0.95), in: Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Building blocks

private struct QuestionHeader: View {
    let title: String
    let hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.rounded(.title2, weight: .bold))
            Text(hint)
                .font(.rounded(.subheadline))
                .foregroundStyle(.secondary)
        }
    }
}

private struct TextEditorCard: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 130)
        }
        .font(.rounded(.body))
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke))
    }
}

/// Multi/single-select chips with an optional "write your own" field.
private struct ChipPicker: View {
    let options: [String]
    @Binding var selection: [String]
    var allowsCustom = false
    var customPlaceholder = ""
    @State var custom = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FlowLayout {
                ForEach(options, id: \.self) { option in
                    Button {
                        Haptics.tap()
                        if let index = selection.firstIndex(of: option) {
                            selection.remove(at: index)
                        } else {
                            selection.append(option)
                        }
                    } label: {
                        ChipView(title: option, isSelected: selection.contains(option),
                                 icon: selection.contains(option) ? "checkmark" : nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            if allowsCustom {
                TextField(customPlaceholder, text: $custom)
                    .font(.rounded(.body))
                    .padding(14)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke))
                    .submitLabel(.done)
                    .onSubmit {
                        let value = custom.trimmingCharacters(in: .whitespaces)
                        if !value.isEmpty { selection = [value] }
                    }
                    .onChange(of: custom) { _, newValue in
                        let value = newValue.trimmingCharacters(in: .whitespaces)
                        if !value.isEmpty { selection = [value] }
                    }
            }
        }
    }
}

private struct PromptPeek: View {
    let text: String
    @State var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } label: {
            Label("Peek at your prompt so far", systemImage: "eye")
                .font(.rounded(.subheadline, weight: .semibold))
        }
        .card(padding: 14)
    }
}

struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Theme.gold)
            Text(text)
                .font(.rounded(.subheadline))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.goldSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct StrengthMeter: View {
    let draft: PromptDraft
    let jump: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Prompt strength")
                    .font(.rounded(.headline, weight: .bold))
                Spacer()
                Text(draft.strengthLabel)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(draft.strength >= 0.8 ? Theme.success : Theme.gold)
            }
            ProgressBar(progress: draft.strength, tint: draft.strength >= 0.8 ? Theme.success : Theme.gold, height: 10)
            FlowLayout(spacing: 6) {
                ForEach(draft.checks) { check in
                    Button { if !check.passed { jump(check.id) } } label: {
                        HStack(spacing: 4) {
                            Image(systemName: check.passed ? "checkmark.circle.fill" : "plus.circle")
                            Text(check.label)
                        }
                        .font(.rounded(.caption, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(check.passed ? Theme.success : Theme.brand)
                        .background(check.passed ? Theme.successSoft : Theme.surfaceRaised, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(check.passed ? "" : check.tip)
                }
            }
            if let firstMissing = draft.checks.first(where: { !$0.passed }) {
                Text("Tip: \(firstMissing.tip) Tap a + to add it.")
                    .font(.rounded(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

// MARK: - Saved prompts

struct SavedPromptsView: View {
    @Environment(PromptLibrary.self) private var library

    var body: some View {
        Group {
            if library.prompts.isEmpty {
                ContentUnavailableView("No saved prompts yet",
                                       systemImage: "bookmark",
                                       description: Text("Build a prompt and tap Save to keep it here for next time."))
            } else {
                List {
                    ForEach(library.prompts) { prompt in
                        NavigationLink {
                            SavedPromptDetail(prompt: prompt)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prompt.title).font(.rounded(.headline, weight: .semibold))
                                Text(prompt.text)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { library.delete(at: $0) }
                }
            }
        }
        .navigationTitle("Saved prompts")
    }
}

private struct SavedPromptDetail: View {
    let prompt: SavedPrompt
    @Environment(\.openURL) var openURL
    @State var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(prompt.text)
                    .textSelection(.enabled)
                    .card()
                Button {
                    UIPasteboard.general.string = prompt.text
                    Haptics.success()
                    openURL(AppConfig.claudeURL(prefill: prompt.text))
                } label: {
                    Label("Copy & open Claude", systemImage: "arrow.up.forward.app.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button {
                    UIPasteboard.general.string = prompt.text
                    Haptics.success()
                    copied = true
                } label: {
                    Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(prompt.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
