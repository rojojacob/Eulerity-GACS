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
                theme: theme,
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
    let theme: ResolvedTheme
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
                Section {
                    if store.cards.isEmpty {
                        Text("No cards added yet.")
                            .foregroundStyle(theme.placeholder)
                            .listRowBackground(theme.surface)
                    } else {
                        ForEach(store.cards) { card in
                            Button {
                                onSelect(card.id)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(card.holderName).foregroundStyle(theme.text)
                                        Text(card.maskedNumber)
                                            .font(.caption)
                                            .foregroundStyle(theme.placeholder)
                                    }
                                    Spacer()
                                    if card.id == selectedCardID {
                                        Image(systemName: "checkmark").foregroundStyle(theme.accent)
                                    }
                                }
                            }
                            .listRowBackground(theme.surface)
                        }
                    }
                } header: {
                    Text("Saved cards").foregroundStyle(theme.text.opacity(0.6))
                }

                Section {
                    TextField("", text: $holderName, prompt: Text("Full name").foregroundColor(theme.placeholder))
                        .foregroundStyle(theme.text)
                        .textContentType(.name)
                        .listRowBackground(theme.surface)
                    TextField("", text: $number, prompt: Text("Card number").foregroundColor(theme.placeholder))
                        .foregroundStyle(theme.text)
                        .keyboardType(.numberPad)
                        .listRowBackground(theme.surface)
                    TextField("", text: $expiry, prompt: Text("Exp date (MM/YY)").foregroundColor(theme.placeholder))
                        .foregroundStyle(theme.text)
                        .listRowBackground(theme.surface)
                    SecureField("", text: $cvv, prompt: Text("CVV").foregroundColor(theme.placeholder))
                        .foregroundStyle(theme.text)
                        .keyboardType(.numberPad)
                        .listRowBackground(theme.surface)
                    Button("Add card", action: addCard)
                        .disabled(!canAdd)
                        .listRowBackground(theme.surface)
                } header: {
                    Text("Add a card").foregroundStyle(theme.text.opacity(0.6))
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Billing Account").font(.headline).foregroundStyle(theme.text)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .tint(theme.accent)
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
