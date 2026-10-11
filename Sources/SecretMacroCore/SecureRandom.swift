//
//  SecureRandom.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

protocol RandomByteGenerating {
    func bytes(count: Int) -> [UInt8]
}

private struct SystemRandomByteGenerator: RandomByteGenerating {
    func bytes(count: Int) -> [UInt8] {
        var rng = SystemRandomNumberGenerator()
        return (0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max, using: &rng) }
    }
}

public enum SecureRandom {
    nonisolated(unsafe) static var generator: RandomByteGenerating = SystemRandomByteGenerator()

    public static func bytes(count: Int) -> [UInt8] {
        generator.bytes(count: count)
    }
}
