//
//  FieldType.swift
//  Eulerity
//

import Foundation

/// The kind of control a field renders.
///
/// Known values map to the brief's exact uppercase tokens. Anything unrecognized
/// decodes to `.unsupported(rawValue:)` instead of throwing, so a server that
/// introduces a new type never breaks the app — the field is simply excluded
/// from render (Constitution V). Matching is **exact /
/// case-sensitive** by design (Plan.md B1), so `"text"` is unsupported, not `TEXT`.
nonisolated enum FieldType: Equatable, Sendable {
    case text
    case dropdown
    case toggle
    case checkbox
    case unsupported(rawValue: String)
}

extension FieldType: Decodable {
    nonisolated init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self.init(token: raw)
    }

    /// Maps a raw JSON token to a case; unknown → `.unsupported`, preserving the
    /// original token for logging/diagnostics. - Complexity: O(1).
    nonisolated init(token: String) {
        switch token {
        case "TEXT": self = .text
        case "DROPDOWN": self = .dropdown
        case "TOGGLE": self = .toggle
        case "CHECKBOX": self = .checkbox
        default: self = .unsupported(rawValue: token)
        }
    }

    /// Whether this type is one the app knows how to render.
    /// - Complexity: O(1).
    nonisolated var isSupported: Bool {
        if case .unsupported = self { return false }
        return true
    }
}
