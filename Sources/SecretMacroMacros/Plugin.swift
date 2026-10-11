//
//  Plugin.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SecretMacroCompilerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObfuscateMacro.self
    ]
}
