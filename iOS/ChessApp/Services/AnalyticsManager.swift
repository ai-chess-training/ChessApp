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
        var token = ""
        var tokenSource = ""

        // Priority 1: Environment variables (CI/CD builds)
        #if DEBUG
        if let envToken = ProcessInfo.processInfo.environment["MIXPANEL_DEBUG_TOKEN"], !envToken.isEmpty {
            token = envToken
            tokenSource = "environment (debug)"
        }
        #else
        if let envToken = ProcessInfo.processInfo.environment["MIXPANEL_PROD_TOKEN"], !envToken.isEmpty {
            token = envToken
            tokenSource = "environment (production)"
        }
        #endif

        // Priority 2: Bundle Info.plist (local development fallback)
        if token.isEmpty {
            #if DEBUG
            if let bundleToken = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_DEBUG_TOKEN") as? String, !bundleToken.isEmpty {
                token = bundleToken
                tokenSource = "bundle (debug)"
            }
            #else
            if let bundleToken = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_PROD_TOKEN") as? String, !bundleToken.isEmpty {
                token = bundleToken
                tokenSource = "bundle (production)"
            }
            #endif
        }

        // Initialize based on token availability
        if token.isEmpty {
            logError("No Mixpanel token found in environment or bundle - analytics disabled", category: .analytics)
            self.mixpanel = nil
        } else {
            // Initialize Mixpanel and get the main instance
            Mixpanel.initialize(
                token: token,
                trackAutomaticEvents: false // We'll track events manually
            )
            self.mixpanel = Mixpanel.mainInstance()
            logDebug("Mixpanel initialized with secure token from \(tokenSource)", category: .analytics)
        }
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


