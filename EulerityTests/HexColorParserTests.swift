//
//  HexColorParserTests.swift
//  EulerityTests
//

import Testing
import SwiftUI
@testable import Eulerity

@Suite("HexColorParser")
struct HexColorParserTests {

    @Test("Parses a 6-digit hex")
    func sixDigit() throws {
        let rgba = try #require(HexColorParser.rgba(from: "#FF0000"))
        #expect(rgba == HexColorParser.RGBA(red: 1, green: 0, blue: 0, alpha: 1))
    }

    @Test("Expands 3-digit shorthand")
    func threeDigit() throws {
        let rgba = try #require(HexColorParser.rgba(from: "#0F0"))
        #expect(rgba == HexColorParser.RGBA(red: 0, green: 1, blue: 0, alpha: 1))
    }

    @Test("Parses 8-digit hex with alpha")
    func eightDigit() throws {
        let rgba = try #require(HexColorParser.rgba(from: "#0000FF80"))
        #expect(rgba.red == 0)
        #expect(rgba.blue == 1)
        #expect(abs(rgba.alpha - 128.0 / 255.0) < 0.0001)
    }

    @Test("Accepts hex without a leading #")
    func missingHash() throws {
        let rgba = try #require(HexColorParser.rgba(from: "00FF00"))
        #expect(rgba == HexColorParser.RGBA(red: 0, green: 1, blue: 0, alpha: 1))
    }

    @Test("Returns nil for empty input")
    func emptyInput() {
        #expect(HexColorParser.rgba(from: "") == nil)
        #expect(HexColorParser.rgba(from: "#") == nil)
        #expect(HexColorParser.rgba(from: "   ") == nil)
    }

    @Test("Returns nil for non-hex digits")
    func invalidDigits() {
        #expect(HexColorParser.rgba(from: "#GGGGGG") == nil)
    }

    @Test("Returns nil for an unsupported length")
    func wrongLength() {
        #expect(HexColorParser.rgba(from: "#FF") == nil)
        #expect(HexColorParser.rgba(from: "#FFFFF") == nil)
    }
}

@Suite("ResolvedTheme")
struct ResolvedThemeTests {

    @Test("A nil model resolves entirely to the fallback theme")
    func nilModelFallsBack() {
        #expect(ResolvedTheme(model: nil) == .fallback)
    }

    @Test("An invalid hex channel falls back to its default")
    func invalidChannelFallsBack() {
        let model = ThemeModel(backgroundColor: "not-a-color", textColor: nil, borderColor: nil, errorColor: nil)
        #expect(ResolvedTheme(model: model).background == ResolvedTheme.fallback.background)
    }

    @Test("A valid hex channel is parsed rather than defaulted")
    func validChannelParsed() {
        let model = ThemeModel(backgroundColor: "#FF0000", textColor: nil, borderColor: nil, errorColor: nil)
        let expected = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)
        #expect(ResolvedTheme(model: model).background == expected)
    }
}
