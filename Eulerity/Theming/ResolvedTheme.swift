//
//  ResolvedTheme.swift
//  Eulerity
//

import SwiftUI
import UIKit

/// The theme resolved into renderable SwiftUI colors. This is the ONLY theming
/// type that imports SwiftUI/UIKit (Constitution I — the thin presentation seam).
///
/// Each channel falls back to a safe, adaptive system color when the payload
/// omitted it or the hex could not be parsed (Constitution V), so the form is
/// always legible regardless of the theme block's quality.
nonisolated struct ResolvedTheme: Equatable, Sendable {
    var background: Color
    var text: Color
    var border: Color
    var error: Color

    /// Safe defaults, used when a payload has no theme or a channel can't be parsed.
    static let fallback = ResolvedTheme(
        background: Color(.systemBackground),
        text: Color(.label),
        border: Color(.separator),
        error: Color(.systemRed)
    )

    init(background: Color, text: Color, border: Color, error: Color) {
        self.background = background
        self.text = text
        self.border = border
        self.error = error
    }

    /// Resolves a raw ``ThemeModel`` (or `nil`) into colors, falling back
    /// per-channel on missing or invalid hex.
    ///
    /// - Complexity: O(1) — four constant-time channel parses.
    init(model: ThemeModel?) {
        self.init(
            background: Self.color(model?.backgroundColor, fallback: Self.fallback.background),
            text: Self.color(model?.textColor, fallback: Self.fallback.text),
            border: Self.color(model?.borderColor, fallback: Self.fallback.border),
            error: Self.color(model?.errorColor, fallback: Self.fallback.error)
        )
    }

    /// Resolves one hex channel to a `Color`, or returns `fallback`.
    /// - Complexity: O(1).
    private static func color(_ hex: String?, fallback: Color) -> Color {
        guard let hex, let rgba = HexColorParser.rgba(from: hex) else { return fallback }
        return Color(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }

    /// Brand accent (`#BB86FC`) used for active/affordance states: a valid Save
    /// button, a checked checkbox, an on toggle. Fixed across payload themes.
    var accent: Color { Color(.sRGB, red: 187.0 / 255.0, green: 134.0 / 255.0, blue: 252.0 / 255.0, opacity: 1) }

    /// Standard placeholder color — a faded version of the theme's text color, so
    /// placeholders read consistently on any background.
    var placeholder: Color { text.opacity(0.4) }
}
