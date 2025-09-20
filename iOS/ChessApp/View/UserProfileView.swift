//
//  UserProfileView.swift
//  ChessApp
//
//  Created by Claude on 9/10/25.
//

import SwiftUI

struct UserProfileView: View {
    @Bindable var authManager: AuthenticationManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        HStack {
            // Profile image placeholder or user initial
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
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
                
                if !authManager.userEmail.isEmpty {
                    Text(authManager.userEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Menu {
                Button("Settings") {
                    // Handle settings
                }
                
                if authManager.user != nil {
                    // Signed in with Google - show Sign Out
                    Button("Sign Out", role: .destructive) {
                        showingSignOutAlert = true
                    }
                } else {
                    // Guest user - show Sign In
                    Button("Sign In with Google") {
                        authManager.signOut() // Reset to show login screen
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    UserProfileView(authManager: AuthenticationManager())
        .padding()
}
