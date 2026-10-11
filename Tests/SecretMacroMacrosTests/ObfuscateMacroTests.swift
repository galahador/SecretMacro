//
//  ObfuscateMacroTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import SecretMacroMacros

final class ObfuscateMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["obfuscate": ObfuscateMacro.self]

    func testRenderExpressionBuildsObfuscatedCall() {
        let rendered = ObfuscateMacro.renderExpression(
            plaintext: Array("abc".utf8),
            key: [0, 0, 0]
        )
        XCTAssertEqual(
            rendered.description,
            "SecretMacro.Obfuscated(bytes: [0x61, 0x62, 0x63], key: [0x0, 0x0, 0x0]).reveal()"
        )
    }

    func testRenderExpressionHandlesEmptyInput() {
        let rendered = ObfuscateMacro.renderExpression(plaintext: [], key: [])
        XCTAssertEqual(rendered.description, "SecretMacro.Obfuscated(bytes: [], key: []).reveal()")
    }

    func testExpandsLiteralIntoObfuscatedCall() throws {
        let expr = ExprSyntax(#"#obfuscate("abc")"#)
        let node = try XCTUnwrap(expr.as(MacroExpansionExprSyntax.self))
        let context = BasicMacroExpansionContext()

        let result = try ObfuscateMacro.expansion(of: node, in: context)
        let description = result.description

        let bytes = try extractHexArray(named: "bytes", from: description)
        let key = try extractHexArray(named: "key", from: description)

        XCTAssertEqual(bytes.count, 3)
        XCTAssertEqual(key.count, 3)

        let decoded = zip(bytes, key).map { $0 ^ $1 }
        XCTAssertEqual(String(decoding: decoded, as: UTF8.self), "abc")
    }

    private func extractHexArray(named field: String, from description: String) throws -> [UInt8] {
        guard let startRange = description.range(of: "\(field): [") else {
            XCTFail("missing \(field) array in \(description)")
            return []
        }
        let rest = description[startRange.upperBound...]
        guard let closingBracket = rest.firstIndex(of: "]") else {
            XCTFail("unterminated \(field) array in \(description)")
            return []
        }
        let inner = rest[..<closingBracket]
        guard !inner.isEmpty else { return [] }
        return inner.split(separator: ", ").map { UInt8($0.dropFirst(2), radix: 16)! }
    }

    func testEmptyLiteralExpandsToEmptyArrays() {
        assertMacroExpansion(
            #"""
            let key = #obfuscate("")
            """#,
            expandedSource: #"""
            let key = SecretMacro.Obfuscated(bytes: [], key: []).reveal()
            """#,
            macros: macros
        )
    }

    func testNonLiteralArgumentProducesDiagnostic() {
        assertMacroExpansion(
            #"""
            let name = "dynamic"
            let key = #obfuscate(name)
            """#,
            expandedSource: #"""
            let name = "dynamic"
            let key = ""
            """#,
            diagnostics: [
                DiagnosticSpec(
                    message: "#obfuscate requires a non-interpolated string literal known at compile time.",
                    line: 2,
                    column: 11
                )
            ],
            macros: macros
        )
    }

    func testInterpolatedArgumentProducesDiagnostic() {
        assertMacroExpansion(
            #"""
            let suffix = "x"
            let key = #obfuscate("abc\(suffix)")
            """#,
            expandedSource: #"""
            let suffix = "x"
            let key = ""
            """#,
            diagnostics: [
                DiagnosticSpec(
                    message: "#obfuscate requires a non-interpolated string literal known at compile time.",
                    line: 2,
                    column: 22
                )
            ],
            macros: macros
        )
    }
}
