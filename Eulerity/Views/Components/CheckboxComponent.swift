//
//  CheckboxComponent.swift
//  Eulerity
//

import SwiftUI

/// A `CHECKBOX` field: a tappable box plus its label, honoring `required`.
///
/// When the label contains rich-text links (`metadata` keys matched in the label),
/// the box and the label are *separate* tap targets — the box toggles, the links
/// open in Safari — so taps don't collide (Plan.md F1). Links are tinted with
/// `clickable_text_color`, falling back to the theme accent.
struct CheckboxComponent: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Button(action: { viewModel.toggle(field.id) }) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? theme.accent : theme.text.opacity(0.6))
            }
            .buttonStyle(.plain)

            label
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private var label: some View {
        if hasLinks {
            Text(richLabel)
                .foregroundStyle(theme.text)
                .tint(clickableColor)
                .multilineTextAlignment(.leading)
        } else {
            // No links: the whole label is a convenient toggle target.
            Button(action: { viewModel.toggle(field.id) }) {
                Text(field.label)
                    .foregroundStyle(theme.text)
                    .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
        }
    }

    private var isOn: Bool { viewModel.values[field.id]?.bool ?? false }

    private var richLabel: AttributedString {
        RichTextLabel.make(label: field.label, metadata: field.metadata)
    }

    private var hasLinks: Bool {
        richLabel.runs.contains { $0.link != nil }
    }

    private var clickableColor: Color {
        if let hex = field.clickableTextColor, let rgba = HexColorParser.rgba(from: hex) {
            return Color(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
        }
        return theme.border
    }
}
