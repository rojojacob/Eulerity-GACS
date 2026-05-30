//
//  RichTextLabel.swift
//  Eulerity
//

import Foundation

/// Builds an attributed checkbox label, turning each `metadata` key that appears
/// as a substring of the label into a tappable link to its URL (Plan.md F1).
///
/// Defensive (Constitution V / §7 #10): a key not found in the label is ignored,
/// and a malformed URL (or one without a scheme) is left as plain text. Foundation
/// only — the link *color* is applied by the view via `.tint`, so this stays pure
/// and unit-testable.
nonisolated enum RichTextLabel {

    /// - Complexity: O(L·k) — for k metadata keys, each substring search is O(L).
    static func make(label: String, metadata: [String: String]?) -> AttributedString {
        var attributed = AttributedString(label)
        guard let metadata else { return attributed }
        for (key, urlString) in metadata {
            guard let url = URL(string: urlString),
                  url.scheme != nil,
                  let range = attributed.range(of: key) else { continue }
            attributed[range].link = url
        }
        return attributed
    }
}
