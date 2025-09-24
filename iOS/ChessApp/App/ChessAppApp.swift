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

    init() {
        // Initialize analytics on app launch
        _ = AnalyticsManager.shared
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isSignedIn {
                ContentView()
                    .environment(authManager)
                    .withAuthenticationUI(authManager)
            } else {
                LoginView(authManager: authManager)
                    .withAuthenticationUI(authManager)
            }
        }
    }
}
