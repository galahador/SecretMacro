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
        let allowEmptyScan = extractor.extractFlag(named: "allow-empty-scan") > 0

        let buildResult = try packageManager.build(
            .all(includingTests: false),
            parameters: .init(configuration: useReleaseConfig ? .release : .debug)
        )

        guard buildResult.succeeded else {
            Diagnostics.error("build failed, nothing to scan:\n\(buildResult.logText)")
            return
        }

        let scannableKinds: Set<PackageManager.BuildResult.BuiltArtifact.Kind> = [
            .executable, .dynamicLibrary, .staticLibrary
        ]
        let scannableArtifacts = buildResult.builtArtifacts.filter { scannableKinds.contains($0.kind) }

        let targetArtifacts: [PackageManager.BuildResult.BuiltArtifact]
        if requestedProducts.isEmpty {
            targetArtifacts = scannableArtifacts
        } else {
            targetArtifacts = scannableArtifacts.filter { requestedProducts.contains($0.url.lastPathComponent) }
            let foundNames = Set(targetArtifacts.map { $0.url.lastPathComponent })
            let missingNames = requestedProducts.subtracting(foundNames)
            guard missingNames.isEmpty else {
                Diagnostics.error("product not found: \(missingNames.sorted().joined(separator: ", "))")
                throw ScanFailure.productsNotFound(missingNames)
            }
        }

        guard !targetArtifacts.isEmpty else {
            guard allowEmptyScan else {
                Diagnostics.error("nothing to scan. Pass --allow-empty-scan if that's expected.")
                throw ScanFailure.noArtifactsToScan
            }
            Diagnostics.warning("nothing to scan, continuing (--allow-empty-scan).")
            return
        }

        Diagnostics.remark("scanning \(targetArtifacts.count) artifact(s): \(targetArtifacts.map { $0.url.lastPathComponent }.joined(separator: ", "))")

        let ignoreFileURL = context.package.directoryURL.appending(path: ".secretmacroignore")
        let ignoreFileArgument = FileManager.default.fileExists(atPath: ignoreFileURL.path) ? ignoreFileURL.path : "-"

        let tool = try context.tool(named: "SecretMacroScanTool")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = [ignoreFileArgument] + targetArtifacts.map { $0.url.path }

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        try process.run()
        let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(decoding: outputData, as: UTF8.self)
        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "\t", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let message = String(parts[1])
            switch parts[0] {
            case "ERROR":
                Diagnostics.error(message)
            case "WARNING":
                Diagnostics.warning(message)
            case "REMARK":
                Diagnostics.remark(message)
            default:
                break
            }
        }

        guard process.terminationStatus == 0 else {
            throw ScanFailure.secretsFound
        }
    }
}

// MARK: - Failure
enum ScanFailure: Error, CustomStringConvertible {
    case secretsFound
    case productsNotFound(Set<String>)
    case noArtifactsToScan

    var description: String {
        switch self {
        case .secretsFound:
            return "found likely secret(s), see errors above."
        case .productsNotFound(let names):
            return "product not found: \(names.sorted().joined(separator: ", "))."
        case .noArtifactsToScan:
            return "nothing scanned. Pass --allow-empty-scan if that's expected."
        }
    }
}
