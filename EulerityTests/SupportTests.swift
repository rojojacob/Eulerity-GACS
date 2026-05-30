//
//  SupportTests.swift
//  EulerityTests
//

import Testing
@testable import Eulerity

@Suite("ViewState")
struct ViewStateTests {

    @Test("Exposes the loaded value and nothing in other states")
    func exposesLoadedValue() {
        #expect(ViewState.loaded(42).value == 42)
        #expect(ViewState<Int>.loading.value == nil)
        #expect(ViewState<Int>.idle.value == nil)
    }

    @Test("Reports loading only while loading")
    func reportsLoading() {
        #expect(ViewState<Int>.loading.isLoading)
        #expect(!ViewState<Int>.loaded(1).isLoading)
    }
}
