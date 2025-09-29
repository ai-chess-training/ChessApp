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
        // Get Mixpanel token from environment variables (CI/CD builds) or bundle (local development)
        let token = getMixpanelToken()

        guard !token.isEmpty else {
            logError("Mixpanel token not configured - analytics disabled", category: .analytics)
            mixpanel = nil
            return
        }

        // Initialize Mixpanel and get the main instance
        Mixpanel.initialize(
            token: token,
            trackAutomaticEvents: false // We'll track events manually
        )
        mixpanel = Mixpanel.mainInstance()

        logDebug("Mixpanel initialized with secure token", category: .analytics)
    }

    // MARK: - Private Token Management

    private func getMixpanelToken() -> String {
        // Priority 1: Environment variables (CI/CD builds)
        #if DEBUG
        if let envToken = ProcessInfo.processInfo.environment["MIXPANEL_DEBUG_TOKEN"], !envToken.isEmpty {
            logDebug("Using Mixpanel debug token from environment", category: .analytics)
            return envToken
        }
        #else
        if let envToken = ProcessInfo.processInfo.environment["MIXPANEL_PROD_TOKEN"], !envToken.isEmpty {
            logDebug("Using Mixpanel production token from environment", category: .analytics)
            return envToken
        }
        #endif

        // Priority 2: Bundle Info.plist (local development fallback)
        #if DEBUG
        if let bundleToken = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_DEBUG_TOKEN") as? String, !bundleToken.isEmpty {
            logDebug("Using Mixpanel debug token from bundle", category: .analytics)
            return bundleToken
        }
        #else
        if let bundleToken = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_PROD_TOKEN") as? String, !bundleToken.isEmpty {
            logDebug("Using Mixpanel production token from bundle", category: .analytics)
            return bundleToken
        }
        #endif

        logError("No Mixpanel token found in environment or bundle", category: .analytics)
        return ""
    }

    // MARK: - User Management

    func identifyUser(_ userId: String) {
        guard let mixpanel = mixpanel else {
            logDebug("Analytics disabled - skipping user identification", category: .analytics)
            return
        }
        mixpanel.identify(distinctId: userId)
        logDebug("User identified: \(userId)", category: .analytics)
    }

    func setUserProperties(_ properties: [String: MixpanelType]) {
        guard let mixpanel = mixpanel else {
            logDebug("Analytics disabled - skipping user properties", category: .analytics)
            return
        }
        mixpanel.people.set(properties: properties)
    }

    // MARK: - Event Tracking

    func track(event: String, properties: [String: MixpanelType] = [:]) {
        guard let mixpanel = mixpanel else {
            logDebug("Analytics disabled - skipping event: \(event)", category: .analytics)
            return
        }
        mixpanel.track(event: event, properties: properties)
        logDebug("Event tracked: \(event)", category: .analytics)
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

    func trackMoveMade(moveNumber: Int, piece: PieceType, isCapture: Bool) {
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

    func trackUserSignIn(provider: AppUser.AuthProvider) {
        track(event: "User Sign In", properties: [
            "auth_provider": provider.rawValue
        ])
    }

    func trackUserSignOut() {
        track(event: "User Sign Out")
    }

    // MARK: - Utility

    func flush() {
        guard let mixpanel = mixpanel else {
            logDebug("Analytics disabled - skipping flush", category: .analytics)
            return
        }
        mixpanel.flush()
        logDebug("Analytics data flushed", category: .analytics)
    }
}


