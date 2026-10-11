//
//  EntropyCalculator.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation

enum EntropyCalculator {
    static func isHighEntropy(_ string: String,
                              lengthThreshold: Int = 20,
                              entropyThreshold: Double = 4.0) -> Bool {
        
        guard string.count >= lengthThreshold,
            string.allSatisfy({ $0.isASCII && !$0.isWhitespace }) else {
            return false
        }
        return shannonEntropy(of: string) >= entropyThreshold
    }

    static func shannonEntropy(of string: String) -> Double {
        guard !string.isEmpty else { return 0 }
        var frequencies: [Character: Int] = [:]
        for character in string {
            frequencies[character, default: 0] += 1
        }
        let length = Double(string.count)
        return frequencies.values.reduce(into: 0.0) { entropy, count in
            let probability = Double(count) / length
            entropy -= probability * log2(probability)
        }
    }
}
