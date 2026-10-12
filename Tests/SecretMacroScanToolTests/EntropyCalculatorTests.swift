//
//  EntropyCalculatorTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-12.
//

import XCTest

@testable import SecretMacroScanTool

final class EntropyCalculatorTests: XCTestCase {
    func testShannonEntropyOfEmptyStringIsZero() {
        XCTAssertEqual(EntropyCalculator.shannonEntropy(of: ""), 0)
    }

    func testShannonEntropyOfRepeatedCharacterIsZero() {
        XCTAssertEqual(EntropyCalculator.shannonEntropy(of: "aaaaaaaaaa"), 0)
    }

    func testShannonEntropyOfAllDistinctCharactersIsHigh() {
        let entropy = EntropyCalculator.shannonEntropy(of: "a8K2zQ9pL4xR7nW1")
        XCTAssertEqual(entropy, 4.0, accuracy: 0.01)
    }

    func testIsHighEntropyRequiresMinimumLength() {
        XCTAssertFalse(EntropyCalculator.isHighEntropy("a8K2zQ9pL4"))
    }

    func testIsHighEntropyFlagsLongRandomLookingToken() {
        XCTAssertTrue(EntropyCalculator.isHighEntropy("a8K2zQ9pL4xR7nW1cF3dH6j"))
    }

    func testIsHighEntropyRejectsStringsWithWhitespace() {
        XCTAssertFalse(EntropyCalculator.isHighEntropy("this is an ordinary sentence with many words"))
    }

    func testIsHighEntropyRejectsLowDiversityText() {
        XCTAssertFalse(EntropyCalculator.isHighEntropy("aaaaaaaaaaaaaaaaaaaaaaaaaa"))
    }
}
