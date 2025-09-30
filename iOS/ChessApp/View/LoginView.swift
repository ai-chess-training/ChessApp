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
                
                Text("Chess Mentor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Play chess with the best mentor in the world!")
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
            .padding()

            if FeatureFlags.isGoogleLoginEnabled {
                GoogleSignInButton {
                    authManager.signInWithGoogle()
                }
                .padding()
            }

            GuestSignInButton {
                authManager.signInAsGuest()
            }
            .padding()
        }
        .frame(maxWidth: 500)
        .padding()

        Text("Sign in to track your progress.")
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
                    .font(.system(size: 18, weight: .medium))

                Text("Sign in with Apple")
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44) // Apple's recommended height
            .padding(.horizontal, 16)
            .foregroundColor(Color(.systemBackground))
            .background(.primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("apple_signin_button")
    }
}

struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "globe")//If enable G login, need change the icon
                    .foregroundColor(.blue)

                Text("Sign in with Google")
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("google_signin_button")
    }
}

struct GuestSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.secondary)

                Text("Continue as Guest")
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("guest_signin_button")
    }
}

#Preview {
    let authManager = AuthenticationManager()
    LoginView(authManager: authManager)
        .withAuthenticationUI(authManager)
}
