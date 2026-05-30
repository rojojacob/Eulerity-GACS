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
