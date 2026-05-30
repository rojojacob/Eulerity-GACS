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

    /// fieldId → current value. Mutation intents arrive in C2.
    @Published private(set) var values: [String: FieldValue]

    init(payload: FormPayload) {
        formTitle = payload.formTitle
        theme = payload.theme
        let ordered = Self.sorted(payload.fields)
        orderedFields = ordered
        values = Self.seedValues(for: ordered)
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
