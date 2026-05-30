//
//  DropdownComponent.swift
//  Eulerity
//

import SwiftUI

/// A `DROPDOWN` control. Tapping opens a sheet listing the options (with
/// checkmarks); selecting stores the option **id** via the view model's `select`
/// intent (single-select replaces and dismisses, multi-select toggles membership
/// and stays open). The collapsed field resolves the selected ids back to labels
/// via the field's O(1) label map.
///
/// A sheet is used instead of a `Menu` so presentation is reliable across iOS
/// versions and multi-select doesn't dismiss on every tap.
struct DropdownComponent: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme
    let options: [DropdownOption]
    let allowMultiple: Bool

    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Text(closedLabel)
                    .foregroundStyle(selection.isEmpty ? theme.placeholder : theme.text)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                    .foregroundStyle(theme.text.opacity(0.6))
            }
            .themedField(theme)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            DropdownPickerSheet(
                field: field,
                viewModel: viewModel,
                options: options,
                allowMultiple: allowMultiple
            )
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

/// The option picker presented as a sheet. Observes the view model so checkmarks
/// reflect the live selection while multi-selecting.
struct DropdownPickerSheet: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let options: [DropdownOption]
    let allowMultiple: Bool

    @Environment(\.dismiss) private var dismiss

    private var selection: [String] {
        viewModel.values[field.id]?.selection ?? []
    }

    var body: some View {
        NavigationStack {
            List(options) { option in
                Button {
                    viewModel.select(field.id, optionID: option.id)
                    if !allowMultiple { dismiss() }
                } label: {
                    HStack {
                        Text(option.label)
                        Spacer()
                        if selection.contains(option.id) {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
                .tint(.primary)
            }
            .navigationTitle(field.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
