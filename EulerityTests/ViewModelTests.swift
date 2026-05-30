//
//  ViewModelTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("FormViewModel state")
@MainActor
struct ViewModelTests {

    private func viewModel(_ json: String) throws -> FormViewModel {
        FormViewModel(payload: try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8)))
    }

    @Test("Seeds text, bool, and selection defaults")
    func defaultsSeeded() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"name","type":"TEXT","label":"N","default_value":"Bob"},
          {"id":"on","type":"TOGGLE","label":"O","default_value":true},
          {"id":"net","type":"DROPDOWN","label":"D","options":[{"id":"o1","label":"One"}],"default_values":["o1"]}
        ]}
        """#)
        #expect(vm.values["name"] == .text("Bob"))
        #expect(vm.values["on"] == .bool(true))
        #expect(vm.values["net"] == .selection(["o1"]))
    }

    @Test("Absent defaults seed to empty text / false bool")
    func defaultsWhenAbsent() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"t","type":"TEXT","label":"T"},
          {"id":"c","type":"CHECKBOX","label":"C"}
        ]}
        """#)
        #expect(vm.values["t"] == .text(""))
        #expect(vm.values["c"] == .bool(false))
    }

    @Test("Default selection ids not present in options are dropped (§7 #9)")
    func defaultSelectionFilteredToValidOptions() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"net","type":"DROPDOWN","label":"D",
           "options":[{"id":"o1","label":"One"}],
           "default_values":["o1","ghost"]}
        ]}
        """#)
        #expect(vm.values["net"] == .selection(["o1"]))
    }

    @Test("Text default longer than max_length is truncated on seed (§7 #1)")
    func textDefaultTruncatedToMaxLength() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"name","type":"TEXT","label":"N","max_length":5,"default_value":"HelloWorld"}
        ]}
        """#)
        #expect(vm.values["name"] == .text("Hello"))
    }
}
