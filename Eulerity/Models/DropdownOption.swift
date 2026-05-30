//
//  DropdownOption.swift
//  Eulerity
//

import Foundation

/// A single selectable option in a `DROPDOWN`. The UI shows `label`; the stored
/// form state holds `id` (Plan.md §2). Pure, SwiftUI-free.
nonisolated struct DropdownOption: Decodable, Equatable, Sendable, Identifiable {
    let id: String
    let label: String
}
