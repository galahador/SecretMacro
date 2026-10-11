//
//  ObfuscateMacroTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import SecretMacroCore
@testable import SecretMacroMacros

final class ObfuscateMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = ["obfuscate": ObfuscateMacro.self]

    private let originalBytesProvider = SecureRandom.bytesProvider

    override func tearDown() {
        SecureRandom.bytesProvider = originalBytesProvider
        super.tearDown()
    }

    func testExpandsLiteralIntoObfuscatedCall() {
        SecureRandom.bytesProvider = { count in Array(repeating: 0, count: count) }

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
        SecureRandom.bytesProvider = { count in Array(repeating: 0, count: count) }

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
