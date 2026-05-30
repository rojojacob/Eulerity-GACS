//
//  Validation.swift
//  Eulerity
//
//  Pure validation rules over field values. NO `import SwiftUI`. Built during
//  Phase D (Plan.md §6):
//    • Validator — validate(fields:values:) -> [String: String] (fieldId → error).
//      Rules: required-empty, regex (compile once, reuse), max_length re-check,
//      multi-select-required, empty-options-required-dropdown conflict.
//      - Complexity: O(n) over fields; each rule O(1)/O(len).
//
//  Intentionally empty in the skeleton.
//
