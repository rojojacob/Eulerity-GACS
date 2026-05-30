//
//  EulerityApp.swift
//  Eulerity
//
//  Composition root. The app is fully offline: its UI is driven entirely by a
//  JSON payload bundled in `Resources/`. No networking layer exists by design
//  (see Plan.md §1 and Constitution III).
//

import SwiftUI

@main
struct EulerityApp: App {
    var body: some Scene {
        WindowGroup {
            FormScreen()
        }
    }
}
