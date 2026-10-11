//
//  ObfuscateMacroTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import SecretMacroMacros

private struct ZeroByteGenerator: RandomByteGenerating {
    func bytes(count: Int) -> [UInt8] { Array(repeating: 0, count: count) }
}

final class ObfuscateMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["obfuscate": ObfuscateMacro.self]

    private let originalGenerator = SecureRandom.generator

    override func tearDown() {
        SecureRandom.generator = originalGenerator
        super.tearDown()
    }

    func testExpandsLiteralIntoObfuscatedCall() {
        SecureRandom.generator = ZeroByteGenerator()

        assertMacroExpansion(
            #"""
            let key = #obfuscate("abc")
            """#,
            expandedSource: #"""
            let key = SecretMacro.Obfuscated(bytes: [0x61, 0x62, 0x63], key: [0x0, 0x0, 0x0]).reveal()
            """#,
            macros: macros
        )
    }

    func testEmptyLiteralExpandsToEmptyArrays() {
        SecureRandom.generator = ZeroByteGenerator()

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
