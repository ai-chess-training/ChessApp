//
//  AnalyticsManager.swift
//  ChessApp
//
//  Created by Claude on 9/24/25.
//

import Foundation
import Mixpanel

actor AnalyticsManager {
    static let shared = AnalyticsManager()

    private var mixpanel: MixpanelInstance?

    private init() {
        setupMixpanel()
    }

    private func setupMixpanel() {
        #if DEBUG
        // Use a different project token for debug builds if needed
        let token = "YOUR_DEBUG_MIXPANEL_TOKEN"
        #else
        let token = "YOUR_PRODUCTION_MIXPANEL_TOKEN"
        #endif

        mixpanel = Mixpanel.initialize(
            token: token,
            trackAutomaticEvents: false // We'll track events manually
        )

        Logger.debug("Mixpanel initialized", category: Logger.analytics)
    }

    // MARK: - User Management

    func identifyUser(_ userId: String) {
        mixpanel?.identify(distinctId: userId)
        Logger.debug("User identified: \(userId)", category: Logger.analytics)
    }

    func setUserProperties(_ properties: [String: Any]) {
        mixpanel?.people.set(properties: properties)
    }

    // MARK: - Event Tracking

    func track(event: String, properties: [String: Any] = [:]) {
        mixpanel?.track(event: event, properties: properties)
        Logger.debug("Event tracked: \(event)", category: Logger.analytics)
    }

    // MARK: - Chess App Specific Events

    func trackGameStarted(mode: GameMode, skillLevel: SkillLevel) {
        track(event: "Game Started", properties: [
            "game_mode": mode.rawValue,
            "skill_level": skillLevel.rawValue,
            "coaching_enabled": true // Always true now
        ])
    }

    func trackGameEnded(winner: ChessColor?, moveCount: Int, duration: TimeInterval) {
        track(event: "Game Ended", properties: [
            "winner": winner?.rawValue ?? "draw",
            "move_count": moveCount,
            "duration_seconds": Int(duration)
        ])
    }

    func trackMoveMade(moveNumber: Int, piece: ChessPieceType, isCapture: Bool) {
        track(event: "Move Made", properties: [
            "move_number": moveNumber,
            "piece_type": piece.rawValue,
            "is_capture": isCapture
        ])
    }

    func trackCoachingFeedbackReceived(severity: String, moveNumber: Int) {
        track(event: "Coaching Feedback Received", properties: [
            "severity": severity,
            "move_number": moveNumber
        ])
    }

    func trackSkillLevelChanged(from: SkillLevel, to: SkillLevel) {
        track(event: "Skill Level Changed", properties: [
            "from_level": from.rawValue,
            "to_level": to.rawValue
        ])
    }

    func trackUserSignIn(provider: AuthProvider) {
        track(event: "User Sign In", properties: [
            "auth_provider": provider.rawValue
        ])
    }

    func trackUserSignOut() {
        track(event: "User Sign Out")
    }

    // MARK: - Utility

    func flush() {
        mixpanel?.flush()
    }
}

// MARK: - Logger Extension

extension Logger {
    static let analytics = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Analytics")
}