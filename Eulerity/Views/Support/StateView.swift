//
//  StateView.swift
//  Eulerity
//

import SwiftUI

/// Renders any ``ViewState``, centralizing how the screen shows loading, empty,
/// and load-failure conditions. Callers supply only the success content via
/// `content`; the non-success branches look consistent everywhere.
struct StateView<Value, Content: View>: View {
    private let state: ViewState<Value>
    private let onRetry: (() -> Void)?
    private let content: (Value) -> Content

    init(
        _ state: ViewState<Value>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
    }

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
        case let .loaded(value):
            content(value)
        case let .failed(message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let onRetry {
                    Button("Retry", action: onRetry)
                        .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
}
