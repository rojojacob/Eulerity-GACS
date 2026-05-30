//
//  TextFieldComponent.swift
//  Eulerity
//

import SwiftUI

/// The input for a `TEXT` field. Routes the five subtypes to the right affordance
/// (keyboard type, masking, multiline) and shows a character counter only when
/// `max_length` is present (Plan.md E2). Binds through the view model's
/// `updateText` intent, which enforces `max_length` live.
struct TextFieldComponent: View {
    let field: FormField
    let subtype: TextSubtype
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme
    @FocusState.Binding var focusedField: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            input
                .focused($focusedField, equals: field.id)
                .themedField(theme)
            if let maxLength = field.maxLength {
                CharacterCounterView(count: currentText.count, max: maxLength, theme: theme)
            }
        }
    }

    @ViewBuilder private var input: some View {
        let prompt = field.placeholder ?? ""
        switch subtype {
        case .plain:
            TextField(prompt, text: textBinding)
        case .multiline:
            TextField(prompt, text: textBinding, axis: .vertical).lineLimit(3...6)
        case .number:
            TextField(prompt, text: textBinding).keyboardType(.decimalPad)
        case .uri:
            TextField(prompt, text: textBinding)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .secure:
            SecureField(prompt, text: textBinding)
        }
    }

    private var currentText: String { viewModel.values[field.id]?.text ?? "" }

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.values[field.id]?.text ?? "" },
            set: { viewModel.updateText(field.id, to: $0) }
        )
    }
}
