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
        // Apple provides limited info, use email as name if full name not available
        let fullName = appleIDCredential.fullName
        let displayName: String

        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        } else if let givenName = fullName?.givenName {
            displayName = givenName
        } else {
            displayName = appleIDCredential.email ?? "Apple User"
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
        configureGoogleSignIn()
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
        GIDSignIn.sharedInstance.restorePreviousSignIn { result, error in
            if let googleUser = result {
                let appUser = AppUser(from: googleUser)
                Task { @MainActor in
                    self.user = appUser
                    self.isSignedIn = true
                }
            }
        }
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
                    let appUser = AppUser(from: appleIDCredential)
                    self.user = appUser
                    self.isSignedIn = true
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Invalid Apple ID credential"
                    self.isSignedIn = false
                }

            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.isSignedIn = false
            }
        }
    }


    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
        isSignedIn = false
    }

    func signInAsGuest() {
        user = .guest
        isSignedIn = true
        errorMessage = nil
    }

    nonisolated private func checkAuthenticationStatus() {
        if let googleUser = GIDSignIn.sharedInstance.currentUser {
            let appUser = AppUser(from: googleUser)
            Task { @MainActor in
                self.user = appUser
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
}
