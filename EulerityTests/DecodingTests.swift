//
//  DecodingTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("FieldType")
struct FieldTypeTests {

    /// Decodes a single token via an array wrapper (robust across Foundation
    /// versions that reject top-level JSON fragments).
    private func decode(_ token: String) throws -> FieldType {
        try JSONDecoder().decode([FieldType].self, from: Data("[\"\(token)\"]".utf8))[0]
    }

    @Test("Known tokens map to their cases")
    func knownTypes() throws {
        #expect(try decode("TEXT") == .text)
        #expect(try decode("DROPDOWN") == .dropdown)
        #expect(try decode("TOGGLE") == .toggle)
        #expect(try decode("CHECKBOX") == .checkbox)
    }

    @Test("Unknown type decodes to .unsupported, preserving the raw token")
    func unknownTypeMapsToUnsupported() throws {
        #expect(try decode("COLOR_PICKER") == .unsupported(rawValue: "COLOR_PICKER"))
        #expect(try decode("DATE_PICKER") == .unsupported(rawValue: "DATE_PICKER"))
    }

    @Test("Matching is exact and case-sensitive")
    func caseSensitive() throws {
        #expect(try decode("text") == .unsupported(rawValue: "text"))
    }

    @Test("isSupported reflects whether the type is renderable")
    func isSupportedFlag() {
        #expect(FieldType.text.isSupported)
        #expect(!FieldType.unsupported(rawValue: "COLOR_PICKER").isSupported)
    }
}

@Suite("TextSubtype")
struct TextSubtypeTests {

    private func decode(_ token: String) throws -> TextSubtype {
        try JSONDecoder().decode([TextSubtype].self, from: Data("[\"\(token)\"]".utf8))[0]
    }

    @Test("Known subtypes map to their cases")
    func knownSubtypes() throws {
        #expect(try decode("PLAIN") == .plain)
        #expect(try decode("MULTILINE") == .multiline)
        #expect(try decode("NUMBER") == .number)
        #expect(try decode("URI") == .uri)
        #expect(try decode("SECURE") == .secure)
    }

    @Test("Unknown subtype defaults to .plain")
    func unknownSubtypeDefaultsToPlain() throws {
        #expect(try decode("RICHTEXT") == .plain)
        #expect(try decode("plain") == .plain)
    }
}

@Suite("FormField")
struct FormFieldTests {

    private func decodeField(_ json: String) throws -> FormField {
        try JSONDecoder().decode(FormField.self, from: Data(json.utf8))
    }

    @Test("Computes the .text kind with its subtype")
    func textKind() throws {
        let field = try decodeField(#"{"id":"a","type":"TEXT","label":"A","subtype":"NUMBER"}"#)
        #expect(field.kind == .text(subtype: .number))
    }

    @Test("Computes the .dropdown kind with options and allow_multiple")
    func dropdownKind() throws {
        let field = try decodeField(#"""
        {"id":"b","type":"DROPDOWN","label":"B","allow_multiple":true,
         "options":[{"id":"o1","label":"One"},{"id":"o2","label":"Two"}]}
        """#)
        #expect(field.kind == .dropdown(
            options: [DropdownOption(id: "o1", label: "One"), DropdownOption(id: "o2", label: "Two")],
            allowMultiple: true
        ))
    }

    @Test("Resolves option labels by id in O(1)")
    func optionLabelLookup() throws {
        let field = try decodeField(#"{"id":"b","type":"DROPDOWN","label":"B","options":[{"id":"o1","label":"One"}]}"#)
        #expect(field.optionLabel(for: "o1") == "One")
        #expect(field.optionLabel(for: "missing") == nil)
    }

    @Test("Duplicate option ids do not crash; first label wins")
    func duplicateOptionIDs() throws {
        let field = try decodeField(#"{"id":"b","type":"DROPDOWN","label":"B","options":[{"id":"o1","label":"One"},{"id":"o1","label":"Two"}]}"#)
        #expect(field.optionLabel(for: "o1") == "One")
    }

    @Test("Captures default_value as a string, bool, or selection by shape")
    func defaultValueShapes() throws {
        let text = try decodeField(#"{"id":"a","type":"TEXT","label":"A","default_value":"hi"}"#)
        #expect(text.defaultString == "hi")
        #expect(text.defaultBool == nil)

        let toggle = try decodeField(#"{"id":"t","type":"TOGGLE","label":"T","default_value":true}"#)
        #expect(toggle.defaultBool == true)

        let dropdown = try decodeField(#"{"id":"d","type":"DROPDOWN","label":"D","options":[{"id":"o1","label":"One"}],"default_values":["o1"]}"#)
        #expect(dropdown.defaultSelection == ["o1"])
    }

    @Test("Missing order falls back to Int.max (renders last)")
    func missingOrderFallsBackToMax() throws {
        let field = try decodeField(#"{"id":"a","type":"TEXT","label":"A"}"#)
        #expect(field.order == .max)
        #expect(field.isRequired == false)
    }
}

@Suite("FormPayload")
struct FormPayloadTests {

    private func decodePayload(_ json: String) throws -> FormPayload {
        try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8))
    }

    @Test("Decodes the four known field types")
    func decodesKnownFields() throws {
        let payload = try decodePayload(#"""
        {"form_title":"T","fields":[
          {"id":"a","type":"TEXT","label":"A","order":1},
          {"id":"b","type":"DROPDOWN","label":"B","order":2,"options":[{"id":"o1","label":"One"}]},
          {"id":"c","type":"TOGGLE","label":"C","order":3,"default_value":true},
          {"id":"d","type":"CHECKBOX","label":"D","order":4,"required":true}
        ]}
        """#)
        #expect(payload.fields.count == 4)
        #expect(payload.skippedFieldCount == 0)
        #expect(payload.formTitle == "T")
    }

    @Test("Unknown type is excluded from render and counted as skipped")
    func unknownTypeExcluded() throws {
        let payload = try decodePayload(#"""
        {"fields":[
          {"id":"a","type":"TEXT","label":"A"},
          {"id":"x","type":"COLOR_PICKER","label":"X"}
        ]}
        """#)
        #expect(payload.fields.count == 1)
        #expect(payload.skippedFieldCount == 1)
        #expect(payload.fields.allSatisfy { $0.type.isSupported })
    }

    @Test("Empty options array decodes fine")
    func emptyOptionsArrayDecodes() throws {
        let payload = try decodePayload(#"{"fields":[{"id":"b","type":"DROPDOWN","label":"B","required":true,"options":[]}]}"#)
        #expect(payload.fields.count == 1)
        #expect(payload.fields[0].options == [])
    }

    @Test("A single malformed field is skipped; the others survive")
    func malformedSingleFieldIsSkipped() throws {
        // Second element is missing the required `id`.
        let payload = try decodePayload(#"""
        {"fields":[
          {"id":"a","type":"TEXT","label":"A"},
          {"type":"TEXT","label":"no id"}
        ]}
        """#)
        #expect(payload.fields.count == 1)
        #expect(payload.fields[0].id == "a")
        #expect(payload.skippedFieldCount == 1)
    }

    @Test("Missing fields array yields an empty form with its title")
    func missingFieldsArrayYieldsEmptyForm() throws {
        let payload = try decodePayload(#"{"form_title":"Empty"}"#)
        #expect(payload.fields.isEmpty)
        #expect(payload.formTitle == "Empty")
    }

    @Test("The bundled sample payload decodes; COLOR_PICKER is excluded")
    func bundledPayloadDecodes() throws {
        let url = try #require(Bundle.main.url(forResource: "form_payload", withExtension: "json"))
        let payload = try JSONDecoder().decode(FormPayload.self, from: Data(contentsOf: url))
        #expect(payload.fields.count == 6)
        #expect(payload.skippedFieldCount == 1)
        #expect(payload.fields.contains { $0.id == "campaign_name" })
        #expect(payload.fields.allSatisfy { $0.type.isSupported })
    }
}
