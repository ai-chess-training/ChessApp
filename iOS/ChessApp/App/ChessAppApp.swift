//
//  ChessAppApp.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

@main
struct ChessAppApp: App {
    @State private var authManager = AuthenticationManager()
    @State private var appTheme = AppTheme.shared

    init() {
        if FeatureFlags.isAnalyticsEnabled {
            // Initialize analytics on app launch
            _ = AnalyticsManager.shared
        }
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isSignedIn {
                ContentView()
                    .environment(authManager)
                    .environment(appTheme)
                    .withAuthenticationUI(authManager)
            } else {
                LoginView(authManager: authManager)
                    .environment(appTheme)
                    .withAuthenticationUI(authManager)
            }
        }
    }
}
