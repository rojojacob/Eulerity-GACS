//
//  FocusTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("Focus order")
@MainActor
struct FocusTests {

    private func viewModel(_ json: String) throws -> FormViewModel {
        FormViewModel(payload: try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8)))
    }

    @Test("Focus order is the text fields in visual order, excluding non-text")
    func focusOrderMatchesVisualOrder() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"c","type":"TEXT","label":"C","order":3},
          {"id":"toggle","type":"TOGGLE","label":"T","order":2},
          {"id":"a","type":"TEXT","label":"A","order":1},
          {"id":"drop","type":"DROPDOWN","label":"D","order":4,"options":[]},
          {"id":"b","type":"TEXT","label":"B","order":5}
        ]}
        """#)
        // Visual order by `order`: a(1), toggle(2), c(3), drop(4), b(5).
        // Text fields only: a, c, b.
        #expect(vm.textFieldIDsInOrder == ["a", "c", "b"])
    }
}
