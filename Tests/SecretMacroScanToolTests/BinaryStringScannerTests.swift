//
//  BinaryStringScannerTests.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-12.
//

import XCTest

@testable import SecretMacroScanTool

final class BinaryStringScannerTests: XCTestCase {
    private var tempFileURL: URL!

    override func setUp() {
        super.setUp()
        tempFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryStringScannerTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }

    private func write(_ contents: String) throws {
        try Data(contents.utf8).write(to: tempFileURL)
    }

    func testFindsPrintableStringsAboveMinimumLength() throws {
        try write("short\0averylongprintablestring\0hi\0anotherlongone12345\0")

        let found = try BinaryStringScanner.scan(binaryAt: tempFileURL, minimumLength: 10)
        let values = found.map(\.value)

        XCTAssertTrue(values.contains("averylongprintablestring"))
        XCTAssertTrue(values.contains("anotherlongone12345"))
        XCTAssertFalse(values.contains("short"))
        XCTAssertFalse(values.contains("hi"))
    }

    func testReturnsParsableHexOffsets() throws {
        try write("\0\0\0\0\0\0\0\0\0\0helloworldlongenough\0")

        let found = try BinaryStringScanner.scan(binaryAt: tempFileURL, minimumLength: 6)
        let match = try XCTUnwrap(found.first { $0.value == "helloworldlongenough" })

        XCTAssertNotNil(UInt(match.offset, radix: 16))
    }

    func testScanningMissingFileThrows() {
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("does-not-exist-\(UUID().uuidString)")
        XCTAssertThrowsError(try BinaryStringScanner.scan(binaryAt: missingURL))
    }

    func testScanningRealSystemBinarySucceeds() throws {
        let found = try BinaryStringScanner.scan(binaryAt: URL(fileURLWithPath: "/bin/ls"), minimumLength: 6)
        XCTAssertFalse(found.isEmpty)
    }
}
