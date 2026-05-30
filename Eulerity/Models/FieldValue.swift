//
//  FieldValue.swift
//  Eulerity
//

import Foundation

/// The live value a user has entered for a field. One case per storage shape,
/// so a field's state is always exactly one of these — never an ambiguous bag of
/// optionals. Dropdowns store option **ids** (not labels). Pure, SwiftUI-free.
nonisolated enum FieldValue: Equatable, Sendable {
    case text(String)
    case bool(Bool)
    case selection([String])
}

extension FieldValue {
    /// The string payload, if this is a `.text` value. - Complexity: O(1).
    nonisolated var text: String? {
        if case let .text(value) = self { return value }
        return nil
    }

    /// The boolean payload, if this is a `.bool` value. - Complexity: O(1).
    nonisolated var bool: Bool? {
        if case let .bool(value) = self { return value }
        return nil
    }

    /// The selected option ids, if this is a `.selection` value. - Complexity: O(1).
    nonisolated var selection: [String]? {
        if case let .selection(value) = self { return value }
        return nil
    }
}
