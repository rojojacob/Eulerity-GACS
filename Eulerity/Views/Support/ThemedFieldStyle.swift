//
//  ThemedFieldStyle.swift
//  Eulerity
//

import SwiftUI

/// Consistent visual treatment for input controls: padding, the theme's text and
/// accent (border) colors, and a rounded border — so the field components don't
/// each repeat styling.
struct ThemedFieldStyle: ViewModifier {
    let theme: ResolvedTheme

    func body(content: Content) -> some View {
        content
            .padding(12)
            .foregroundStyle(theme.text)
            .tint(theme.border)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(theme.border, lineWidth: 1)
            )
    }
}

extension View {
    /// Applies ``ThemedFieldStyle``. - Complexity: O(1).
    func themedField(_ theme: ResolvedTheme) -> some View {
        modifier(ThemedFieldStyle(theme: theme))
    }
}
