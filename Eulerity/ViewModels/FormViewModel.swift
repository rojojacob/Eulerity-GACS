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

    /// fieldId → field, for O(1) metadata lookup (`max_length`, `allow_multiple`)
    /// during updates — never a linear scan of `orderedFields` (Constitution IV).
    private let fieldsByID: [String: FormField]

    init(payload: FormPayload) {
        formTitle = payload.formTitle
        theme = payload.theme
        let ordered = Self.sorted(payload.fields)
        orderedFields = ordered
        fieldsByID = Dictionary(ordered.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
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
}
