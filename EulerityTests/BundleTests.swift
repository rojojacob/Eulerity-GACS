//
//  BundleTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("Bundle resources")
struct BundleTests {

    /// Plan.md A1 acceptance: the form payload JSON must ship inside the app
    /// bundle so `FormLoader` can read it at runtime.
    @Test("The form payload JSON is bundled with the app")
    func payloadFileExistsInBundle() throws {
        let url = Bundle.main.url(forResource: "form_payload", withExtension: "json")
        #expect(url != nil)
    }
}
