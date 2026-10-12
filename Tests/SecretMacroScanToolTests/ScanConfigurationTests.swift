//
//  ScanConfigurationTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-12.
//

import XCTest

@testable import SecretMacroScanTool

final class ScanConfigurationTests: XCTestCase {
    func testNilPathReturnsEmptyIgnoreList() {
        let configuration = ScanConfiguration.load(ignoreFileAt: nil)
        XCTAssertTrue(configuration.ignoredSubstrings.isEmpty)
    }

    func testMissingFileReturnsEmptyIgnoreList() {
        let missingPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString)").path
        let configuration = ScanConfiguration.load(ignoreFileAt: missingPath)
        XCTAssertTrue(configuration.ignoredSubstrings.isEmpty)
    }

    func testParsesEntriesSkippingBlankLinesAndComments() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ignore-\(UUID().uuidString)")
        let contents = """
        # comment
        some-known-false-positive

        another-entry
        # another comment
        """
        try Data(contents.utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let configuration = ScanConfiguration.load(ignoreFileAt: fileURL.path)
        XCTAssertEqual(configuration.ignoredSubstrings, ["some-known-false-positive", "another-entry"])
    }
}
