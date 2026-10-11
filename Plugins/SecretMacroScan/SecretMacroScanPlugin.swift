//
//  SecretMacroScanPlugin.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation
import PackagePlugin
import SecretMacroScanCore

@main
struct SecretMacroScanPlugin: CommandPlugin {

    private static let scannableKinds: Set<PackageManager.BuildResult.BuiltArtifact.Kind> = [
        .executable, .dynamicLibrary, .staticLibrary
    ]

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

        let scannableArtifacts = buildResult.builtArtifacts.filter { Self.scannableKinds.contains($0.kind) }

        let targetArtifacts: [PackageManager.BuildResult.BuiltArtifact]
        if requestedProducts.isEmpty {
            targetArtifacts = scannableArtifacts
        } else {
            targetArtifacts = scannableArtifacts.filter { requestedProducts.contains($0.url.lastPathComponent) }
            let foundNames = Set(targetArtifacts.map { $0.url.lastPathComponent })
            let missingNames = requestedProducts.subtracting(foundNames)
            guard missingNames.isEmpty else {
                Diagnostics.error("secret-scan: requested --product not found among built artifacts: \(missingNames.sorted().joined(separator: ", "))")
                throw ScanFailure.productsNotFound(missingNames)
            }
        }

        guard !targetArtifacts.isEmpty else {
            Diagnostics.warning("secret-scan: build produced no executable, dynamic library, or static library artifacts to scan.")
            return
        }

        Diagnostics.remark("secret-scan: scanning \(targetArtifacts.count) artifact(s): \(targetArtifacts.map { $0.url.lastPathComponent }.joined(separator: ", "))")

        var totalMatches = 0

        for artifact in targetArtifacts {
            let artifactName = artifact.url.lastPathComponent

            let strings = try BinaryStringScanner.scan(binaryAt: artifact.url)
            let matches = SecretPatternMatcher.suspiciousStrings(
                in: strings,
                ignoring: configuration.ignoredSubstrings
            )

            guard !matches.isEmpty else { continue }
            totalMatches += matches.count

            for match in matches {
                Diagnostics.error("secret-scan: \(artifactName): possible \(match.reason) at offset 0x\(match.offset)")
            }
        }

        if totalMatches > 0 {
            Diagnostics.error("secret-scan: found \(totalMatches) likely plaintext secret(s) across \(targetArtifacts.count) artifact(s). Wrap them in #obfuscate(...) or add a reviewed exception to .secretmacroignore.")
            throw ScanFailure.secretsFound(count: totalMatches)
        }
    }
}

// MARK: - Failure
enum ScanFailure: Error, CustomStringConvertible {
    case secretsFound(count: Int)
    case productsNotFound(Set<String>)

    var description: String {
        switch self {
        case .secretsFound(let count):
            return "secret-scan found \(count) likely plaintext secret(s)."
        case .productsNotFound(let names):
            return "secret-scan: requested --product not found: \(names.sorted().joined(separator: ", "))."
        }
    }
}
