//
//  LoginView.swift
//  ChessApp
//
//  Created by Claude on 9/10/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 30) {
            // App Logo/Title
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("ChessApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Play chess with friends around the world")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            SignInSection(authManager: authManager)
            
            Spacer()
        }
        .padding()
    }
}

struct SignInSection: View {
    @Bindable var authManager: AuthenticationManager

    var body: some View {
        VStack {
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            AppleSignInButton {
                authManager.signInWithApple()
            }

            if FeatureFlags.isGoogleLoginEnabled {
                GoogleSignInButton {
                    authManager.signInWithGoogle()
                }
            }

            Text("Or continue as guest")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Continue as Guest") {
                authManager.signInAsGuest()
            }
            .buttonStyle(.bordered)
        }
        .padding()

        Text("Sign in to save your games and track your progress")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

struct AppleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "applelogo")
                    .foregroundColor(.white)

                Text("Sign in with Apple")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct GoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                
                Text("Sign in with Google")
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let authManager = AuthenticationManager()
    LoginView(authManager: authManager)
        .withAuthenticationUI(authManager)
}
