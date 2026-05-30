//
//  LoaderTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("FormLoader")
struct LoaderTests {

    @Test("Loads the bundled payload successfully")
    func loadsBundledPayload() throws {
        let payload = try FormLoader.load(resource: "form_payload").get()
        #expect(payload.fields.count == 8)
    }

    @Test("A missing resource returns .fileNotFound")
    func missingResourceReturnsFileNotFound() {
        let result = FormLoader.load(resource: "does_not_exist_xyz")
        #expect(result == .failure(.fileNotFound(resource: "does_not_exist_xyz")))
    }

    @Test("Corrupt JSON returns .decoding")
    func corruptJSONReturnsDecodingError() {
        let result = FormLoader.decode(Data("{ this is not valid json".utf8))
        guard case .failure(.decoding) = result else {
            Issue.record("Expected a .decoding failure, got \(result)")
            return
        }
    }

    @Test("Valid JSON data decodes into a payload")
    func validDataDecodes() throws {
        let json = #"{"form_title":"X","fields":[{"id":"a","type":"TEXT","label":"A"}]}"#
        let payload = try FormLoader.decode(Data(json.utf8)).get()
        #expect(payload.formTitle == "X")
        #expect(payload.fields.count == 1)
    }
}
