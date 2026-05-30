//
//  Theming.swift
//  Eulerity
//
//  Turns raw theme hex strings into presentation colors. Built during Phase A2
//  (Plan.md §6):
//    • HexColorParser — "#RGB" / "#RRGGBB" / "#RRGGBBAA" (with or without "#") →
//      (r,g,b,a); invalid input → nil so callers fall back to a safe default.
//      Pure, no SwiftUI. - Complexity: O(1) (fixed-length string).
//    • ResolvedTheme  — ThemeModel → SwiftUI `Color`s. This is the ONLY place in
//      the theming layer that imports SwiftUI (thin presentation extension).
//
//  Intentionally empty in the skeleton.
//
