//
//  ByteCipherTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import XCTest

@testable import SecretMacroCore

final class ByteCipherTests: XCTestCase {
    func testXORRoundTripsWithRandomKey() {
        let plaintext = Array("Hello, Secret!".utf8)
        let key = SecureRandom.bytes(count: plaintext.count)

        let cipher = ByteCipher.xor(plaintext, key: key)
        XCTAssertNotEqual(cipher, plaintext, "ciphertext should not equal plaintext for a non-zero key")

        let decoded = ByteCipher.xor(cipher, key: key)
        XCTAssertEqual(decoded, plaintext)
    }

    func testXORWithEmptyKeyIsIdentity() {
        let plaintext = Array("unchanged".utf8)
        XCTAssertEqual(ByteCipher.xor(plaintext, key: []), plaintext)
    }

    func testXORRepeatsShortKey() {
        let plaintext: [UInt8] = [10, 20, 30, 40, 50]
        let key: [UInt8] = [1, 2]

        let cipher = ByteCipher.xor(plaintext, key: key)
        XCTAssertEqual(cipher, [11, 22, 31, 42, 51])

        XCTAssertEqual(ByteCipher.xor(cipher, key: key), plaintext)
    }

    func testSecureRandomProducesRequestedLength() {
        XCTAssertEqual(SecureRandom.bytes(count: 32).count, 32)
        XCTAssertEqual(SecureRandom.bytes(count: 0).count, 0)
    }
}
