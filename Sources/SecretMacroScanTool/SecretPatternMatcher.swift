//
//  SecretPatternMatcher.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation

enum SecretPatternMatcher {
    private static let patterns: [(label: String, regex: NSRegularExpression)] = [
        ("AWS Access Key", #"AKIA[0-9A-Z]{16}"#),
        ("Generic secret assignment", #"(?i)(api[_-]?key|secret|token|password)\s*[=:]\s*['"]?[A-Za-z0-9_\-]{8,}"#),
        ("Bearer token", #"Bearer [A-Za-z0-9\-_.]{10,}"#),
        ("JWT", #"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"#),
        ("Private key header", #"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"#)
    ].compactMap { label, pattern in
        (try? NSRegularExpression(pattern: pattern)).map { (label, $0) }
    }

    struct Match {
        let offset: String
        let value: String
        let reason: String
    }

    static func suspiciousStrings(in strings: [BinaryStringScanner.FoundString], ignoring ignoredSubstrings: [String] = []) -> [Match] {
        strings.compactMap { found in
            guard !ignoredSubstrings.contains(where: found.value.contains) else { return nil }
            
            for (label, regex) in patterns {
                let range = NSRange(found.value.startIndex..<found.value.endIndex, in: found.value)
                if regex.firstMatch(in: found.value, range: range) != nil {
                    return Match(offset: found.offset, value: found.value, reason: label)
                }
            }
            
            if EntropyCalculator.isHighEntropy(found.value) {
                return Match(offset: found.offset, value: found.value, reason: "high-entropy string")
            }
            return nil
        }
    }
}
