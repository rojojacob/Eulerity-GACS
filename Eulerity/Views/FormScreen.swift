//
//  FormScreen.swift
//  Eulerity
//

import SwiftUI

/// The app's single screen. It renders the dynamic form described by the decoded
/// payload — themed background, an ordered list of field components, and a Save
/// button — and handles the load-failure / empty states.
///
/// Placeholder for now: field rendering, theming, validation, and the
/// `FormViewModel` wiring are built task-by-task per Plan.md (Phases C–E).
struct FormScreen: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Dynamic Form Builder")
                .font(.title.bold())
            Text("Skeleton ready — server-driven form rendering lands here (Plan.md Phase E).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    FormScreen()
}
