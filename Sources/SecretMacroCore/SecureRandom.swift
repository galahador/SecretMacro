//
//  SecureRandom.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

public enum SecureRandom {
    public nonisolated(unsafe) static var bytesProvider: (Int) -> [UInt8] = { count in
        var generator = SystemRandomNumberGenerator()
        return (0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max, using: &generator) }
    }

    public static func bytes(count: Int) -> [UInt8] {
        bytesProvider(count)
    }
}
