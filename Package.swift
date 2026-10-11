// swift-tools-version: 6.0
//
//  Package.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SecretMacro",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ],
    products: [
        .library(name: "SecretMacro", targets: ["SecretMacro"]),
        .plugin(name: "SecretMacroScan", targets: ["SecretMacroScan"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [.target(
            name: "SecretMacroCore"
        ),
        .target(
            name: "SecretMacroScanCore"
        ),
        .macro(
            name: "SecretMacroMacros",
            dependencies: [
                "SecretMacroCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "SecretMacro",
            dependencies: [
                "SecretMacroCore",
                "SecretMacroMacros"
            ]
        ),
        .plugin(
            name: "SecretMacroScan",
            capability: .command(
                intent: .custom(
                    verb: "secret-scan",
                    description: "Scans built binaries for plaintext secrets using `strings`."
                )
            ),
            dependencies: [
                "SecretMacroScanCore"
            ]
        ),

        .testTarget(
            name: "SecretMacroTests",
            dependencies: [
                "SecretMacro",
                "SecretMacroCore"
            ]
        ),
        .testTarget(
            name: "SecretMacroMacrosTests",
            dependencies: [
                "SecretMacroMacros",
                "SecretMacroCore",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "SecretMacroScanCoreTests",
            dependencies: [
                "SecretMacroScanCore"
            ]
        )
    ]
)
