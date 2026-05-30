//
//  BillingAccountComponent.swift
//  Eulerity
//

import SwiftUI

/// Replaces the disabled "no options" dropdown for a billing account with a local
/// add-a-card flow (Plan.md F7): tapping the field opens a bottom sheet to enter
/// and save a card; saved cards are listed and selectable. The chosen card's id is
/// stored as the field's selection, so validation/submit treat it like any option.
struct BillingAccountComponent: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    let theme: ResolvedTheme

    @StateObject private var store = CardStore()
    @State private var showingSheet = false

    private var selectedCard: BillingCard? {
        guard let id = viewModel.values[field.id]?.selection?.first else { return nil }
        return store.cards.first { $0.id == id }
    }

    var body: some View {
        Button {
            showingSheet = true
        } label: {
            HStack {
                Text(selectedCard?.maskedNumber ?? (field.placeholder ?? "Add a billing account"))
                    .foregroundStyle(selectedCard == nil ? theme.placeholder : theme.text)
                Spacer()
                Image(systemName: "creditcard")
                    .foregroundStyle(theme.text.opacity(0.6))
            }
            .themedField(theme)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            BillingAccountSheet(
                store: store,
                selectedCardID: viewModel.values[field.id]?.selection?.first
            ) { cardID in
                viewModel.select(field.id, optionID: cardID)
            }
        }
    }
}

/// The bottom sheet: a list of saved cards (selectable) plus a form to add a new
/// one. System-styled so it reads as a standard iOS sheet.
struct BillingAccountSheet: View {
    @ObservedObject var store: CardStore
    let selectedCardID: String?
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var holderName = ""
    @State private var number = ""
    @State private var expiry = ""
    @State private var cvv = ""

    private var canAdd: Bool {
        !holderName.trimmingCharacters(in: .whitespaces).isEmpty
            && number.filter(\.isNumber).count >= 12
            && !expiry.trimmingCharacters(in: .whitespaces).isEmpty
            && cvv.filter(\.isNumber).count >= 3
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Saved cards") {
                    if store.cards.isEmpty {
                        Text("No cards added yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.cards) { card in
                            Button {
                                onSelect(card.id)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(card.holderName)
                                        Text(card.maskedNumber)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if card.id == selectedCardID {
                                        Image(systemName: "checkmark").foregroundStyle(.tint)
                                    }
                                }
                            }
                            .tint(.primary)
                        }
                    }
                }

                Section("Add a card") {
                    TextField("Full name", text: $holderName)
                        .textContentType(.name)
                    TextField("Card number", text: $number)
                        .keyboardType(.numberPad)
                    TextField("Exp date (MM/YY)", text: $expiry)
                    SecureField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                    Button("Add card", action: addCard)
                        .disabled(!canAdd)
                }
            }
            .navigationTitle("Billing Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addCard() {
        let card = BillingCard(
            id: UUID().uuidString,
            holderName: holderName,
            number: number,
            expiry: expiry,
            cvv: cvv
        )
        store.add(card)
        onSelect(card.id)
        holderName = ""
        number = ""
        expiry = ""
        cvv = ""
    }
}
