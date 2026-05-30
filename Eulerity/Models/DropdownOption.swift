//
//  DropdownOption.swift
//  Eulerity
//

import Foundation

/// A single selectable option in a `DROPDOWN`. The UI shows `label`; the stored
/// form state holds `id`. Pure, SwiftUI-free.
nonisolated struct DropdownOption: Decodable, Equatable, Sendable, Identifiable {
    let id: String
    let label: String
}
