//
//  SecretPatternMatcher.swift
//  SecretMacro
//
//  Created by tBug on 2026-10-11.
//

import Foundation

enum SecretPatternMatcher {
    private static let patterns: [(label: String, regex: NSRegularExpression)] = [
        ("AWS Access Key", #"AKIA[0-9A-Z]{16}"#), /// Need to check this patern, hmmm ( this is from forum... ) i want to test on device
        ("Generic secret assignment", #"(?i)(api[_-]?key|secret|token|password)\s*[=:]\s*['"]?[A-Za-z0-9_\-]{8,}"#),
        ("Bearer token", #"Bearer [A-Za-z0-9\-_.]{10,}"#),
        ("JWT", #"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"#),
        ("Private key header", #"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"#)].compactMap { label, pattern in
            (try? NSRegularExpression(pattern: pattern)).map { (label, $0) }
        }
    
    struct Match {
        let line: String
        let reason: String
    }
    
    static func suspiciousStrings(in lines: [String],
                                  ignoring ignoredSubstrings: [String] = []) -> [Match] {
        lines.compactMap { line in
            guard !ignoredSubstrings.contains(where: line.contains) else { return nil }
            
            for (label, regex) in patterns {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if regex.firstMatch(in: line, range: range) != nil {
                    return Match(line: line, reason: label)
                }
            }
            
            if EntropyCalculator.isHighEntropy(line) {
                return Match(line: line, reason: "high-entropy string")
            }
            
            return nil
        }
    }
}
