//
//  Validator.swift
//  Eulerity
//

import Foundation

/// Validates field values on Save. Pure and SwiftUI-free: it
/// takes the fields and their current values and returns `fieldId → error message`
/// for every invalid field — an empty result means the form is valid.
nonisolated enum Validator {

    /// Validates all fields against `values`.
    ///
    /// - Complexity: O(n) over fields; each field's check is O(1), except a `TEXT`
    ///   field with a `regex`, which is O(L) to compile and match.
    static func validate(
        fields: [FormField],
        values: [String: FieldValue],
        regexes: [String: NSRegularExpression] = [:]
    ) -> [String: String] {
        var errors: [String: String] = [:]
        for field in fields {
            if let message = error(for: field, value: values[field.id], precompiledRegex: regexes[field.id]) {
                errors[field.id] = message
            }
        }
        return errors
    }

    /// The validation error for a single field, or `nil` if it is valid.
    private static func error(for field: FormField, value: FieldValue?, precompiledRegex: NSRegularExpression?) -> String? {
        switch field.kind {
        case .text:
            let text = value?.text ?? ""
            if field.isRequired && text.isEmpty {
                return requiredMessage(field)
            }
            // `max_length` is enforced live at input; re-checked here defensively.
            if let maxLength = field.maxLength, text.count > maxLength {
                return "Must be \(maxLength) characters or fewer."
            }
            // Regex only applies to a non-empty value (emptiness is the required rule's job).
            if let pattern = field.regex, !text.isEmpty, !matches(pattern, text, precompiled: precompiledRegex) {
                return field.errorMessage ?? "Please match the requested format."
            }
            return nil

        case .toggle:
            // A toggle always holds a valid boolean; nothing to validate.
            return nil

        case .checkbox:
            let isOn = value?.bool ?? false
            return (field.isRequired && !isOn) ? requiredMessage(field) : nil

        case .dropdown:
            guard field.isRequired else { return nil }
            // A chosen option (or a locally-added billing card) satisfies it; an
            // empty selection is still surfaced so submit stays blocked.
            let selection = value?.selection ?? []
            return selection.isEmpty ? requiredMessage(field) : nil

        case .unsupported:
            return nil
        }
    }

    private static func requiredMessage(_ field: FormField) -> String {
        field.errorMessage ?? "This field is required."
    }

    /// Whether `text` satisfies `pattern`. Uses `precompiled` when available
    /// (compiled once at the view model — Plan.md F2), otherwise compiles inline.
    /// An invalid pattern is treated as "no rule" (returns `true`), never a crash.
    /// - Complexity: O(L) to match; O(pattern) to compile when not precompiled.
    private static func matches(_ pattern: String, _ text: String, precompiled: NSRegularExpression?) -> Bool {
        let regex = precompiled ?? (try? NSRegularExpression(pattern: pattern))
        guard let regex else { return true }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }
}
