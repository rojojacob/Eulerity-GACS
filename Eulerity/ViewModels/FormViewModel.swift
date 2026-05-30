//
//  FormViewModel.swift
//  Eulerity
//

import Foundation
import Combine

/// Owns the form's UI-facing state: the fields in render order and the live value
/// of each, seeded from the payload's defaults.
///
/// `@MainActor` (Constitution I) — it holds `@Published` state the views observe.
/// It imports no SwiftUI: the raw ``ThemeModel`` is exposed for the view to resolve
/// into colors, keeping presentation types out of the view model.
@MainActor
final class FormViewModel: ObservableObject {
    let formTitle: String
    let theme: ThemeModel?
    let orderedFields: [FormField]

    /// fieldId → current value. Mutated only through the intent methods below.
    @Published private(set) var values: [String: FieldValue]

    /// fieldId → validation error message, populated on Save. Empty == valid.
    @Published private(set) var errors: [String: String] = [:]

    /// Set when a valid form is submitted; drives the confirmation alert.
    @Published private(set) var confirmation: Confirmation?

    /// fieldId → field, for O(1) metadata lookup (`max_length`, `allow_multiple`)
    /// during updates — never a linear scan of `orderedFields` (Constitution IV).
    private let fieldsByID: [String: FormField]

    /// fieldId → compiled regex, built once so validation never recompiles a pattern
    /// on each Save (Plan.md F2). Invalid patterns are omitted (treated as no rule, §7 #11).
    private let compiledRegexes: [String: NSRegularExpression]

    /// The result of a successful submit: the typed payload and its pretty JSON.
    struct Confirmation: Equatable {
        let payload: [String: SubmitValue]
        let json: String
    }

    init(payload: FormPayload) {
        formTitle = payload.formTitle
        theme = payload.theme
        let ordered = Self.sorted(payload.fields)
        orderedFields = ordered
        fieldsByID = Dictionary(ordered.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        compiledRegexes = Self.compileRegexes(ordered)
        values = Self.seedValues(for: ordered)
    }

    // MARK: - Update intents

    /// Sets a text field's value, enforcing `max_length` live by truncating the
    /// prefix (Plan.md C2 / §7 #13). Unknown ids are ignored.
    /// - Complexity: O(L) in the new text length; the store is O(1).
    func updateText(_ id: String, to newValue: String) {
        guard let field = fieldsByID[id] else { return }
        var text = newValue
        if let maxLength = field.maxLength, text.count > maxLength {
            text = String(text.prefix(maxLength))
        }
        values[id] = .text(text)
    }

    /// Flips a toggle/checkbox value. - Complexity: O(1).
    func toggle(_ id: String) {
        let current = values[id]?.bool ?? false
        values[id] = .bool(!current)
    }

    /// Applies a dropdown selection: single-select replaces the value; multi-select
    /// toggles the option's membership (Plan.md C2). Unknown ids are ignored.
    /// - Complexity: O(s) in the current selection count (membership toggle).
    func select(_ id: String, optionID: String) {
        guard let field = fieldsByID[id] else { return }
        if field.allowMultiple {
            var current = values[id]?.selection ?? []
            if let index = current.firstIndex(of: optionID) {
                current.remove(at: index)
            } else {
                current.append(optionID)
            }
            values[id] = .selection(current)
        } else {
            values[id] = .selection([optionID])
        }
    }

    // MARK: - Submit

    /// Validates the form; on success builds and prints the submit payload and sets
    /// ``confirmation``. On failure, populates ``errors`` and submits nothing
    /// (Plan.md D2).
    func validateAndSubmit() {
        errors = Validator.validate(fields: orderedFields, values: values, regexes: compiledRegexes)
        guard errors.isEmpty else {
            confirmation = nil
            return
        }
        let payload = submissionPayload()
        let json = Self.prettyJSON(payload)
        print(json)
        confirmation = Confirmation(payload: payload, json: json)
    }

    /// Clears the confirmation (e.g. when the alert is dismissed).
    func dismissConfirmation() {
        confirmation = nil
    }

    /// The values to submit, keyed by field id. Empty text and empty selections are
    /// omitted; a single-select emits a scalar id, a multi-select an array, and a
    /// toggle/checkbox its bool — preserving scalars vs arrays (Plan.md D2).
    /// - Complexity: O(n) over fields.
    func submissionPayload() -> [String: SubmitValue] {
        var payload: [String: SubmitValue] = [:]
        for field in orderedFields {
            guard let value = values[field.id],
                  let submit = Self.submitValue(for: field, value: value) else { continue }
            payload[field.id] = submit
        }
        return payload
    }

    private static func submitValue(for field: FormField, value: FieldValue) -> SubmitValue? {
        switch field.kind {
        case .text:
            guard let text = value.text, !text.isEmpty else { return nil }
            return .string(text)
        case .toggle, .checkbox:
            return .bool(value.bool ?? false)
        case .dropdown(_, let allowMultiple):
            let selection = value.selection ?? []
            guard !selection.isEmpty else { return nil }
            return allowMultiple ? .strings(selection) : .string(selection[0])
        case .unsupported:
            return nil
        }
    }

    private static func prettyJSON(_ payload: [String: SubmitValue]) -> String {
        let object = payload.mapValues { $0.jsonValue }
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    // MARK: - Ordering

    /// Sorts by the `order` integer with an explicit, stable tie-break on the
    /// decode index, so we never depend on `sorted(by:)` being stable and equal
    /// orders keep their payload sequence (Plan.md §7 #7). Missing `order` already
    /// decoded to `Int.max`, so those render last.
    ///
    /// - Complexity: O(n log n).
    private static func sorted(_ fields: [FormField]) -> [FormField] {
        fields.enumerated()
            .sorted { lhs, rhs in
                lhs.element.order != rhs.element.order
                    ? lhs.element.order < rhs.element.order
                    : lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    // MARK: - Default seeding

    /// Builds the initial value for every field. - Complexity: O(n) over fields
    /// (each field's seed is O(1), except a dropdown's option-id `Set` which is
    /// O(m) in its own options).
    private static func seedValues(for fields: [FormField]) -> [String: FieldValue] {
        var values: [String: FieldValue] = [:]
        values.reserveCapacity(fields.count)
        for field in fields {
            values[field.id] = initialValue(for: field)
        }
        return values
    }

    /// The seeded value for one field, honoring its default and the §7 decisions:
    /// text default truncated to `max_length` (#1); dropdown defaults filtered to
    /// ids that actually exist in the options (#9).
    private static func initialValue(for field: FormField) -> FieldValue {
        switch field.kind {
        case .text:
            var text = field.defaultString ?? ""
            if let maxLength = field.maxLength, text.count > maxLength {
                text = String(text.prefix(maxLength))
            }
            return .text(text)

        case .toggle, .checkbox:
            return .bool(field.defaultBool ?? false)

        case .dropdown(let options, _):
            let validIDs = Set(options.map(\.id))                 // O(m) build, O(1) membership
            let requested = field.defaultSelection ?? field.defaultString.map { [$0] } ?? []
            return .selection(requested.filter { validIDs.contains($0) })

        case .unsupported:
            // Unreachable for renderable fields (FormPayload excludes unsupported),
            // but the switch must be total.
            return .text("")
        }
    }

    /// Compiles each field's `regex` once; invalid patterns are dropped (treated as
    /// no rule). - Complexity: O(n) over fields; each compile is O(pattern length).
    private static func compileRegexes(_ fields: [FormField]) -> [String: NSRegularExpression] {
        var result: [String: NSRegularExpression] = [:]
        for field in fields {
            guard let pattern = field.regex,
                  let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            result[field.id] = regex
        }
        return result
    }
}
