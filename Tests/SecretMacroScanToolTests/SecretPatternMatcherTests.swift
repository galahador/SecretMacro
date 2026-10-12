//
//  SecretPatternMatcherTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-12.
//

import XCTest

@testable import SecretMacroScanTool

final class SecretPatternMatcherTests: XCTestCase {
    private func found(_ value: String, offset: String = "0") -> BinaryStringScanner.FoundString {
        BinaryStringScanner.FoundString(offset: offset, value: value)
    }

    // MARK: - Recognized formats
    func testDetectsAWSAccessKey() {
        let matches = SecretPatternMatcher.suspiciousStrings(in: [found("AKIAIOSFODNN7EXAMPLE")])
        XCTAssertEqual(matches.first?.reason, "AWS Access Key")
    }

    func testDetectsJWT() {
        let token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dGhpc2lzbm90YXJlYWxzaWduYXR1cmU"
        let matches = SecretPatternMatcher.suspiciousStrings(in: [found(token)])
        XCTAssertEqual(matches.first?.reason, "JWT")
    }

    func testDetectsPrivateKeyHeader() {
        let matches = SecretPatternMatcher.suspiciousStrings(in: [found("-----BEGIN RSA PRIVATE KEY-----")])
        XCTAssertEqual(matches.first?.reason, "Private key header")
    }

    func testDetectsBearerToken() {
        let matches = SecretPatternMatcher.suspiciousStrings(in: [found("Bearer abcdEFGH12345678ij")])
        XCTAssertEqual(matches.first?.reason, "Bearer token")
    }

    func testFallsBackToHighEntropyForUnrecognizedFormats() {
        let matches = SecretPatternMatcher.suspiciousStrings(in: [found("a8K2zQ9pL4xR7nW1cF3dH6j")])
        XCTAssertEqual(matches.first?.reason, "high-entropy string")
    }

    // MARK: - False positives

    func testIgnoresOrdinaryShortText() {
        let matches = SecretPatternMatcher.suspiciousStrings(
            in: [found("Hello, world!"), found("DemoApp"), found("Content-Type")]
        )
        XCTAssertTrue(matches.isEmpty)
    }

    func testExcludesKnownCompilerSymbols() {
        let strings = [
            found("swift_task_enterThreadLocalContext"),
            found("_Z19voucher_needs_adoptP9voucher_s")
        ]
        XCTAssertTrue(SecretPatternMatcher.suspiciousStrings(in: strings).isEmpty)
    }

    func testIgnoredSubstringsSuppressMatches() {
        let matches = SecretPatternMatcher.suspiciousStrings(
            in: [found("AKIAIOSFODNN7EXAMPLE")],
            ignoring: ["AKIAIOSFODNN7EXAMPLE"]
        )
        XCTAssertTrue(matches.isEmpty)
    }

    func testMatchPreservesOffsetAndValue() {
        let matches = SecretPatternMatcher.suspiciousStrings(
            in: [found("AKIAIOSFODNN7EXAMPLE", offset: "2060")]
        )
        XCTAssertEqual(matches.first?.offset, "2060")
        XCTAssertEqual(matches.first?.value, "AKIAIOSFODNN7EXAMPLE")
    }
}
