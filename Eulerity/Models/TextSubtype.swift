//
//  TextSubtype.swift
//  Eulerity
//

import Foundation

/// The flavor of a `TEXT` field.
///
/// Unknown subtypes fall back to `.plain` — a deliberate product decision:
/// a `TEXT` field is always usable as a plain text box even if
/// the server sends a subtype we don't recognize. The `String` raw values match
/// the brief's exact uppercase tokens.
nonisolated enum TextSubtype: String, Sendable, Equatable, CaseIterable {
    case plain = "PLAIN"
    case multiline = "MULTILINE"
    case number = "NUMBER"
    case uri = "URI"
    case secure = "SECURE"
}

extension TextSubtype: Decodable {
    /// Decodes a subtype token, defaulting any unrecognized value to `.plain`
    /// rather than throwing. - Complexity: O(1).
    nonisolated init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TextSubtype(rawValue: raw) ?? .plain
    }
}
