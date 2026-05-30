//
//  FieldRowView.swift
//  Eulerity
//

import SwiftUI

/// Renders one field: its label (for text/dropdown), the control for its kind, and
/// any validation error. Routing on ``FormField/kind`` lives here so
/// ``FormContentView`` stays a simple list. Toggle and checkbox carry their own
/// inline label, so the top label is omitted for them.
struct FieldRowView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showsTopLabel {
                Text(field.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
            }

            control

            if let error = viewModel.errors[field.id] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(theme.error)
            }
        }
    }

    /// Toggle/checkbox render their label inline, so they skip the row's top label.
    private var showsTopLabel: Bool {
        switch field.kind {
        case .toggle, .checkbox: return false
        default: return true
        }
    }

    @ViewBuilder private var control: some View {
        switch field.kind {
        case .text(let subtype):
            TextFieldComponent(field: field, subtype: subtype, viewModel: viewModel, theme: theme)
        case .dropdown(let options, let allowMultiple):
            DropdownComponent(field: field, viewModel: viewModel, theme: theme,
                              options: options, allowMultiple: allowMultiple)
        case .toggle:
            ToggleComponent(field: field, viewModel: viewModel, theme: theme)
        case .checkbox:
            CheckboxComponent(field: field, viewModel: viewModel, theme: theme)
        case .unsupported:
            EmptyView()
        }
    }
}
