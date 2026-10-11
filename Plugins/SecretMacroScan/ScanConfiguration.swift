//
//  ScanConfiguration.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation

struct ScanConfiguration {
    let ignoredSubstrings: [String]

    static func load(from packageDirectory: URL) -> ScanConfiguration {
        let configURL = packageDirectory.appending(path: ".secretmacroignore")
        guard
            let data = FileManager.default.contents(atPath: configURL.path),
            let text = String(data: data, encoding: .utf8) else {
            return ScanConfiguration(ignoredSubstrings: [])
        }

        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        return ScanConfiguration(ignoredSubstrings: lines)
    }
}
