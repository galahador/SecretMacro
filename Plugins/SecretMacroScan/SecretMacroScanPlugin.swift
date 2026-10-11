//
//  SecretMacroScanPlugin.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation
import PackagePlugin

@main
struct SecretMacroScanPlugin: CommandPlugin {
    
    // MARK: - Public
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        let requestedProducts = Set(extractor.extractOption(named: "product"))
        let useReleaseConfig = extractor.extractFlag(named: "release") > 0

        let buildResult = try packageManager.build(
            .all(includingTests: false),
            parameters: .init(configuration: useReleaseConfig ? .release : .debug)
        )

        guard buildResult.succeeded else {
            Diagnostics.error("secret-scan: build failed, nothing to scan.\n\(buildResult.logText)")
            return
        }

        let configuration = ScanConfiguration.load(from: context.package.directoryURL)

        let scannableArtifacts = buildResult.builtArtifacts.filter { artifact in
            artifact.kind == .executable || artifact.kind == .dynamicLibrary
        }

        guard !scannableArtifacts.isEmpty else {
            Diagnostics.warning("secret-scan: build produced no executable or dynamic library artifacts to scan.")
            return
        }

        var totalMatches = 0

        for artifact in scannableArtifacts {
            let artifactName = artifact.url.lastPathComponent
            if !requestedProducts.isEmpty, !requestedProducts.contains(artifactName) {
                continue
            }

            let strings = try BinaryStringScanner.scan(binaryAt: artifact.url)
            let matches = SecretPatternMatcher.suspiciousStrings(
                in: strings,
                ignoring: configuration.ignoredSubstrings
            )

            guard !matches.isEmpty else { continue }
            totalMatches += matches.count

            for match in matches {
                Diagnostics.error("secret-scan: \(artifactName): possible \(match.reason): \(match.line)")
            }
        }

        if totalMatches > 0 {
            Diagnostics.error("secret-scan: found \(totalMatches)")
            throw ScanFailure.secretsFound(count: totalMatches)
        }
    }
}

// MARK: - Failure 
enum ScanFailure: Error, CustomStringConvertible {
    case secretsFound(count: Int)

    var description: String {
        switch self {
        case .secretsFound(let count):
            return "secret-scan found \(count) likely plaintext secret(s)."
        }
    }
}
