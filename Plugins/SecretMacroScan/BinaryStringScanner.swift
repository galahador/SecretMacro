//
//  BinaryStringScanner.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation
import PackagePlugin

enum BinaryStringScanner {
    enum ScanError: Error, CustomStringConvertible {
        case processFailed(Int32)

        var description: String {
            switch self {
            case .processFailed(let status):
                return "`strings` exited with status \(status)."
            }
        }
    }

    // MARK: - Public
    static func scan(binaryAt path: Path, minimumLength: Int = 6) throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/strings")
        process.arguments = ["-n", "\(minimumLength)", path.string]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ScanError.processFailed(process.terminationStatus)
        }

        let output = String(decoding: data, as: UTF8.self)
        return output.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }
}
