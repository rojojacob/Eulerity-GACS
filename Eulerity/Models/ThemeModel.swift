//
//  ThemeModel.swift
//  Eulerity
//

import Foundation

/// The `theme` block exactly as it appears in the JSON payload — raw hex strings,
/// no interpretation. Turning these into renderable colors is the job of
/// ``ResolvedTheme`` (the presentation layer), keeping this type pure and
/// SwiftUI-free (Constitution I).
///
/// Every channel is optional: a payload may omit `theme` entirely or any single
/// channel, and that must degrade gracefully rather than fail to decode
/// (Constitution V).
nonisolated struct ThemeModel: Decodable, Equatable, Sendable {
    var backgroundColor: String?
    var textColor: String?
    var borderColor: String?
    var errorColor: String?

    enum CodingKeys: String, CodingKey {
        case backgroundColor = "background_color"
        case textColor = "text_color"
        case borderColor = "border_color"
        case errorColor = "error_color"
    }
}
