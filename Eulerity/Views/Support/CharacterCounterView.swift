//
//  CharacterCounterView.swift
//  Eulerity
//

import SwiftUI

/// A live `count / max` indicator shown beneath a text field that declares a
/// `max_length`. Turns the theme's error color once the limit is reached.
struct CharacterCounterView: View {
    let count: Int
    let max: Int
    let theme: ResolvedTheme

    var body: some View {
        Text("\(count)/\(max)")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(count >= max ? theme.error : theme.text.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
