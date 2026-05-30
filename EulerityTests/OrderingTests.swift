//
//  OrderingTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("Ordering")
@MainActor
struct OrderingTests {

    private func viewModel(_ json: String) throws -> FormViewModel {
        FormViewModel(payload: try JSONDecoder().decode(FormPayload.self, from: Data(json.utf8)))
    }

    @Test("Fields render sorted by `order`, not array index; missing order goes last")
    func sortedByOrderNotIndex() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"c","type":"TEXT","label":"C","order":3},
          {"id":"a","type":"TEXT","label":"A","order":1},
          {"id":"b","type":"TEXT","label":"B","order":2},
          {"id":"z","type":"TEXT","label":"Z"}
        ]}
        """#)
        #expect(vm.orderedFields.map(\.id) == ["a", "b", "c", "z"])
    }

    @Test("Equal orders keep their decode order (stable tie-break)")
    func stableTieBreak() throws {
        let vm = try viewModel(#"""
        {"fields":[
          {"id":"first","type":"TEXT","label":"F","order":1},
          {"id":"second","type":"TEXT","label":"S","order":1}
        ]}
        """#)
        #expect(vm.orderedFields.map(\.id) == ["first", "second"])
    }
}
