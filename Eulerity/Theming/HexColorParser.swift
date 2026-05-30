//
//  HexColorParser.swift
//  Eulerity
//

import Foundation

/// Parses CSS-style hex color strings into normalized RGBA components.
///
/// Supports `#RGB`, `#RRGGBB`, and `#RRGGBBAA`, with or without the leading `#`.
/// Any malformed input (wrong length, non-hex digits, empty) returns `nil` so the
/// caller can fall back to a safe default — never a crash (Constitution V).
/// Pure and SwiftUI-free.
nonisolated enum HexColorParser {

    /// Normalized color components, each in the range `0...1`.
    struct RGBA: Equatable, Sendable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double
    }

    /// Parses `hex` into an ``RGBA``, or returns `nil` if it is not a valid color.
    ///
    /// - Complexity: O(1) — the input is bounded (at most 8 hex digits).
    static func rgba(from hex: String) -> RGBA? {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }
        guard !string.isEmpty else { return nil }

        // Expand shorthand #RGB → #RRGGBB; accept 6 (RGB) or 8 (RGBA) directly.
        let normalized: String
        switch string.count {
        case 3: normalized = string.map { "\($0)\($0)" }.joined()
        case 6, 8: normalized = string
        default: return nil
        }

        guard let value = UInt32(normalized, radix: 16) else { return nil }

        if normalized.count == 8 {
            return RGBA(
                red: Double((value >> 24) & 0xFF) / 255,
                green: Double((value >> 16) & 0xFF) / 255,
                blue: Double((value >> 8) & 0xFF) / 255,
                alpha: Double(value & 0xFF) / 255
            )
        } else {
            return RGBA(
                red: Double((value >> 16) & 0xFF) / 255,
                green: Double((value >> 8) & 0xFF) / 255,
                blue: Double(value & 0xFF) / 255,
                alpha: 1
            )
        }
    }
}
