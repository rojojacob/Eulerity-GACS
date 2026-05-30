//
//  FormField.swift
//  Eulerity
//

import Foundation

/// The structured "shape" of a field, derived from its `type` plus the keys that
/// matter for that type. View models and views switch over this instead of
/// re-inspecting raw optionals (Plan.md B2: flat struct + computed `kind`).
nonisolated enum FieldKind: Equatable, Sendable {
    case text(subtype: TextSubtype)
    case dropdown(options: [DropdownOption], allowMultiple: Bool)
    case toggle
    case checkbox
    case unsupported
}

/// One decoded field. A deliberately **flat** struct: shared keys plus every
/// optional type-specific key, with a computed ``kind`` that exposes the relevant
/// subset per type. Decoding is defensive (Constitution V):
///
/// - `id`, `type`, `label` are required — a field lacking them is unusable, so it
///   throws and is skipped by ``FormPayload`` rather than corrupting the form.
/// - `type` never throws on an unknown token (it becomes `.unsupported`).
/// - Every other key is optional and tolerant of the wrong JSON type (it falls
///   back to `nil`/a default instead of dropping the whole field).
///
/// Pure and SwiftUI-free.
nonisolated struct FormField: Decodable, Equatable, Sendable, Identifiable {
    // Shared keys.
    let id: String
    let order: Int
    let type: FieldType
    let label: String
    let isRequired: Bool

    // Optional / type-specific keys.
    let subtype: TextSubtype?
    let placeholder: String?
    let maxLength: Int?
    let errorMessage: String?
    let options: [DropdownOption]?
    let allowMultiple: Bool
    let regex: String?
    let metadata: [String: String]?
    let clickableTextColor: String?

    // Defaults — `default_value` may be String or Bool; `default_values` is [String].
    let defaultString: String?
    let defaultBool: Bool?
    let defaultSelection: [String]?

    /// Pre-built `id → label` map for O(1) label resolution of the selected option(s).
    let optionLabelsByID: [String: String]

    enum CodingKeys: String, CodingKey {
        case id, order, type, label
        case isRequired = "required"
        case subtype, placeholder
        case maxLength = "max_length"
        case errorMessage = "error_message"
        case options
        case allowMultiple = "allow_multiple"
        case regex, metadata
        case clickableTextColor = "clickable_text_color"
        case defaultValue = "default_value"
        case defaultValues = "default_values"
    }

    /// - Complexity: O(m) in the number of dropdown options (to build the label
    ///   map); O(1) otherwise.
    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Required — throwing here makes the element skippable upstream.
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(FieldType.self, forKey: .type)
        label = try c.decode(String.self, forKey: .label)

        // Defensive shared keys (missing / wrong-type → safe default).
        order = (try? c.decode(Int.self, forKey: .order)) ?? .max
        isRequired = ((try? c.decode(Bool.self, forKey: .isRequired)) ?? false)
        allowMultiple = ((try? c.decode(Bool.self, forKey: .allowMultiple)) ?? false)

        // Optional keys (absent or wrong-type → nil, never a thrown field).
        subtype = (try? c.decodeIfPresent(TextSubtype.self, forKey: .subtype)) ?? nil
        placeholder = (try? c.decodeIfPresent(String.self, forKey: .placeholder)) ?? nil
        maxLength = (try? c.decodeIfPresent(Int.self, forKey: .maxLength)) ?? nil
        errorMessage = (try? c.decodeIfPresent(String.self, forKey: .errorMessage)) ?? nil
        regex = (try? c.decodeIfPresent(String.self, forKey: .regex)) ?? nil
        metadata = (try? c.decodeIfPresent([String: String].self, forKey: .metadata)) ?? nil
        clickableTextColor = (try? c.decodeIfPresent(String.self, forKey: .clickableTextColor)) ?? nil

        let decodedOptions = (try? c.decodeIfPresent([DropdownOption].self, forKey: .options)) ?? nil
        options = decodedOptions

        // Defaults: `default_value` is Bool | String | [String]; `default_values` wins for selection.
        var dBool: Bool?
        var dString: String?
        var dSelection: [String]?
        if let bool = (try? c.decodeIfPresent(Bool.self, forKey: .defaultValue)) ?? nil {
            dBool = bool
        } else if let string = (try? c.decodeIfPresent(String.self, forKey: .defaultValue)) ?? nil {
            dString = string
        } else if let array = (try? c.decodeIfPresent([String].self, forKey: .defaultValue)) ?? nil {
            dSelection = array
        }
        if let values = (try? c.decodeIfPresent([String].self, forKey: .defaultValues)) ?? nil {
            dSelection = values
        }
        defaultBool = dBool
        defaultString = dString
        defaultSelection = dSelection

        // Pre-build the option label map once; dedupe defensively (first id wins, no crash).
        optionLabelsByID = Dictionary(
            (decodedOptions ?? []).map { ($0.id, $0.label) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// The structured kind for this field, exposing only the keys its `type` uses.
    /// - Complexity: O(1).
    var kind: FieldKind {
        switch type {
        case .text: return .text(subtype: subtype ?? .plain)
        case .dropdown: return .dropdown(options: options ?? [], allowMultiple: allowMultiple)
        case .toggle: return .toggle
        case .checkbox: return .checkbox
        case .unsupported: return .unsupported
        }
    }

    /// The display label for a selected option `id`. - Complexity: O(1).
    func optionLabel(for optionID: String) -> String? {
        optionLabelsByID[optionID]
    }
}
