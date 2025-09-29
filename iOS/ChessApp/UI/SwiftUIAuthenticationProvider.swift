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
import AuthenticationServices

/// SwiftUI implementation of AuthenticationUIProvider
/// This class handles all UI-related authentication concerns
@MainActor
class SwiftUIAuthenticationProvider: NSObject, AuthenticationUIProvider {

    // Apple Sign-In completion handler
    private var appleSignInCompletion: ((Result<ASAuthorization, Error>) -> Void)?

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

    func presentAppleSignIn(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        // Store completion handler for delegate callbacks
        self.appleSignInCompletion = completion

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func presentError(_ message: String) {
        Task {
            guard let rootViewController = await getRootViewController() else {
                logError("Cannot present error alert: no root view controller", category: .ui)
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
                logError("Cannot find root view controller", category: .ui)
                return nil
            }
            return window.rootViewController
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension SwiftUIAuthenticationProvider: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            appleSignInCompletion?(.success(authorization))
            appleSignInCompletion = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            appleSignInCompletion?(.failure(error))
            appleSignInCompletion = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SwiftUIAuthenticationProvider: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - SwiftUI Environment Integration

/// Environment key for authentication UI provider
private struct AuthenticationUIProviderKey: EnvironmentKey {
    nonisolated static let defaultValue: SwiftUIAuthenticationProvider = {
        MainActor.assumeIsolated {
            SwiftUIAuthenticationProvider()
        }
    }()
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
