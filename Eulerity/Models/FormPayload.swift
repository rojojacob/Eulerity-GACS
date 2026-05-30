//
//  FormPayload.swift
//  Eulerity
//

import Foundation

/// Decodes any `Decodable` element without throwing: a failure is captured as
/// `nil` so an enclosing array keeps decoding the remaining elements. This is how
/// a single malformed field is skipped without nuking the whole payload
/// (Constitution V).
private nonisolated struct Failable<Wrapped: Decodable>: Decodable {
    let value: Wrapped?
    nonisolated init(from decoder: any Decoder) throws {
        value = try? Wrapped(from: decoder)
    }
}

/// The top-level decoded form: title, optional theme, and the renderable fields.
///
/// `fields` contains only the fields that **decoded successfully AND are a
/// supported type** — malformed elements and unknown types are excluded from
/// render and counted in ``skippedFieldCount`` for
/// diagnostics. A missing/empty `fields` array yields an empty form (#6).
/// Ordering by `order` is applied later, in the view model (Plan.md C1).
///
/// Per-element resilience lives in ``Failable``; a corrupt *top-level* shape
/// (e.g. `fields` that isn't an array) throws and is handled by `FormLoader` (B3).
/// Pure and SwiftUI-free.
nonisolated struct FormPayload: Decodable, Equatable, Sendable {
    let formTitle: String
    let theme: ThemeModel?
    let fields: [FormField]
    let skippedFieldCount: Int

    enum CodingKeys: String, CodingKey {
        case formTitle = "form_title"
        case theme
        case fields
    }

    /// - Complexity: O(n) in the number of field elements.
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        formTitle = try container.decodeIfPresent(String.self, forKey: .formTitle) ?? ""
        theme = try container.decodeIfPresent(ThemeModel.self, forKey: .theme)

        let rawFields = try container.decodeIfPresent([Failable<FormField>].self, forKey: .fields) ?? []
        let decoded = rawFields.compactMap { $0.value }
        let renderable = decoded.filter { $0.type.isSupported }

        fields = renderable
        skippedFieldCount = rawFields.count - renderable.count
    }
}
