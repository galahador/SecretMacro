//
//  SecretMacro.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

@freestanding(expression)
public macro obfuscate(_ value: StaticString) -> String = #externalMacro(module: "SecretMacroMacros", type: "ObfuscateMacro")
