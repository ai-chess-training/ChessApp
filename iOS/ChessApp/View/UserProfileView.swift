//
//  UserProfileView.swift
//  ChessApp
//
//  Created by Claude on 9/10/25.
//

import SwiftUI

struct UserProfileView: View {
    @Bindable var authManager: AuthenticationManager
    let gameState: ChessGameState
    @State private var showingSignOutAlert = false
    @State private var showingSettings = false
    @Environment(AppTheme.self) private var theme

    var body: some View {
        HStack {
            // Profile image with user initial
            Circle()
                .fill(theme.primaryColor.gradient)
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(authManager.userName.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.userName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Menu {
                Button("Settings") {
                    showingSettings = true
                }

                if let appuser = authManager.user, !appuser.isGuest  {
                    // Signed in with Google - show Sign Out
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
        }
        .cornerRadius(12)
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

#Preview {
    UserProfileView(authManager: AuthenticationManager(), gameState: ChessGameState())
        .padding()
}
