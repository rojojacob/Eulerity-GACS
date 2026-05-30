//
//  DropdownComponent.swift
//  Eulerity
//

import SwiftUI

/// A `DROPDOWN` control. The menu shows option **labels**; selecting stores the
/// option **id** through the view model's `select` intent (single-select replaces,
/// multi-select toggles membership, with a checkmark on chosen rows). The closed
/// state resolves selected ids back to labels via the field's O(1) label map.
/// Empty options render a disabled hint rather than an unusable control (§7 #3).
struct DropdownComponent: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme
    let options: [DropdownOption]
    let allowMultiple: Bool

    var body: some View {
        if options.isEmpty {
            Text("No options available")
                .font(.footnote)
                .foregroundStyle(theme.text.opacity(0.55))
                .themedField(theme)
        } else {
            Menu {
                ForEach(options) { option in
                    Button {
                        viewModel.select(field.id, optionID: option.id)
                    } label: {
                        if selection.contains(option.id) {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Text(option.label)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(closedLabel)
                        .foregroundStyle(selection.isEmpty ? theme.text.opacity(0.5) : theme.text)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .foregroundStyle(theme.text.opacity(0.6))
                }
                .themedField(theme)
            }
        }
    }

    private var selection: [String] {
        viewModel.values[field.id]?.selection ?? []
    }

    /// The collapsed label: the selected options' labels, or the placeholder.
    /// - Complexity: O(s) over the current selection (each lookup is O(1)).
    private var closedLabel: String {
        let labels = selection.compactMap { field.optionLabel(for: $0) }
        return labels.isEmpty ? (field.placeholder ?? "Select…") : labels.joined(separator: ", ")
    }
}
