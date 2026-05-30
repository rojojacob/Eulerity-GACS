//
//  EdgeCaseTests.swift
//  EulerityTests
//
//  Consolidated coverage of the Plan.md edge-case matrix (F4). Rows not already
//  exercised elsewhere are covered here, plus one hostile end-to-end payload.
//

import Testing
import Foundation
import SwiftUI
@testable import Eulerity

@Suite("Edge cases")
struct EdgeCaseTests {

    private func decodePayload(_ json: String) throws -> FormPayload {
        try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8))
    }

    private func decodeField(_ json: String) throws -> FormField {
        try JSONDecoder().decode(FormField.self, from: Data(json.utf8))
    }

    @Test("Garbage (non-integer) order falls back to Int.max (renders last)")
    func garbageOrderTreatedAsLast() throws {
        let field = try decodeField(#"{"id":"a","type":"TEXT","label":"A","order":"oops"}"#)
        #expect(field.order == .max)
    }

    @Test("Missing optional keys decode as nil / safe defaults")
    func missingOptionalKeysAreNil() throws {
        let field = try decodeField(#"{"id":"a","type":"TEXT","label":"A"}"#)
        #expect(field.placeholder == nil)
        #expect(field.maxLength == nil)
        #expect(field.errorMessage == nil)
        #expect(field.regex == nil)
        #expect(field.subtype == nil)
        #expect(field.options == nil)
        #expect(field.metadata == nil)
        #expect(field.allowMultiple == false)
        #expect(field.isRequired == false)
    }

    @Test("A hostile mixed payload decodes resiliently")
    func hostileMixedPayloadDecodes() throws {
        let payload = try decodePayload(#"""
        {
          "form_title": "All In One",
          "theme": {"background_color":"#GGGGGG","text_color":null,"border_color":"#FFF","error_color":"oops"},
          "fields": [
            {"id":"keep1","type":"TEXT","label":"Keep 1","order":2},
            {"id":"color","type":"COLOR_PICKER","label":"Unknown","order":1},
            {"type":"TEXT","label":"No ID"},
            {"id":"bill","type":"DROPDOWN","label":"Billing","required":true,"options":[]},
            {"id":"keep2","type":"TEXT","label":"Keep 2"}
          ]
        }
        """#)
        // COLOR_PICKER excluded (#2) + the id-less element skipped (#12) → 3 renderable.
        #expect(payload.fields.count == 3)
        #expect(payload.skippedFieldCount == 2)
        #expect(payload.fields.allSatisfy { $0.type.isSupported })
        // The empty-options required dropdown still decodes (#3 is a validation concern).
        #expect(payload.fields.contains { $0.id == "bill" })
        #expect(payload.formTitle == "All In One")
    }

    @Test("A theme with all-invalid hex resolves entirely to the fallback")
    func invalidThemeResolvesToFallback() throws {
        let payload = try decodePayload(#"""
        {"theme":{"background_color":"nope","text_color":"###","border_color":"","error_color":"zzz"},"fields":[]}
        """#)
        #expect(ResolvedTheme(model: payload.theme) == .fallback)
    }

    @Test("A payload with no fields key yields an empty, titled form")
    func missingFieldsYieldsEmptyTitledForm() throws {
        let payload = try decodePayload(#"{"form_title":"Just a title"}"#)
        #expect(payload.fields.isEmpty)
        #expect(payload.skippedFieldCount == 0)
        #expect(payload.formTitle == "Just a title")
    }
}
