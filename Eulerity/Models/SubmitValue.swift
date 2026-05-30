//
//  SubmitValue.swift
//  Eulerity
//

import Foundation

/// A single value in the submitted payload, typed so the submit shape is
/// assertable in tests. Preserves the scalar-vs-array distinction (Plan.md D2):
/// text and single-select are scalars, multi-select is an array, toggles are bools.
nonisolated enum SubmitValue: Equatable, Sendable {
    case string(String)
    case bool(Bool)
    case strings([String])
}

extension SubmitValue {
    /// A JSON-serializable (`JSONSerialization`-compatible) representation.
    /// - Complexity: O(1).
    nonisolated var jsonValue: Any {
        switch self {
        case .string(let value): return value
        case .bool(let value): return value
        case .strings(let value): return value
        }
    }
}
