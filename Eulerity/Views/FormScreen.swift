//
//  FormScreen.swift
//  Eulerity
//

import SwiftUI

/// The app's single screen. Loads the bundled payload through ``FormLoader`` and
/// renders one of three states via ``StateView``: a brief loading indicator, the
/// themed form (``FormContentView``) on success, or a friendly message on a load
/// failure (Plan.md E1, B3).
struct FormScreen: View {
    @State private var loadState: ViewState<FormPayload> = .idle

    var body: some View {
        StateView(loadState) { payload in
            FormContentView(payload: payload)
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func loadIfNeeded() {
        guard case .idle = loadState else { return }
        switch FormLoader.load() {
        case .success(let payload):
            loadState = .loaded(payload)
        case .failure(let error):
            loadState = .failed(error.errorDescription ?? "The form couldn't be loaded.")
        }
    }
}

#Preview {
    FormScreen()
}
