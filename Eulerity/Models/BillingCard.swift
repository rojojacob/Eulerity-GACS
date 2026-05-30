//
//  BillingCard.swift
//  Eulerity
//

import Foundation

/// A billing card the user added locally (Plan.md F7 flow).
///
/// - Note: persisting the full PAN and CVV in `UserDefaults` is **not** secure and
///   is done only to satisfy the exercise's "save locally" requirement. A real app
///   would tokenize via a payment SDK and never store the raw card number or CVV.
nonisolated struct BillingCard: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let holderName: String
    let number: String
    let expiry: String
    let cvv: String

    /// Last four digits of the (digits-only) card number. - Complexity: O(n).
    var last4: String { String(number.filter(\.isNumber).suffix(4)) }

    /// Display form, e.g. `•••• 4242`. - Complexity: O(n).
    var maskedNumber: String { "•••• " + last4 }
}
