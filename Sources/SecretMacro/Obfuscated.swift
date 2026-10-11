//
//  Obfuscated.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import SecretMacroCore

public struct Obfuscated: Sendable {
    public let bytes: [UInt8]
    public let key: [UInt8]

    public init(bytes: [UInt8], key: [UInt8]) {
        self.bytes = bytes
        self.key = key
    }

    public func reveal() -> String {
        let plaintext = ByteCipher.xor(bytes, key: key)
        return String(decoding: plaintext, as: UTF8.self)
    }
}
