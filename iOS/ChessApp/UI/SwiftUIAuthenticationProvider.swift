//
//  SwiftUIAuthenticationProvider.swift
//  ChessApp
//
//  SwiftUI implementation of AuthenticationUIProvider
//  Handles UI presentation for authentication flows
//

import SwiftUI
import UIKit
import GoogleSignIn

/// SwiftUI implementation of AuthenticationUIProvider
/// This class handles all UI-related authentication concerns
@MainActor
class SwiftUIAuthenticationProvider: AuthenticationUIProvider {

    // MARK: - AuthenticationUIProvider Implementation

    func presentGoogleSignIn(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        Task {
            do {
                guard let presentingViewController = await getRootViewController() else {
                    completion(.failure(AuthenticationError.noUIProvider))
                    return
                }

                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                        if let error = error {
                            completion(.failure(error))
                        } else if let googleUser = result?.user {
                            completion(.success(googleUser))
                        } else {
                            completion(.failure(AuthenticationError.unknown("Failed to get user information")))
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }

    func presentError(_ message: String) {
        Task {
            guard let rootViewController = await getRootViewController() else {
                Logger.error("Cannot present error alert: no root view controller", category: Logger.ui)
                return
            }

            let alert = UIAlertController(
                title: "Authentication Error",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .default))

            rootViewController.present(alert, animated: true)
        }
    }

    // MARK: - Private Helper Methods

    private func getRootViewController() async -> UIViewController? {
        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                Logger.error("Cannot find root view controller", category: Logger.ui)
                return nil
            }
            return window.rootViewController
        }
    }
}

// MARK: - SwiftUI Environment Integration

/// Environment key for authentication UI provider
private struct AuthenticationUIProviderKey: EnvironmentKey {
    static let defaultValue: SwiftUIAuthenticationProvider = SwiftUIAuthenticationProvider()
}

extension EnvironmentValues {
    var authenticationUIProvider: SwiftUIAuthenticationProvider {
        get { self[AuthenticationUIProviderKey.self] }
        set { self[AuthenticationUIProviderKey.self] = newValue }
    }
}

// MARK: - View Modifier for Easy Integration

struct AuthenticationUIProviderModifier: ViewModifier {
    let authenticationManager: AuthenticationManager
    let provider = SwiftUIAuthenticationProvider()

    func body(content: Content) -> some View {
        content
            .environment(\.authenticationUIProvider, provider)
            .onAppear {
                // Inject the UI provider into the authentication manager
                authenticationManager.uiProvider = provider
            }
    }
}

extension View {
    /// Configures authentication UI provider for this view hierarchy
    func withAuthenticationUI(_ authenticationManager: AuthenticationManager) -> some View {
        self.modifier(AuthenticationUIProviderModifier(authenticationManager: authenticationManager))
    }
}