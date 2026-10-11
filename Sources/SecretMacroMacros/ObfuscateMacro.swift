//
//  ObfuscateMacro.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import SecretMacroCore
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ObfuscateMacro: ExpressionMacro {

    // MARK: - Public
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard let argumentExpr = node.argumentList.first?.expression,
              let literal = argumentExpr.as(StringLiteralExprSyntax.self) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: MacroDiagnostics.requiresStaticStringLiteral))
            return ExprSyntax(stringLiteral: "\"\"")
        }

        guard let value = literal.representedLiteralValue else {
            context.diagnose(Diagnostic(node: Syntax(literal), message: MacroDiagnostics.requiresStaticStringLiteral))
            return ExprSyntax(stringLiteral: "\"\"")
        }

        let plaintext = Array(value.utf8)
        let key = SecureRandom.bytes(count: plaintext.count)
        let cipher = ByteCipher.xor(plaintext, key: key)
        
        let bytesLiteral = hexArrayLiteral(cipher)
        let keyLiteral = hexArrayLiteral(key)
        
        return ExprSyntax(
            "SecretMacro.Obfuscated(bytes: \(raw: bytesLiteral), key: \(raw: keyLiteral)).reveal()"
        )
    }
    
    // MARK: - Private
    private static func hexArrayLiteral(_ bytes: [UInt8]) -> String {
        "[" + bytes.map { "0x" + String($0, radix: 16) }.joined(separator: ", ") + "]"
    }
}
