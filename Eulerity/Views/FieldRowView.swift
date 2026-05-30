//
//  FieldRowView.swift
//  Eulerity
//

import SwiftUI

/// Renders one field: its label, the control for its kind, and any validation
/// error. Routing on ``FormField/kind`` lives here so ``FormContentView`` stays
/// a simple list.
///
/// In E1 the control is a themed placeholder; E2–E4 (Plan.md) replace each branch
/// with the real component (text field, dropdown, toggle, checkbox).
struct FieldRowView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)

            placeholderControl

            if let error = viewModel.errors[field.id] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(theme.error)
            }
        }
    }

    // MARK: - E1 placeholder control (replaced in E2–E4)

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
        case .text(let subtype): return "Text field · \(subtype.rawValue.capitalized)"
        case .dropdown(_, let allowMultiple): return allowMultiple ? "Dropdown · multi-select" : "Dropdown"
        case .toggle: return "Toggle"
        case .checkbox: return "Checkbox"
        case .unsupported: return "Unsupported"
        }
    }
}
