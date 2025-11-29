//
//  SettingsView.swift
//  ChessApp
//
//  App settings including Chess Coach API configuration
//

import SwiftUI

// MARK: - Constants
private struct APIPreset {
    static let presets: [(name: String, url: String)] = [
        ("Production", "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"),
        ("Local Dev", "http://localhost:8000")
    ]

    static let defaultURL = "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"
}

struct SettingsView: View {
    let gameState: ChessGameState
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ChessCoach.apiBaseURL") private var apiBaseURL: String = "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"
    @State private var originalAPIBaseURL: String = ""
    @AppStorage("ChessCoach.apiKey") private var apiKey: String = ""
    @State private var defaultSkillLevel: SkillLevel = .intermediate
    @AppStorage("ChessCoach.shouldShowHistory") private var shouldShowHistory: Bool = false
    @State private var showingSignOutAlert = false
    @State private var showingSkillLevelAlert = false
    @State private var pendingSkillLevel: SkillLevel?
    @State private var testingConnection = false
    @State private var connectionResult: String?
    @Environment(AppTheme.self) private var theme

    var body: some View {
        NavigationStack {
            Form {
                // User Info Section
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(theme.primaryColor.gradient)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(authManager.userName.prefix(1)).uppercased())
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.userName)
                                .font(.headline)
                                .foregroundColor(.primary)

                            if let appuser = authManager.user, !appuser.isGuest {
                                Text("Signed in with Apple")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Guest User")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    if let appuser = authManager.user, !appuser.isGuest {
                        Button("Sign Out", role: .destructive) {
                            showingSignOutAlert = true
                        }
                    } else {
                        Button("Sign In") {
                            authManager.signOut()
                        }
                    }
                } header: {
                    Label("Account", systemImage: "person.crop.circle")
                }

                // Chess Coach API Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Base URL")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter API base URL", text: $apiBaseURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Enter API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Quick URL presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Presets")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 12) {
                            ForEach(APIPreset.presets, id: \.url) { preset in
                                Button(action: {
                                    apiBaseURL = preset.url
                                }) {
                                    Text(preset.name)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(apiBaseURL == preset.url ? theme.primaryColor : .gray)
                            }
                        }
                    }

                } header: {
                    Label("Chess Coach API", systemImage: "brain")
                } footer: {
                    Text("Configure the Chess Coach backend server connection. Use localhost for local development or your Mac's IP address for testing on device.")
                }

                // Skill Level Section
                Section {
                    Picker("Skill Level", selection: Binding(
                        get: { defaultSkillLevel },
                        set: { newLevel in
                            handleSkillLevelChange(to: newLevel)
                        }
                    )) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                } header: {
                    Label("Skill Level", systemImage: "graduationcap")
                } footer: {
                    Text("Choose your preferred difficulty level for coaching.")
                }

                // Developer Settings Section
                Section {
                    Toggle("Show Move History", isOn: Binding(
                        get: { shouldShowHistory },
                        set: { newValue in
                            shouldShowHistory = newValue
                            gameState.shouldShowHistory = newValue
                        }
                    ))

                } header: {
                    Label("Developer", systemImage: "hammer")
                } footer: {
                    Text("Enable debug mode to show move history and additional development information during gameplay.")
                }

                // Connection Testing Section
                Section {
                    HStack {
                        Button(action: testConnection) {
                            HStack {
                                if testingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "wifi")
                                }
                                Text("Test Connection")
                            }
                        }
                        .disabled(testingConnection || apiBaseURL.isEmpty)
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    if let result = connectionResult {
                        HStack {
                            Image(systemName: result.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.contains("Success") ? .green : .red)
                            Text(result)
                                .font(.caption)
                        }
                    }

                } header: {
                    Label("Connection Test", systemImage: "network")
                }
                
                // Theme Section
                ThemeSectionView()

                // App Version Section
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let settingsChanged = saveSettings()
                        if settingsChanged {
                            gameState.refreshSettings()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Change Skill Level?", isPresented: $showingSkillLevelAlert) {
                Button("Cancel", role: .cancel) {
                    pendingSkillLevel = nil
                }
                Button("Reset & Change", role: .destructive) {
                    confirmSkillLevelChange()
                }
            } message: {
                if let newLevel = pendingSkillLevel {
                    Text("Changing to \(newLevel.displayName) requires resetting the game because a new coaching session will be created. This will start a fresh game at the new difficulty level.")
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }

    // MARK: - App Version

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (Build \(build))"
    }

    // MARK: - Settings Management

    private func loadSettings() {
        // Store original API URL for change detection
        originalAPIBaseURL = apiBaseURL

        // Load skill level from gameState
        defaultSkillLevel = gameState.skillLevel

        // Load shouldShowHistory into gameState
        gameState.shouldShowHistory = shouldShowHistory
    }

    private func saveSettings() -> Bool {
        // Check if API URL has changed
        let urlChanged = apiBaseURL != originalAPIBaseURL

        // Update skill level in gameState
        gameState.updateSkillLevel(defaultSkillLevel)

        // Update debug mode in gameState
        gameState.shouldShowHistory = shouldShowHistory

        // @AppStorage automatically saves apiBaseURL, apiKey, and shouldShowHistory
        // Only return true if game-related settings changed (API, skill level, etc.)
        // Color theme changes don't require game state refresh
        return urlChanged
    }

    private func resetToDefaults() {
        // @AppStorage properties will automatically save these changes
        apiBaseURL = APIPreset.defaultURL
        apiKey = ""
        defaultSkillLevel = .intermediate
        shouldShowHistory = false
        connectionResult = nil

        // Also update gameState
        gameState.updateSkillLevel(.intermediate)
        gameState.shouldShowHistory = false
    }

    private func handleSkillLevelChange(to newLevel: SkillLevel) {
        // Check if game is in progress
        if gameState.moveCount > 0 && newLevel != gameState.skillLevel {
            logDebug("Skill level change with game in progress - showing warning", category: .ui)
            pendingSkillLevel = newLevel
            showingSkillLevelAlert = true
            return
        }

        // Direct change (no game in progress)
        defaultSkillLevel = newLevel
        gameState.updateSkillLevel(newLevel)
    }

    private func confirmSkillLevelChange() {
        guard let newLevel = pendingSkillLevel else { return }

        logDebug("User confirmed skill level change - resetting game and updating level", category: .ui)
        defaultSkillLevel = newLevel
        gameState.updateSkillLevel(newLevel)
        pendingSkillLevel = nil
    }

    private func testConnection() {
        testingConnection = true
        connectionResult = nil

        Task {
            let testAPI = ChessCoachAPI(baseURL: apiBaseURL, apiKey: apiKey.isEmpty ? nil : apiKey)
            let success = await testAPI.testConnection()

            await MainActor.run {
                testingConnection = false
                connectionResult = success ? "✅ Success: Connected to Chess Coach API" : "❌ Failed: Unable to connect to server"
            }
        }
    }

    // MARK: - Network Utilities

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET) {
                    let name = String(validatingCString: interface.ifa_name) ?? ""
                    if name == "en0" || name == "en1" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(validating: hostname, as: UTF8.self)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}

#Preview {
    SettingsView(gameState: ChessGameState())
}
