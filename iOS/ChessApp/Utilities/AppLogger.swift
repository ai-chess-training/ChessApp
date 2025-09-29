//
//  AppLogger.swift
//  ChessApp
//
//  Improved logging architecture with better patterns
//  Created by Claude on 9/24/25.
//

import Foundation
import os.log

// MARK: - Log Level

public enum LogLevel: Int, CaseIterable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }

    var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

// MARK: - Log Category

public enum LogCategory: String, CaseIterable, Sendable {
    case game = "Game"
    case coaching = "Coaching"
    case api = "API"
    case ui = "UI"
    case analytics = "Analytics"
    case auth = "Authentication"
    case network = "Network"

    var identifier: String { rawValue }
}

// MARK: - App Logger

@available(iOS 14.0, *)
public actor AppLogger {
    public static let shared = AppLogger()

    private let subsystem: String
    private let loggers: [LogCategory: Logger]
    private var minimumLogLevel: LogLevel

    private init() {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.chessapp"
        self.subsystem = bundleId
        self.loggers = Dictionary(uniqueKeysWithValues:
            LogCategory.allCases.map { category in
                (category, Logger(subsystem: bundleId, category: category.identifier))
            }
        )

        // Set minimum log level based on build configuration
        #if DEBUG
        self.minimumLogLevel = .debug
        #else
        self.minimumLogLevel = .info
        #endif
    }

    // MARK: - Configuration

    public func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }

    // MARK: - Logging Methods

    public func log(
        _ level: LogLevel,
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLogLevel else { return }

        let logger = loggers[category] ?? loggers[.game]!
        let fileName = (file as NSString).lastPathComponent

        #if DEBUG
        let enrichedMessage = "\(level.emoji) [\(fileName):\(function):\(line)] \(message)"
        #else
        let enrichedMessage = "\(level.emoji) \(message)"
        #endif

        logger.log(level: level.osLogType, "\(enrichedMessage, privacy: .public)")
    }

    // MARK: - Convenience Methods

    public func debug(
        _ message: String,
        category: LogCategory = .game,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, category: category, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        category: LogCategory = .game,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, category: category, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        category: LogCategory = .game,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message, category: category, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        category: LogCategory = .game,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message, category: category, file: file, function: function, line: line)
    }
}

// MARK: - Fallback for iOS 13 and below

@available(iOS, deprecated: 14.0, message: "Use AppLogger instead")
public struct LegacyLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.chessapp"

    public static func debug(_ message: String, category: String = "Game") {
        #if DEBUG
        print("🐛 [\(category)] \(message)")
        #endif
    }

    public static func info(_ message: String, category: String = "Game") {
        print("ℹ️ [\(category)] \(message)")
    }

    public static func warning(_ message: String, category: String = "Game") {
        print("⚠️ [\(category)] \(message)")
    }

    public static func error(_ message: String, category: String = "Game") {
        print("❌ [\(category)] \(message)")
    }
}

// MARK: - Global Convenience Functions

@available(iOS 14.0, *)
public func logDebug(
    _ message: String,
    category: LogCategory = .game,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Task { @Sendable in
        await AppLogger.shared.debug(message, category: category, file: file, function: function, line: line)
    }
}

@available(iOS 14.0, *)
public func logInfo(
    _ message: String,
    category: LogCategory = .game,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Task { @Sendable in
        await AppLogger.shared.info(message, category: category, file: file, function: function, line: line)
    }
}

@available(iOS 14.0, *)
public func logWarning(
    _ message: String,
    category: LogCategory = .game,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Task { @Sendable in
        await AppLogger.shared.warning(message, category: category, file: file, function: function, line: line)
    }
}

@available(iOS 14.0, *)
public func logError(
    _ message: String,
    category: LogCategory = .game,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Task { @Sendable in
        await AppLogger.shared.error(message, category: category, file: file, function: function, line: line)
    }
}