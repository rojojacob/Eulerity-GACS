//
//  FieldRowView.swift
//  Eulerity
//

import SwiftUI

/// Renders one field: its label, the control for its kind, and any validation
/// error. Routing on ``FormField/kind`` lives here so ``FormContentView`` stays a
/// simple list. Components land per Plan.md E2–E4; not-yet-built kinds show a
/// themed placeholder.
struct FieldRowView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)

            control

            if let error = viewModel.errors[field.id] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(theme.error)
            }
        }
    }

    @ViewBuilder private var control: some View {
        switch field.kind {
        case .text(let subtype):
            TextFieldComponent(field: field, subtype: subtype, viewModel: viewModel, theme: theme)
        case .dropdown(let options, let allowMultiple):
            DropdownComponent(field: field, viewModel: viewModel, theme: theme,
                              options: options, allowMultiple: allowMultiple)
        case .toggle, .checkbox, .unsupported:
            placeholderControl // replaced in E4
        }
    }

    private var placeholderControl: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(theme.border, lineWidth: 1)
            .frame(height: 44)
            .overlay(alignment: .leading) {
                Text(placeholderLabel)
                    .font(.footnote)
                    .foregroundStyle(theme.text.opacity(0.55))
                    .padding(.horizontal, 12)
            }
    }

    private var placeholderLabel: String {
        switch field.kind {
        case .dropdown(_, let allowMultiple): return allowMultiple ? "Dropdown · multi-select" : "Dropdown"
        case .toggle: return "Toggle"
        case .checkbox: return "Checkbox"
        default: return ""
        }
    }
}
