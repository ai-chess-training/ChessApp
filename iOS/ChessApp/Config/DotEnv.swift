//
//  DotEnv.swift
//  ChessApp
//
//  Loads environment variables from .env file
//

import Foundation

struct DotEnv {
    static let shared = DotEnv()

    private var variables: [String: String] = [:]

    private init() {
        loadDotEnv()
    }

    /// Get an environment variable by key from .env file
    func get(_ key: String) -> String? {
        return variables[key]
    }

    /// Load variables from .env file in the app bundle
    private mutating func loadDotEnv() {
        // Try to find .env file in the app bundle
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: "") else {
            // .env file not found - this is OK for release builds
            // App will fall back to other configuration methods
            return
        }

        do {
            let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
            parseEnvContent(envContent)
        } catch {
            print("Warning: Failed to load .env file: \(error)")
        }
    }

    /// Parse .env file content
    /// Format: KEY=VALUE (one per line, supports comments with #)
    private mutating func parseEnvContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse KEY=VALUE
            let parts = trimmed.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else {
                continue
            }

            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

            variables[key] = value
        }
    }
}
