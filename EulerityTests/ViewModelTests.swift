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

@Suite("FormViewModel updates")
@MainActor
struct ViewModelUpdateTests {

    private func viewModel(_ json: String) throws -> FormViewModel {
        FormViewModel(payload: try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8)))
    }

    @Test("updateText truncates input to max_length (blocks overflow)")
    func maxLengthBlocksOverflow() throws {
        let vm = try viewModel(#"{"fields":[{"id":"n","type":"TEXT","label":"N","max_length":5}]}"#)
        vm.updateText("n", to: "HelloWorld")
        #expect(vm.values["n"] == .text("Hello"))
    }

    @Test("updateText without max_length stores the full value")
    func updateTextWithoutMaxLength() throws {
        let vm = try viewModel(#"{"fields":[{"id":"n","type":"TEXT","label":"N"}]}"#)
        vm.updateText("n", to: "anything goes here")
        #expect(vm.values["n"] == .text("anything goes here"))
    }

    @Test("toggle flips the boolean value")
    func toggleFlips() throws {
        let vm = try viewModel(#"{"fields":[{"id":"c","type":"CHECKBOX","label":"C"}]}"#)
        #expect(vm.values["c"] == .bool(false))
        vm.toggle("c")
        #expect(vm.values["c"] == .bool(true))
        vm.toggle("c")
        #expect(vm.values["c"] == .bool(false))
    }

    @Test("Single-select replaces the selection")
    func singleSelectReplaces() throws {
        let vm = try viewModel(#"""
        {"fields":[{"id":"d","type":"DROPDOWN","label":"D","allow_multiple":false,
          "options":[{"id":"o1","label":"One"},{"id":"o2","label":"Two"}]}]}
        """#)
        vm.select("d", optionID: "o1")
        #expect(vm.values["d"] == .selection(["o1"]))
        vm.select("d", optionID: "o2")
        #expect(vm.values["d"] == .selection(["o2"]))
    }

    @Test("Multi-select toggles membership (add then remove)")
    func multiSelectTogglesMembership() throws {
        let vm = try viewModel(#"""
        {"fields":[{"id":"d","type":"DROPDOWN","label":"D","allow_multiple":true,
          "options":[{"id":"o1","label":"One"},{"id":"o2","label":"Two"}]}]}
        """#)
        vm.select("d", optionID: "o1")
        #expect(vm.values["d"] == .selection(["o1"]))
        vm.select("d", optionID: "o2")
        #expect(vm.values["d"] == .selection(["o1", "o2"]))
        vm.select("d", optionID: "o1")
        #expect(vm.values["d"] == .selection(["o2"]))
    }
}
