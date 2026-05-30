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

    @Test("Default selection ids not present in options are dropped")
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

    @Test("Text default longer than max_length is truncated on seed")
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

@Suite("FormViewModel submit")
@MainActor
struct ViewModelSubmitTests {

    private func viewModel(_ json: String) throws -> FormViewModel {
        FormViewModel(payload: try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8)))
    }

    @Test("An invalid form blocks submit and surfaces errors")
    func submitBlockedWhenInvalid() throws {
        let vm = try viewModel(#"{"fields":[{"id":"name","type":"TEXT","label":"N","required":true}]}"#)
        vm.validateAndSubmit()
        #expect(vm.errors["name"] != nil)
        #expect(vm.confirmation == nil)
    }

    @Test("A valid submit preserves scalars, arrays, and bools in the payload")
    func submitPayloadShapeMatchesValues() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"campaign_name","type":"TEXT","label":"N","required":true},
          {"id":"single_net","type":"DROPDOWN","label":"S","options":[{"id":"net_meta","label":"Meta"}]},
          {"id":"ad_networks","type":"DROPDOWN","label":"A","allow_multiple":true,
           "options":[{"id":"a","label":"A"},{"id":"b","label":"B"}]},
          {"id":"accept_legal","type":"CHECKBOX","label":"L"}
        ]}
        """#)
        vm.updateText("campaign_name", to: "Summer Sale")
        vm.select("single_net", optionID: "net_meta")
        vm.select("ad_networks", optionID: "a")
        vm.select("ad_networks", optionID: "b")
        vm.toggle("accept_legal")

        vm.validateAndSubmit()

        #expect(vm.errors.isEmpty)
        let payload = try #require(vm.confirmation?.payload)
        #expect(payload["campaign_name"] == .string("Summer Sale"))   // text → scalar
        #expect(payload["single_net"] == .string("net_meta"))         // single-select → scalar id
        #expect(payload["ad_networks"] == .strings(["a", "b"]))       // multi-select → array
        #expect(payload["accept_legal"] == .bool(true))              // checkbox → bool
    }

    @Test("Empty text and empty selections are omitted; bools are always included")
    func omitsEmptyValues() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"name","type":"TEXT","label":"N"},
          {"id":"net","type":"DROPDOWN","label":"D","options":[{"id":"o1","label":"One"}]},
          {"id":"flag","type":"TOGGLE","label":"F"}
        ]}
        """#)
        vm.validateAndSubmit()
        let payload = try #require(vm.confirmation?.payload)
        #expect(payload["name"] == nil)
        #expect(payload["net"] == nil)
        #expect(payload["flag"] == .bool(false))
    }

    @Test("Dismiss clears the confirmation")
    func dismissClearsConfirmation() throws {
        let vm = try viewModel(#"{"fields":[{"id":"f","type":"TOGGLE","label":"F"}]}"#)
        vm.validateAndSubmit()
        #expect(vm.confirmation != nil)
        vm.dismissConfirmation()
        #expect(vm.confirmation == nil)
    }
}

@Suite("FormViewModel regex")
@MainActor
struct ViewModelRegexTests {

    private func viewModel(_ json: String) throws -> FormViewModel {
        FormViewModel(payload: try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8)))
    }

    private let regexField = #"{"fields":[{"id":"code","type":"TEXT","label":"C","regex":"^[A-Z0-9]{4,10}$"}]}"#

    @Test("A regex-failing value blocks submit with an inline error")
    func regexErrorSurfacesOnSubmit() throws {
        let vm = try viewModel(regexField)
        vm.updateText("code", to: "lower")
        vm.validateAndSubmit()
        #expect(vm.errors["code"] != nil)
        #expect(vm.confirmation == nil)
    }

    @Test("A matching value submits cleanly through the precompiled regex")
    func regexValidSubmits() throws {
        let vm = try viewModel(regexField)
        vm.updateText("code", to: "SAVE20")
        vm.validateAndSubmit()
        #expect(vm.errors.isEmpty)
        #expect(vm.confirmation != nil)
    }

    @Test("An invalid regex pattern is ignored end-to-end, never blocks submit")
    func invalidPatternIgnored() throws {
        let vm = try viewModel(#"{"fields":[{"id":"code","type":"TEXT","label":"C","regex":"[unclosed"}]}"#)
        vm.updateText("code", to: "anything")
        vm.validateAndSubmit()
        #expect(vm.errors.isEmpty)
        #expect(vm.confirmation != nil)
    }
}
