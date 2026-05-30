//
//  ToggleComponent.swift
//  Eulerity
//

import SwiftUI

/// A `TOGGLE` field: a labeled switch honoring the seeded default. Flips through
/// the view model's `toggle` intent.
struct ToggleComponent: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme

    var body: some View {
        Toggle(isOn: binding) {
            Text(field.label).foregroundStyle(theme.text)
        }
        .tint(theme.accent)
    }

    private var binding: Binding<Bool> {
        Binding(
            get: { viewModel.values[field.id]?.bool ?? false },
            set: { _ in viewModel.toggle(field.id) }
        )
    }
}
