import SwiftUI

struct ReplacementRulesList: View {
    let store: RuleStore

    @State private var editing: ReplacementRule?
    @State private var isAdding = false

    var body: some View {
        VStack(spacing: 0) {
            ForEach(store.rules) { rule in
                ruleRow(rule)
                Divider().padding(.horizontal, 12)
            }

            Button {
                isAdding = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                    Text("Add Rule")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .sheet(item: $editing) { rule in
            RuleEditorView(rule: rule) { store.update($0) }
        }
        .sheet(isPresented: $isAdding) {
            RuleEditorView(rule: nil) { store.add($0) }
        }
    }

    private func ruleRow(_ rule: ReplacementRule) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                Text(summary(rule.kind))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Menu {
                Button("Edit") { editing = rule }
                Button("Duplicate") { store.duplicate(rule) }
                Divider()
                Button("Delete", role: .destructive) { store.delete(rule) }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            .menuIndicator(.hidden)
            .fixedSize()

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { store.setEnabled(rule, $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summary(_ kind: ReplacementRule.Kind) -> String {
        switch kind {
        case let .stripTrackingParams(names):
            return "Remove " + names.joined(separator: ", ")
        case let .findReplace(pattern, replacement, _):
            return pattern + " → " + (replacement.isEmpty ? "∅" : replacement)
        }
    }
}

struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let ruleID: UUID?
    private let isEnabled: Bool
    private let onSave: (ReplacementRule) -> Void

    @State private var name: String
    @State private var kindTag: KindTag
    @State private var paramsText: String
    @State private var pattern: String
    @State private var replacement: String
    @State private var isRegex: Bool

    enum KindTag: String, CaseIterable, Identifiable {
        case tracking = "Tracking params"
        case findReplace = "Find & replace"
        var id: String { rawValue }
    }

    init(rule: ReplacementRule?, onSave: @escaping (ReplacementRule) -> Void) {
        self.onSave = onSave
        self.ruleID = rule?.id
        self.isEnabled = rule?.isEnabled ?? true

        var kindTag: KindTag = .findReplace
        var paramsText = ""
        var pattern = ""
        var replacement = ""
        var isRegex = false

        switch rule?.kind {
        case let .stripTrackingParams(names):
            kindTag = .tracking
            paramsText = names.joined(separator: "\n")
        case let .findReplace(p, r, rx):
            pattern = p
            replacement = r
            isRegex = rx
        case nil:
            break
        }

        _name = State(initialValue: rule?.name ?? "")
        _kindTag = State(initialValue: kindTag)
        _paramsText = State(initialValue: paramsText)
        _pattern = State(initialValue: pattern)
        _replacement = State(initialValue: replacement)
        _isRegex = State(initialValue: isRegex)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Form {
                TextField("Name", text: $name)

                Picker("Type", selection: $kindTag) {
                    ForEach(KindTag.allCases) { Text($0.rawValue).tag($0) }
                }

                if kindTag == .tracking {
                    Section("Parameters to remove") {
                        TextEditor(text: $paramsText)
                            .font(.body.monospaced())
                            .frame(minHeight: 120)
                        Text("One per line. A trailing * matches a prefix, e.g. utm_*")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Replacement") {
                        TextField("Find", text: $pattern)
                        TextField("Replace with", text: $replacement)
                        Toggle("Regular expression", isOn: $isRegex)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 380, height: 440)
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
            Spacer()
            Text(ruleID == nil ? "New Rule" : "Edit Rule").font(.headline)
            Spacer()
            Button("Save") { save() }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }

    private func save() {
        let kind: ReplacementRule.Kind
        switch kindTag {
        case .tracking:
            kind = .stripTrackingParams(names: parseParams(paramsText))
        case .findReplace:
            kind = .findReplace(pattern: pattern, replacement: replacement, isRegex: isRegex)
        }

        onSave(ReplacementRule(
            id: ruleID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            isEnabled: isEnabled,
            kind: kind
        ))
        dismiss()
    }

    private func parseParams(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == "\n" || $0 == "," || $0 == " " })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
