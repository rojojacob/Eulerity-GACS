//
//  ViewState.swift
//  Eulerity
//

import Foundation

/// The lifecycle of an asynchronously-loaded value, modeled as one finite-state
/// type. `FormScreen` switches over this to render the load / failure / empty
/// states without expressing impossible combinations.
nonisolated enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

extension ViewState {
    /// The successfully-loaded value, if present. - Complexity: O(1).
    nonisolated var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    /// Whether a load is in flight — drives progress indicators. - Complexity: O(1).
    nonisolated var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

extension ViewState: Equatable where Value: Equatable {}
extension ViewState: Sendable where Value: Sendable {}
