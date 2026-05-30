//
//  CharacterCounterView.swift
//  Eulerity
//

import SwiftUI

/// A live `count / max` indicator shown beneath a text field that declares a
/// `max_length`. Reaching the limit is a valid state (input is capped, never
/// exceeded), so the counter stays neutral — it is not an error and isn't colored
/// red at `count == max`.
struct CharacterCounterView: View {
    let count: Int
    let max: Int
    let theme: ResolvedTheme

    var body: some View {
        Text("\(count)/\(max)")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(theme.text.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
