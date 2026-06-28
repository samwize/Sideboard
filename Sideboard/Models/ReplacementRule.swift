import Foundation

struct ReplacementRule: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var isEnabled: Bool
    var kind: Kind

    enum Kind: Codable, Equatable {
        case stripTrackingParams(names: [String])
        case findReplace(pattern: String, replacement: String, isRegex: Bool)
    }

    init(id: UUID = UUID(), name: String, isEnabled: Bool, kind: Kind) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.kind = kind
    }
}

extension ReplacementRule {
    static var defaults: [ReplacementRule] {
        [
            ReplacementRule(name: "Tracking params", isEnabled: true, kind: .stripTrackingParams(names: [
                "utm_*", "gclid", "gbraid", "wbraid", "dclid", "fbclid", "msclkid",
                "igshid", "igsh", "ttclid", "twclid", "li_fat_id",
                "mc_cid", "mc_eid", "_hsenc", "_hsmi", "yclid", "mkt_tok"
            ])),
            ReplacementRule(name: "Share tokens", isEnabled: false, kind: .stripTrackingParams(names: [
                "si", "ref", "ref_src", "s", "t", "spm", "scm"
            ])),
            ReplacementRule(name: "Amazon links", isEnabled: false, kind: .findReplace(
                pattern: #"(https?://(?:www\.)?amazon\.[a-z.]+)/(?:[^\s]*/)?dp/([A-Z0-9]{10})[^\s]*"#,
                replacement: "$1/dp/$2",
                isRegex: true
            )),
            ReplacementRule(name: "Straight quotes", isEnabled: false, kind: .findReplace(
                pattern: "[\u{201C}\u{201D}]", replacement: "\"", isRegex: true
            )),
            ReplacementRule(name: "Straight apostrophes", isEnabled: false, kind: .findReplace(
                pattern: "[\u{2018}\u{2019}]", replacement: "'", isRegex: true
            )),
            ReplacementRule(name: "Invisible characters", isEnabled: false, kind: .findReplace(
                pattern: "[\u{200B}-\u{200D}\u{FEFF}]", replacement: "", isRegex: true
            )),
            ReplacementRule(name: "No-break spaces", isEnabled: false, kind: .findReplace(
                pattern: "\u{00A0}", replacement: " ", isRegex: false
            )),
            ReplacementRule(name: "Trim whitespace", isEnabled: false, kind: .findReplace(
                pattern: #"^\s+|\s+$"#, replacement: "", isRegex: true
            ))
        ]
    }
}
