//
//  AuthenticationManager.swift
//  ChessApp
//
//  Created by Claude on 9/10/25.
//

import Foundation
import GoogleSignIn
import SwiftUI
import UIKit

struct AppUser: Sendable {
    let name: String
    let email: String
    let imageURL: String?
    let isGuest: Bool

    init(name: String, email: String, imageURL: String?, isGuest: Bool) {
        self.name = name
        self.email = email
        self.imageURL = imageURL
        self.isGuest = isGuest
    }

    init(from googleUser: GIDGoogleUser) {
        self.name = googleUser.profile?.name ?? "Unknown"
        self.email = googleUser.profile?.email ?? ""
        self.imageURL = googleUser.profile?.imageURL(withDimension: 100)?.absoluteString
        self.isGuest = false
    }

    static let guest = AppUser(name: "Guest", email: "", imageURL: nil, isGuest: true)
}

@MainActor @Observable
class AuthenticationManager {
    var isSignedIn = false
    var user: AppUser?
    var errorMessage: String?

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

    func signIn() {
        Task {
            guard let presentingViewController = await getRootViewController() else {
                self.errorMessage = "Could not find presenting view controller"
                return
            }

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                    if let error = error {
                        Task { @MainActor in
                            self.errorMessage = error.localizedDescription
                            continuation.resume()
                        }
                    } else if let googleUser = result?.user {
                        let appUser = AppUser(from: googleUser)
                        Task { @MainActor in
                            self.user = appUser
                            self.isSignedIn = true
                            self.errorMessage = nil
                            continuation.resume()
                        }
                    } else {
                        Task { @MainActor in
                            self.errorMessage = "Failed to get user information"
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }

    nonisolated private func getRootViewController() async -> UIViewController? {
        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return nil
            }
            return window.rootViewController
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
