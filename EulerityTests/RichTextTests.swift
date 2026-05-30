//
//  RichTextTests.swift
//  EulerityTests
//

import Testing
import Foundation
@testable import Eulerity

@Suite("RichTextLabel")
struct RichTextTests {

    @Test("A metadata key found in the label becomes a link covering exactly that text")
    func linkRangesResolved() {
        let url = URL(string: "https://example.com/tos")!
        let attributed = RichTextLabel.make(
            label: "I accept the Terms of Service today",
            metadata: ["Terms of Service": "https://example.com/tos"]
        )
        let linkedRuns = attributed.runs.filter { $0.link == url }
        #expect(!linkedRuns.isEmpty)
        let linkedText = linkedRuns.map { String(attributed[$0.range].characters) }.joined()
        #expect(linkedText == "Terms of Service")
    }

    @Test("A key not present in the label is ignored")
    func missingSubstringIgnored() {
        let attributed = RichTextLabel.make(
            label: "I accept the terms",
            metadata: ["Privacy Policy": "https://example.com/privacy"]
        )
        #expect(attributed.runs.allSatisfy { $0.link == nil })
    }

    @Test("A malformed URL is not made clickable")
    func malformedURLNotClickable() {
        let attributed = RichTextLabel.make(
            label: "See the Terms here",
            metadata: ["Terms": "not a url"]
        )
        #expect(attributed.runs.allSatisfy { $0.link == nil })
    }

    @Test("Nil metadata yields a plain, link-free label")
    func nilMetadataPlain() {
        let attributed = RichTextLabel.make(label: "Plain label", metadata: nil)
        #expect(attributed.runs.allSatisfy { $0.link == nil })
        #expect(String(attributed.characters) == "Plain label")
    }
}
