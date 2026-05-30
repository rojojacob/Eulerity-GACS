//
//  FormLoader.swift
//  Eulerity
//

import Foundation

/// Loads and decodes the bundled form payload, returning a typed `Result` rather
/// than throwing — the view model maps a failure straight to a friendly error
/// state (Plan.md B3). Pure Foundation, SwiftUI-free.
nonisolated enum FormLoader {

    /// Loads `<resource>.json` from `bundle` and decodes it into a ``FormPayload``.
    ///
    /// - Complexity: O(n) in the size of the JSON file.
    static func load(
        resource: String = "form_payload",
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) -> Result<FormPayload, FormLoadError> {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            return .failure(.fileNotFound(resource: resource))
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return .failure(.unreadable(message: error.localizedDescription))
        }

        return decode(data, using: decoder)
    }

    /// Decodes already-loaded JSON `data` into a ``FormPayload``. Split out from
    /// ``load(resource:bundle:decoder:)`` so the decoding path is testable without
    /// a bundled fixture.
    ///
    /// - Complexity: O(n) in the size of `data`.
    static func decode(
        _ data: Data,
        using decoder: JSONDecoder = JSONDecoder()
    ) -> Result<FormPayload, FormLoadError> {
        do {
            return .success(try decoder.decode(FormPayload.self, from: data))
        } catch {
            return .failure(.decoding(message: error.localizedDescription))
        }
    }
}
