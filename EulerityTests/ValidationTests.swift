//
//  ValidationTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("Validator")
struct ValidationTests {

    private func field(_ json: String) throws -> FormField {
        try JSONDecoder().decode(FormField.self, from: Data(json.utf8))
    }

    @Test("Required empty field reports its error_message")
    func requiredMissing() throws {
        let f = try field(#"{"id":"name","type":"TEXT","label":"N","required":true,"error_message":"Name required"}"#)
        let errors = Validator.validate(fields: [f], values: ["name": .text("")])
        #expect(errors["name"] == "Name required")
    }

    @Test("Required field with a value is valid")
    func requiredPresent() throws {
        let f = try field(#"{"id":"name","type":"TEXT","label":"N","required":true}"#)
        #expect(Validator.validate(fields: [f], values: ["name": .text("Bob")]).isEmpty)
    }

    @Test("A matching regex value passes")
    func regexPass() throws {
        let f = try field(#"{"id":"code","type":"TEXT","label":"C","regex":"^[A-Z0-9]{4,10}$"}"#)
        #expect(Validator.validate(fields: [f], values: ["code": .text("SAVE20")]).isEmpty)
    }

    @Test("A non-matching regex value fails")
    func regexFail() throws {
        let f = try field(#"{"id":"code","type":"TEXT","label":"C","regex":"^[A-Z0-9]{4,10}$"}"#)
        #expect(Validator.validate(fields: [f], values: ["code": .text("lower")])["code"] != nil)
    }

    @Test("An invalid regex pattern in the JSON is ignored, never crashes")
    func invalidRegexIgnored() throws {
        let f = try field(#"{"id":"code","type":"TEXT","label":"C","regex":"[unclosed"}"#)
        #expect(Validator.validate(fields: [f], values: ["code": .text("anything")]).isEmpty)
    }

    @Test("A non-required empty text field with a regex is still valid")
    func optionalEmptyWithRegexIsValid() throws {
        let f = try field(#"{"id":"code","type":"TEXT","label":"C","regex":"^[A-Z]+$"}"#)
        #expect(Validator.validate(fields: [f], values: ["code": .text("")]).isEmpty)
    }

    @Test("Multi-select required with an empty selection fails")
    func multiSelectRequiredEmpty() throws {
        let f = try field(#"""
        {"id":"net","type":"DROPDOWN","label":"D","required":true,"allow_multiple":true,
         "options":[{"id":"o1","label":"One"}]}
        """#)
        #expect(Validator.validate(fields: [f], values: ["net": .selection([])])["net"] != nil)
        #expect(Validator.validate(fields: [f], values: ["net": .selection(["o1"])]).isEmpty)
    }

    @Test("Required dropdown with empty options surfaces the conflict")
    func emptyOptionsRequiredDropdown() throws {
        let f = try field(#"{"id":"bill","type":"DROPDOWN","label":"B","required":true,"options":[]}"#)
        #expect(Validator.validate(fields: [f], values: ["bill": .selection([])])["bill"] != nil)
    }

    @Test("Required checkbox must be checked")
    func requiredCheckbox() throws {
        let f = try field(#"{"id":"legal","type":"CHECKBOX","label":"L","required":true}"#)
        #expect(Validator.validate(fields: [f], values: ["legal": .bool(false)])["legal"] != nil)
        #expect(Validator.validate(fields: [f], values: ["legal": .bool(true)]).isEmpty)
    }

    @Test("A fully valid form yields no errors")
    func validForm() throws {
        let name = try field(#"{"id":"name","type":"TEXT","label":"N","required":true}"#)
        let legal = try field(#"{"id":"legal","type":"CHECKBOX","label":"L","required":true}"#)
        let errors = Validator.validate(
            fields: [name, legal],
            values: ["name": .text("Bob"), "legal": .bool(true)]
        )
        #expect(errors.isEmpty)
    }
}
