//
//  ScanConfiguration.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation

struct ScanConfiguration {
    let ignoredSubstrings: [String]

    static func load(ignoreFileAt path: String?) -> ScanConfiguration {
        guard
            let path,
            let data = FileManager.default.contents(atPath: path),
            let text = String(data: data, encoding: .utf8)
        else {
            return ScanConfiguration(ignoredSubstrings: [])
        }

        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        return ScanConfiguration(ignoredSubstrings: lines)
    }
}
