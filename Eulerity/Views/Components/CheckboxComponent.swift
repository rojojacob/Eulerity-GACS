//
//  CheckboxComponent.swift
//  Eulerity
//

import SwiftUI

/// A `CHECKBOX` field: a tappable box plus its label, honoring `required`. Toggles
/// through the view model's `toggle` intent. (Rich-text clickable links in the
/// label arrive in Plan.md F1.)
struct CheckboxComponent: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme

    private var isOn: Bool { viewModel.values[field.id]?.bool ?? false }

    var body: some View {
        Button {
            viewModel.toggle(field.id)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? theme.border : theme.text.opacity(0.6))
                Text(field.label)
                    .foregroundStyle(theme.text)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}
