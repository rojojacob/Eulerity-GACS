//
//  Validator.swift
//  Eulerity
//

import Foundation

/// Validates field values on Save (Plan.md §7 #13). Pure and SwiftUI-free: it
/// takes the fields and their current values and returns `fieldId → error message`
/// for every invalid field — an empty result means the form is valid.
nonisolated enum Validator {

    /// Validates all fields against `values`.
    ///
    /// - Complexity: O(n) over fields; each field's check is O(1), except a `TEXT`
    ///   field with a `regex`, which is O(L) to compile and match.
    static func validate(fields: [FormField], values: [String: FieldValue]) -> [String: String] {
        var errors: [String: String] = [:]
        for field in fields {
            if let message = error(for: field, value: values[field.id]) {
                errors[field.id] = message
            }
        }
        return errors
    }

    /// The validation error for a single field, or `nil` if it is valid.
    private static func error(for field: FormField, value: FieldValue?) -> String? {
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
            if let pattern = field.regex, !text.isEmpty, !matches(pattern, text) {
                return field.errorMessage ?? "Please match the requested format."
            }
            return nil

        case .toggle:
            // A toggle always holds a valid boolean; nothing to validate.
            return nil

        case .checkbox:
            let isOn = value?.bool ?? false
            return (field.isRequired && !isOn) ? requiredMessage(field) : nil

        case .dropdown(let options, _):
            guard field.isRequired else { return nil }
            if options.isEmpty {
                // §7 #3: required but no options to choose — surface the conflict
                // instead of letting an unsatisfiable field pass silently.
                return field.errorMessage ?? "No options are available, so this required field can't be completed."
            }
            let selection = value?.selection ?? []
            return selection.isEmpty ? requiredMessage(field) : nil

        case .unsupported:
            return nil
        }
    }

    private static func requiredMessage(_ field: FormField) -> String {
        field.errorMessage ?? "This field is required."
    }

    /// Whether `text` satisfies `pattern`. An invalid pattern in the JSON is
    /// treated as "no rule" (returns `true`) rather than crashing (§7 #11).
    /// - Complexity: O(L) to compile and match.
    private static func matches(_ pattern: String, _ text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return true
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }
}
