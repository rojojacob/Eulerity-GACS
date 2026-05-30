//
//  CardStore.swift
//  Eulerity
//

import Foundation
import Combine

/// Persists locally-added billing cards in `UserDefaults`, observable so the UI
/// updates when a card is added (Plan.md F7). Foundation + Combine only — no SwiftUI.
@MainActor
final class CardStore: ObservableObject {
    @Published private(set) var cards: [BillingCard] = []

    private let key = "eulerity.billing_cards"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    /// Adds a card and persists. - Complexity: O(n) to encode.
    func add(_ card: BillingCard) {
        cards.append(card)
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([BillingCard].self, from: data) else { return }
        cards = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(cards) else { return }
        defaults.set(data, forKey: key)
    }
}
