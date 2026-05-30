//
//  TextFieldComponent.swift
//  Eulerity
//

import SwiftUI

/// The input for a `TEXT` field. Routes the five subtypes to the right affordance
/// (keyboard type, masking, multiline) and shows a character counter only when
/// `max_length` is present (Plan.md E2).
///
/// Input is **hard-capped** at `max_length`: the field binds to local state, and
/// any over-limit edit is rewritten to the capped value, which forces the field to
/// drop the extra character instead of leaving it visible. (A plain view-model
/// binding can't revert the displayed text when the capped value equals the
/// previous one — the value stays correct but the keystroke lingers on screen.)
/// The view model is kept in sync so validation and submit see the capped value.
struct TextFieldComponent: View {
    let field: FormField
    let subtype: TextSubtype
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme
    @FocusState.Binding var focusedField: String?

    @State private var text: String

    init(
        field: FormField,
        subtype: TextSubtype,
        viewModel: FormViewModel,
        theme: ResolvedTheme,
        focusedField: FocusState<String?>.Binding
    ) {
        self.field = field
        self.subtype = subtype
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.theme = theme
        self._focusedField = focusedField
        self._text = State(initialValue: viewModel.values[field.id]?.text ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            input
                .focused($focusedField, equals: field.id)
                .themedField(theme)
            if let maxLength = field.maxLength {
                CharacterCounterView(count: text.count, max: maxLength, theme: theme)
            }
        }
        .onChange(of: text) { newValue in
            let capped = cap(newValue)
            if capped != newValue { text = capped }   // drop the over-limit character
            viewModel.updateText(field.id, to: capped)
        }
    }

    /// Truncates to `max_length` if present. - Complexity: O(L).
    private func cap(_ value: String) -> String {
        guard let maxLength = field.maxLength, value.count > maxLength else { return value }
        return String(value.prefix(maxLength))
    }

    @ViewBuilder private var input: some View {
        // Fall back to the field label when no placeholder is given (item 2), and
        // color every placeholder consistently from the theme (item 3).
        let prompt = Text(field.placeholder ?? field.label).foregroundColor(theme.placeholder)
        switch subtype {
        case .plain:
            TextField("", text: $text, prompt: prompt)
        case .multiline:
            TextField("", text: $text, prompt: prompt, axis: .vertical).lineLimit(3...6)
        case .number:
            TextField("", text: $text, prompt: prompt).keyboardType(.decimalPad)
        case .uri:
            TextField("", text: $text, prompt: prompt)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .secure:
            SecureField("", text: $text, prompt: prompt)
        }
    }
}
