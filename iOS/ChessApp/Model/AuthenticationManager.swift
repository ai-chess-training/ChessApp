//
//  AuthenticationManager.swift
//  ChessApp
//
//  Created by Claude on 9/10/25.
//

import Foundation
import GoogleSignIn
import AuthenticationServices

struct AppUser: Sendable {
    let name: String
    let email: String
    let imageURL: String?
    let isGuest: Bool
    let authProvider: AuthProvider

    enum AuthProvider: String, Sendable {
        case google = "google"
        case apple = "apple"
        case guest = "guest"
    }

    init(name: String, email: String, imageURL: String?, isGuest: Bool, authProvider: AuthProvider = .guest) {
        self.name = name
        self.email = email
        self.imageURL = imageURL
        self.isGuest = isGuest
        self.authProvider = authProvider
    }

    init(from googleUser: GIDGoogleUser) {
        self.name = googleUser.profile?.name ?? "Unknown"
        self.email = googleUser.profile?.email ?? ""
        self.imageURL = googleUser.profile?.imageURL(withDimension: 100)?.absoluteString
        self.isGuest = false
        self.authProvider = .google
    }

    init(from appleIDCredential: ASAuthorizationAppleIDCredential) {

        let fullName = appleIDCredential.fullName
        let displayName: String

        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        } else if let givenName = fullName?.givenName {
            displayName = givenName
        } else if let email = appleIDCredential.email, !email.isEmpty {
            displayName = email
        } else {
            displayName = "Apple User"
        }


        self.name = displayName
        self.email = appleIDCredential.email ?? ""
        self.imageURL = nil // Apple doesn't provide profile images
        self.isGuest = false
        self.authProvider = .apple
    }

    static let guest = AppUser(name: "Guest", email: "", imageURL: nil, isGuest: true, authProvider: .guest)
}

@MainActor @Observable
class AuthenticationManager {
    var isSignedIn = false
    var user: AppUser?
    var errorMessage: String?

    // UI provider for handling presentation (injected from UI layer)
    weak var uiProvider: AuthenticationUIProvider?

    init() {
        if FeatureFlags.isGoogleLoginEnabled {
            configureGoogleSignIn()
        }
        checkAuthenticationStatus()
    }

    nonisolated private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            Task { @MainActor in
                self.errorMessage = "Could not find GoogleService-Info.plist or CLIENT_ID"
            }
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }

    func signInWithGoogle() {
        guard let uiProvider = uiProvider else {
            self.errorMessage = AuthenticationError.noUIProvider.localizedDescription
            return
        }

        uiProvider.presentGoogleSignIn { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let googleUser):
                let appUser = AppUser(from: googleUser)
                self.user = appUser
                self.isSignedIn = true
                self.errorMessage = nil

            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.isSignedIn = false
            }
        }
    }

    func signInWithApple() {
        guard let uiProvider = uiProvider else {
            self.errorMessage = AuthenticationError.noUIProvider.localizedDescription
            return
        }

        uiProvider.presentAppleSignIn { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let authorization):
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

                    // Store Apple user info (important: only available on first sign-in)
                    self.storeAppleUserInfo(appleIDCredential)

                    // Try to use stored data first, then fall back to credential data
                    var appUser = AppUser(from: appleIDCredential)

                    // If the credential doesn't have name/email (subsequent sign-ins), use stored data
                    if appUser.name == "Apple User", let storedUser = self.getStoredAppleUserInfo() {
                        appUser = storedUser
                    }


                    self.user = appUser
                    self.isSignedIn = true
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Invalid Apple ID credential"
                    self.isSignedIn = false
                }

            case .failure(let error):
                // Handle Apple Sign-In cancellation gracefully
                if let authError = error as? ASAuthorizationError {
                    switch authError.code {
                    case .canceled:
                        // User canceled - don't show error message
                        self.errorMessage = nil
                    case .unknown, .invalidResponse, .notHandled, .failed:
                        self.errorMessage = "Apple Sign-In failed. Please try again."
                    @unknown default:
                        self.errorMessage = "Apple Sign-In failed. Please try again."
                    }
                } else {
                    self.errorMessage = error.localizedDescription
                }
                self.isSignedIn = false
            }
        }
    }

    private func storeAppleUserInfo(_ credential: ASAuthorizationAppleIDCredential) {
        let userDefaults = UserDefaults.standard


        // Always store the user ID
        userDefaults.set(credential.user, forKey: "apple_user_id")

        // Store email and name if provided (first sign-in only)
        if let email = credential.email, !email.isEmpty {
            userDefaults.set(email, forKey: "apple_user_email")
        } else {
        }

        if let fullName = credential.fullName {
            if let givenName = fullName.givenName {
                userDefaults.set(givenName, forKey: "apple_user_given_name")
            }
            if let familyName = fullName.familyName {
                userDefaults.set(familyName, forKey: "apple_user_family_name")
            }
        } else {
        }

    }


    func signOut() {
        // Sign out from Google if enabled and user is signed in with Google
        if FeatureFlags.isGoogleLoginEnabled && user?.authProvider == .google {
            GIDSignIn.sharedInstance.signOut()
        }

        // For Apple ID, we clear stored user info
        if user?.authProvider == .apple {
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: "apple_user_id")
            userDefaults.removeObject(forKey: "apple_user_email")
            userDefaults.removeObject(forKey: "apple_user_given_name")
            userDefaults.removeObject(forKey: "apple_user_family_name")
        }

        user = nil
        isSignedIn = false
    }

    func signInAsGuest() {
        user = .guest
        isSignedIn = true
        errorMessage = nil
    }

    nonisolated private func checkAuthenticationStatus() {
        // Check for Google user if Google login is enabled
        if FeatureFlags.isGoogleLoginEnabled {
            if let googleUser = GIDSignIn.sharedInstance.currentUser {
                let appUser = AppUser(from: googleUser)
                Task { @MainActor in
                    self.user = appUser
                    self.isSignedIn = true
                }
                return
            }
        }

        // Check for stored Apple user
        if let storedAppleUser = getStoredAppleUserInfo() {
            Task { @MainActor in
                self.user = storedAppleUser
                self.isSignedIn = true
            }
        }
    }


    var userName: String {
        return user?.name ?? "Guest"
    }

    var userEmail: String {
        return user?.email ?? ""
    }

    var userProfileImageURL: String? {
        return user?.imageURL
    }

    // MARK: - Apple User Info Helpers

    nonisolated func getStoredAppleUserInfo() -> AppUser? {
        let userDefaults = UserDefaults.standard

        // Check if we have stored Apple user data
        guard userDefaults.string(forKey: "apple_user_id") != nil else {
            return nil
        }

        let email = userDefaults.string(forKey: "apple_user_email") ?? ""
        let givenName = userDefaults.string(forKey: "apple_user_given_name")
        let familyName = userDefaults.string(forKey: "apple_user_family_name")

        // Construct full name
        let fullName: String
        if let given = givenName, let family = familyName {
            fullName = "\(given) \(family)"
        } else if let given = givenName {
            fullName = given
        } else {
            fullName = email.isEmpty ? "Apple User" : email
        }

        return AppUser(
            name: fullName,
            email: email,
            imageURL: nil, // Apple doesn't provide profile images
            isGuest: false,
            authProvider: .apple
        )
    }

    func getAppleUserUniqueID() -> String? {
        return UserDefaults.standard.string(forKey: "apple_user_id")
    }
}
