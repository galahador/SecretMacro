//
//  ByteCipher.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

public enum ByteCipher {
    public static func xor(_ data: [UInt8], key: [UInt8]) -> [UInt8] {
        guard !key.isEmpty else { return data }
        return data.enumerated().map { index, byte in
            byte ^ key[index % key.count]
        }
    }
}
