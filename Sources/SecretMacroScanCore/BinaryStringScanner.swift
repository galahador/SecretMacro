//
//  BinaryStringScanner.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation

public enum BinaryStringScanner {
    public enum ScanError: Error, CustomStringConvertible {
        case processFailed(Int32)

        public var description: String {
            switch self {
            case .processFailed(let status):
                return "`strings` exited with status \(status)."
            }
        }
    }
    
    // MARK: - Public
    public struct FoundString {
        public let offset: String
        public let value: String
    }

    public static func scan(binaryAt url: URL, minimumLength: Int = 6) throws -> [FoundString] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/strings")
        process.arguments = ["-n", "\(minimumLength)", "-t", "x", url.path]

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
        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { rawLine in
                let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                guard parts.count == 2 else { return nil }
                return FoundString(offset: String(parts[0]), value: String(parts[1]))
            }
    }
}
