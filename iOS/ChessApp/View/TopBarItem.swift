//
//  TopBarItem.swift
//  ChessApp
//
//  Created by Claude on 9/10/25.
//

import SwiftUI

// MARK: - Reset Game Button
struct ResetGameButtonView: View {
    let gameState: ChessGameState
    @State private var showingResetAlert = false
    @Environment(AppTheme.self) private var theme

    var body: some View {
        Button(action: {
            showingResetAlert = true
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.body)
                .foregroundColor(theme.primaryColor)
        }
        .alert("Reset Game", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                gameState.resetGame()
            }
        } message: {
            Text("Are you sure you want to reset the game? Your current progress will be lost.")
        }
    }
}

// MARK: - Resign Game Button
struct ResignGameButtonView: View {
    let gameState: ChessGameState
    @State private var showingResignAlert = false

    var body: some View {
        Button(action: {
            showingResignAlert = true
        }) {
            Image(systemName: "flag.fill")
                .font(.body)
                .foregroundColor(.red)
        }
        .alert("Resign Game", isPresented: $showingResignAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Resign", role: .destructive) {
                gameState.resignGame()
            }
        } message: {
            Text("Are you sure you want to resign? The opponent will win.")
        }
    }
}

// MARK: - Settings Menu
struct SettingsMenuView: View {
    @Bindable var authManager: AuthenticationManager
    let gameState: ChessGameState
    @State private var showingSignOutAlert = false
    @State private var showingSettings = false

    var body: some View {
        Menu {
            Button("Settings") {
                showingSettings = true
            }

            if let appuser = authManager.user, !appuser.isGuest  {
                // Signed in with Apple - show Sign Out
                Button("Sign Out", role: .destructive) {
                    showingSignOutAlert = true
                }
            } else {
                // Guest user - show Sign In
                Button("Sign In") {
                    authManager.signOut() // Reset to show login screen
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(gameState: gameState)
        }
    }
}

