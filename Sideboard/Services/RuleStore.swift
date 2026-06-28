import Foundation

@MainActor
@Observable
final class RuleStore {
    private(set) var rules: [ReplacementRule]
    var onChange: (() -> Void)?

    private let defaults = UserDefaults.standard
    private let storageKey = "replacementRules"
    private let seedKey = "replacementRulesSeeded"

    init() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ReplacementRule].self, from: data) {
            rules = decoded
        } else if defaults.bool(forKey: seedKey) {
            rules = []
        } else {
            rules = ReplacementRule.defaults
            defaults.set(true, forKey: seedKey)
            persist()
        }
    }

    func add(_ rule: ReplacementRule) {
        rules.append(rule)
        changed()
    }

    func update(_ rule: ReplacementRule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index] = rule
        changed()
    }

    func setEnabled(_ rule: ReplacementRule, _ isEnabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index].isEnabled = isEnabled
        changed()
    }

    func duplicate(_ rule: ReplacementRule) {
        let copy = ReplacementRule(name: rule.name + " copy", isEnabled: rule.isEnabled, kind: rule.kind)
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules.insert(copy, at: index + 1)
        } else {
            rules.append(copy)
        }
        changed()
    }

    func delete(_ rule: ReplacementRule) {
        rules.removeAll { $0.id == rule.id }
        changed()
    }

    private func changed() {
        persist()
        onChange?()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
