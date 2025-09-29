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
        #if DEBUG
        // Use a different project token for debug builds if needed
        let token = "YOUR_DEBUG_MIXPANEL_TOKEN"
        #else
        let token = "YOUR_PRODUCTION_MIXPANEL_TOKEN"
        #endif

        // Initialize Mixpanel and get the main instance
        Mixpanel.initialize(
            token: token,
            trackAutomaticEvents: false // We'll track events manually
        )
        mixpanel = Mixpanel.mainInstance()

        logDebug("Mixpanel initialized", category: .analytics)
    }

    // MARK: - User Management

    func identifyUser(_ userId: String) {
        mixpanel?.identify(distinctId: userId)
        logDebug("User identified: \(userId)", category: .analytics)
    }

    func setUserProperties(_ properties: [String: MixpanelType]) {
        mixpanel?.people.set(properties: properties)
    }

    // MARK: - Event Tracking

    func track(event: String, properties: [String: MixpanelType] = [:]) {
        mixpanel?.track(event: event, properties: properties)
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
        mixpanel?.flush()
    }
}


