//
//  LoadableViewModel.swift
//  Eulerity
//

import Foundation

/// Shared shape for view models that asynchronously load a single value and
/// publish it as a ``ViewState``. Conformers expose a `state` the views switch
/// over (see ``StateView``), so every screen handles loading, success, and
/// failure the same way.
///
/// View models are `@MainActor`: they own UI-facing state and mutate it on the
/// main actor. Conform with `ObservableObject` and mark `state` `@Published`.
@MainActor
protocol LoadableViewModel: ObservableObject {
    associatedtype Value
    var state: ViewState<Value> { get }
    /// Triggers the load. Implementations assign `.loading`, then `.loaded`/`.failed`.
    func load() async
}
