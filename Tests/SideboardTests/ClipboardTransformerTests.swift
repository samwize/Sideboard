import Foundation
import Testing
@testable import Sideboard

struct ClipboardTransformerTests {
    private func rule(_ kind: ReplacementRule.Kind, name: String = "Rule", enabled: Bool = true) -> ReplacementRule {
        ReplacementRule(name: name, isEnabled: enabled, kind: kind)
    }

    @Test
    func stripsTrackingParameters() {
        let rules = [rule(.stripTrackingParams(names: ["utm_*", "fbclid"]))]
        let result = ClipboardTransformer.apply(
            rules: rules,
            to: "https://example.com/article?utm_source=news&utm_medium=email&id=42&fbclid=abc"
        )

        #expect(result.text == "https://example.com/article?id=42")
        #expect(result.appliedRuleNames == ["Rule"])
    }

    @Test
    func dropsQuestionMarkWhenAllParamsRemoved() {
        let rules = [rule(.stripTrackingParams(names: ["utm_*"]))]
        let result = ClipboardTransformer.apply(rules: rules, to: "https://example.com/a?utm_source=x")

        #expect(result.text == "https://example.com/a")
    }

    @Test
    func preservesEncodedValuesOfRetainedParams() {
        let rules = [rule(.stripTrackingParams(names: ["utm_*"]))]
        let result = ClipboardTransformer.apply(
            rules: rules,
            to: "https://api.example.com/x?token=%2Babc%3D&utm_source=news"
        )

        #expect(result.text == "https://api.example.com/x?token=%2Babc%3D")
    }

    @Test
    func cleansEveryUrlInText() {
        let rules = [rule(.stripTrackingParams(names: ["utm_source"]))]
        let result = ClipboardTransformer.apply(
            rules: rules,
            to: "see https://a.com/x?utm_source=1 and https://b.com/y?utm_source=2"
        )

        #expect(result.text == "see https://a.com/x and https://b.com/y")
    }

    @Test
    func leavesPlainTextUntouched() {
        let rules = [rule(.stripTrackingParams(names: ["utm_*"]))]
        let text = "just some prose with utm_source written in it"
        let result = ClipboardTransformer.apply(rules: rules, to: text)

        #expect(result.text == text)
        #expect(result.appliedRuleNames.isEmpty)
    }

    @Test
    func isIdempotent() {
        let rules = [rule(.stripTrackingParams(names: ["utm_*"]))]
        let once = ClipboardTransformer.apply(rules: rules, to: "https://example.com/a?utm_source=x&keep=1")
        let twice = ClipboardTransformer.apply(rules: rules, to: once.text)

        #expect(once.text == "https://example.com/a?keep=1")
        #expect(twice.text == once.text)
        #expect(twice.appliedRuleNames.isEmpty)
    }

    @Test
    func shortensAmazonLinks() {
        let amazon = ReplacementRule.defaults.first { $0.name == "Amazon links" }!
        let enabled = ReplacementRule(name: amazon.name, isEnabled: true, kind: amazon.kind)
        let result = ClipboardTransformer.apply(
            rules: [enabled],
            to: "https://www.amazon.com/Anker-PowerCore/dp/B07S829LBX/ref=sr_1_3?keywords=power+bank"
        )

        #expect(result.text == "https://www.amazon.com/dp/B07S829LBX")
    }

    @Test
    func disabledRuleIsIgnored() {
        let rules = [rule(.stripTrackingParams(names: ["utm_*"]), enabled: false)]
        let text = "https://example.com/a?utm_source=x"
        let result = ClipboardTransformer.apply(rules: rules, to: text)

        #expect(result.text == text)
        #expect(result.appliedRuleNames.isEmpty)
    }

    @Test
    func literalFindReplace() {
        let rules = [rule(.findReplace(pattern: "\u{00A0}", replacement: " ", isRegex: false))]
        let result = ClipboardTransformer.apply(rules: rules, to: "npm\u{00A0}install")

        #expect(result.text == "npm install")
    }

    @Test
    func regexFindReplaceUsesTemplate() {
        let rules = [rule(.findReplace(pattern: #"ENG-(\d+)"#, replacement: "https://linear.app/acme/issue/ENG-$1", isRegex: true))]
        let result = ClipboardTransformer.apply(rules: rules, to: "ENG-412")

        #expect(result.text == "https://linear.app/acme/issue/ENG-412")
    }

    @Test
    func stripsInvisibleCharacters() {
        let rules = [rule(.findReplace(pattern: "[\u{200B}-\u{200D}\u{FEFF}]", replacement: "", isRegex: true))]
        let result = ClipboardTransformer.apply(rules: rules, to: "he\u{200B}llo\u{FEFF} world")

        #expect(result.text == "hello world")
    }

    @Test
    func appliesRulesInOrderAndReportsEachThatFires() {
        let rules = [
            rule(.stripTrackingParams(names: ["utm_*"]), name: "Tracking"),
            rule(.findReplace(pattern: #"\s+$"#, replacement: "", isRegex: true), name: "Trim")
        ]
        let result = ClipboardTransformer.apply(rules: rules, to: "https://x.com/a?utm_source=z   ")

        #expect(result.text == "https://x.com/a")
        #expect(result.appliedRuleNames == ["Tracking", "Trim"])
    }
}
