//
//  AuthenticationUIProvider.swift
//  ChessApp
//
//  Protocol for providing UI presentation capabilities to AuthenticationManager
//  This separates UI concerns from business logic
//

import Foundation
import GoogleSignIn
import AuthenticationServices

/// Protocol that abstracts UI presentation for authentication
/// This allows the AuthenticationManager to remain UI-agnostic
@MainActor
protocol AuthenticationUIProvider: AnyObject {
    /// Present the Google Sign-In flow
    /// - Parameter completion: Called when sign-in completes with result or error
    func presentGoogleSignIn(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void)

    /// Present the Apple Sign-In flow
    /// - Parameter completion: Called when sign-in completes with result or error
    func presentAppleSignIn(completion: @escaping (Result<ASAuthorization, Error>) -> Void)

    /// Present an error alert to the user
    /// - Parameter message: The error message to display
    func presentError(_ message: String)
}

/// Result enum for authentication operations
enum AuthenticationError: LocalizedError {
    case noUIProvider
    case userCancelled
    case configurationMissing
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noUIProvider:
            return "No UI provider available for authentication"
        case .userCancelled:
            return "User cancelled sign-in"
        case .configurationMissing:
            return "Google Sign-In configuration missing"
        case .unknown(let message):
            return message
        }
    }
}