//
//  ObfuscatedRuntimeTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import XCTest

import SecretMacroCore
@testable import SecretMacro

final class ObfuscatedRuntimeTests: XCTestCase {
    func testRevealReconstructsOriginalString() {
        let plaintext = Array("super-secret-api-key".utf8)
        let key = SecureRandom.bytes(count: plaintext.count)
        let cipher = ByteCipher.xor(plaintext, key: key)

        let obfuscated = Obfuscated(bytes: cipher, key: key)
        XCTAssertEqual(obfuscated.reveal(), "super-secret-api-key")
    }

    func testRevealHandlesEmptyString() {
        let obfuscated = Obfuscated(bytes: [], key: [])
        XCTAssertEqual(obfuscated.reveal(), "")
    }

    func testObfuscateMacroRoundTripsAtRuntime() {
        let revealed = #obfuscate("integration-test-value")
        XCTAssertEqual(revealed, "integration-test-value")
    }

    func testObfuscateMacroResolvesEscapeSequences() {
        let revealed = #obfuscate("line1\nline2\ttabbed \"quoted\" \\backslash")
        XCTAssertEqual(revealed, "line1\nline2\ttabbed \"quoted\" \\backslash")
    }
}
