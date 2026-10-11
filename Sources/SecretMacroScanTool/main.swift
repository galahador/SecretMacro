//
//  main.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())

guard arguments.count >= 2 else {
    FileHandle.standardError.write(
        Data("usage: SecretMacroScanTool <ignorefile-or-'-'> <binary-path> [<binary-path> ...]\n".utf8)
    )
    exit(2)
}

let ignoreFileArgument = arguments[0]
let binaryPaths = arguments.dropFirst()

let configuration = ScanConfiguration.load(ignoreFileAt: ignoreFileArgument == "-" ? nil : ignoreFileArgument)

func report(_ severity: String, _ message: String) {
    print("\(severity)\t\(message)")
}

var totalMatches = 0

for pathString in binaryPaths {
    let url = URL(fileURLWithPath: pathString)
    let artifactName = url.lastPathComponent

    do {
        let found = try BinaryStringScanner.scan(binaryAt: url)
        let matches = SecretPatternMatcher.suspiciousStrings(in: found, ignoring: configuration.ignoredSubstrings)

        guard !matches.isEmpty else { continue }
        totalMatches += matches.count

        for match in matches {
            report("ERROR", "\(artifactName): possible \(match.reason) at offset 0x\(match.offset)")
        }
    } catch {
        report("WARNING", "\(artifactName): scan failed: \(error)")
    }
}

if totalMatches > 0 {
    report("ERROR", "found \(totalMatches) secret(s) across \(binaryPaths.count)")
    exit(1)
} else {
    report("REMARK", "scanned \(binaryPaths.count) artifact(s)")
    exit(0)
}
