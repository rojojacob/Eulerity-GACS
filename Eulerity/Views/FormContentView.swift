//
//  FormContentView.swift
//  Eulerity
//

import SwiftUI

/// The themed form itself, shown once a payload has loaded. Owns the
/// ``FormViewModel`` and paints the JSON-defined ``ResolvedTheme``: a scrollable
/// title + ordered fields + Save button, plus the confirmation alert on submit.
struct FormContentView: View {
    @StateObject private var viewModel: FormViewModel
    private let theme: ResolvedTheme

    init(payload: FormPayload) {
        _viewModel = StateObject(wrappedValue: FormViewModel(payload: payload))
        theme = ResolvedTheme(model: payload.theme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(viewModel.formTitle)
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.text)

                ForEach(viewModel.orderedFields) { field in
                    FieldRowView(field: field, viewModel: viewModel, theme: theme)
                }

                Button(action: viewModel.validateAndSubmit) {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.border)
                .padding(.top, 8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.background.ignoresSafeArea())
        .alert(
            "Form submitted",
            isPresented: confirmationBinding,
            presenting: viewModel.confirmation
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { confirmation in
            Text(confirmation.json)
        }
    }

    /// Bridges the view model's `confirmation` to the alert's `isPresented`,
    /// clearing it when the alert is dismissed.
    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.confirmation != nil },
            set: { isShowing in if !isShowing { viewModel.dismissConfirmation() } }
        )
    }
}

#Preview {
    let previewJSON = #"""
    {"form_title":"Create Campaign",
     "theme":{"background_color":"#0B1221","text_color":"#FFFFFF","border_color":"#4F9DFF","error_color":"#FF5A5F"},
     "fields":[
       {"id":"name","type":"TEXT","label":"Campaign Name","subtype":"PLAIN","max_length":20},
       {"id":"net","type":"DROPDOWN","label":"Target Network","allow_multiple":true,"options":[{"id":"o1","label":"Meta"}]},
       {"id":"notify","type":"TOGGLE","label":"Enable Notifications"},
       {"id":"legal","type":"CHECKBOX","label":"Accept Terms"}
     ]}
    """#
    if let payload = try? JSONDecoder().decode(FormPayload.self, from: Data(previewJSON.utf8)) {
        FormContentView(payload: payload)
    } else {
        Text("Preview unavailable")
    }
}
