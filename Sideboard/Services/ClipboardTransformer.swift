import Foundation

enum ClipboardTransformer {
    struct Result {
        let text: String
        let appliedRuleNames: [String]
    }

    // NSDataDetector is immutable and thread-safe; build it once instead of per copy.
    private static let linkDetector =
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    static func apply(rules: [ReplacementRule], to text: String) -> Result {
        var current = text
        var fired: [String] = []

        for rule in rules where rule.isEnabled {
            let next = apply(rule.kind, to: current)
            if next != current {
                current = next
                fired.append(rule.name)
            }
        }

        return Result(text: current, appliedRuleNames: fired)
    }

    private static func apply(_ kind: ReplacementRule.Kind, to text: String) -> String {
        switch kind {
        case let .stripTrackingParams(names):
            return stripTrackingParams(names: names, in: text)
        case let .findReplace(pattern, replacement, isRegex):
            return findReplace(pattern: pattern, replacement: replacement, isRegex: isRegex, in: text)
        }
    }

    private static func stripTrackingParams(names: [String], in text: String) -> String {
        guard let detector = linkDetector else { return text }
        let loweredNames = names.map { $0.lowercased() }

        let nsText = text as NSString
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return text }

        let result = NSMutableString(string: text)
        // Reverse so each replacement leaves earlier match ranges valid.
        for match in matches.reversed() {
            let urlString = nsText.substring(with: match.range)
            guard var components = URLComponents(string: urlString),
                  let query = components.percentEncodedQuery, !query.isEmpty
            else { continue }

            let pairs = query.components(separatedBy: "&")
            let kept = pairs.filter { pair in
                let rawName = String(pair.prefix { $0 != "=" })
                let name = (rawName.removingPercentEncoding ?? rawName).lowercased()
                return !loweredNames.contains { isBlocked(name: name, pattern: $0) }
            }
            guard kept.count != pairs.count else { continue }

            components.percentEncodedQuery = kept.isEmpty ? nil : kept.joined(separator: "&")
            guard let cleaned = components.string else { continue }

            result.replaceCharacters(in: match.range, with: cleaned)
        }

        return result as String
    }

    private static func isBlocked(name: String, pattern: String) -> Bool {
        if pattern.hasSuffix("*") {
            return name.hasPrefix(pattern.dropLast())
        }
        return name == pattern
    }

    private static func findReplace(pattern: String, replacement: String, isRegex: Bool, in text: String) -> String {
        guard !pattern.isEmpty else { return text }

        if isRegex {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
        }

        return text.replacingOccurrences(of: pattern, with: replacement)
    }
}
