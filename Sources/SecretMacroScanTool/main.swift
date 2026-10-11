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
        Data("usage: SecretMacroScanTool <ignorefile|-> <binary> [<binary> ...]\n".utf8)
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
var unreadableArtifacts = 0

for pathString in binaryPaths {
    let url = URL(fileURLWithPath: pathString)
    let artifactName = url.lastPathComponent

    do {
        let found = try BinaryStringScanner.scan(binaryAt: url)
        let matches = SecretPatternMatcher.suspiciousStrings(in: found, ignoring: configuration.ignoredSubstrings)

        guard !matches.isEmpty else { continue }
        totalMatches += matches.count

        for match in matches {
            report("ERROR", "\(artifactName): possible \(match.reason) at 0x\(match.offset)")
        }
    } catch {
        unreadableArtifacts += 1
        report("ERROR", "\(artifactName): scan failed (\(error))")
    }
}

let scannedSuccessfully = binaryPaths.count - unreadableArtifacts

if unreadableArtifacts > 0 {
    report("ERROR", "\(unreadableArtifacts)/\(binaryPaths.count) artifacts failed to scan")
}

if totalMatches > 0 {
    report("ERROR", "found \(totalMatches) likely secret(s) in \(scannedSuccessfully) artifact(s)")
}

guard unreadableArtifacts == 0, totalMatches == 0 else {
    exit(1)
}

report("REMARK", "scanned \(scannedSuccessfully)/\(binaryPaths.count) artifacts, nothing found")
exit(0)
