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
    
    var body: some Scene {
        WindowGroup {
            if authManager.isSignedIn {
                ContentView()
                    .environment(authManager)
            } else {
                LoginView(authManager: authManager)
            }
        }
    }
}
