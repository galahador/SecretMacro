//
//  MacroDiagnostics.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import SwiftDiagnostics

enum MacroDiagnostics: String, DiagnosticMessage {
    case requiresStaticStringLiteral

    var message: String {
        switch self {
        case .requiresStaticStringLiteral:
            return "#obfuscate requires a non-interpolated string literal known at compile time."
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "SecretMacro", id: rawValue)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
