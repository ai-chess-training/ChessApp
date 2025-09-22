//
//  Logger.swift
//  ChessApp
//
//  Logging utility that only outputs in debug builds
//

import Foundation
import os.log

enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.chessapp"

    // Different log categories for better organization
    static let game = OSLog(subsystem: subsystem, category: "Game")
    static let coaching = OSLog(subsystem: subsystem, category: "Coaching")
    static let api = OSLog(subsystem: subsystem, category: "API")
    static let ui = OSLog(subsystem: subsystem, category: "UI")

    // Debug logging that only appears in debug builds
    static func debug(_ message: String, category: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        os_log("%{public}@:%{public}@:%d - %{public}@", log: category, type: .debug, fileName, function, line, message)
        #endif
    }

    // Info logging for important events (appears in debug and release)
    static func info(_ message: String, category: OSLog = .default) {
        os_log("%{public}@", log: category, type: .info, message)
    }

    // Error logging (always appears)
    static func error(_ message: String, category: OSLog = .default) {
        os_log("%{public}@", log: category, type: .error, message)
    }

    // Warning logging (always appears)
    static func warning(_ message: String, category: OSLog = .default) {
        os_log("%{public}@", log: category, type: .default, message)
    }
}