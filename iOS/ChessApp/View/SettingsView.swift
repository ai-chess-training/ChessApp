//
//  SettingsView.swift
//  ChessApp
//
//  App settings including Chess Coach API configuration
//

import SwiftUI

struct SettingsView: View {
    let gameState: ChessGameState
    @Environment(\.dismiss) private var dismiss
    @State private var apiBaseURL: String = "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"
    @State private var originalAPIBaseURL: String = "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"
    @State private var apiKey: String = ""
    @State private var defaultSkillLevel: SkillLevel = .intermediate
    @State private var enableCoachingByDefault: Bool = true
    @State private var shouldShowHistory: Bool = false
    @State private var showingResetAlert = false
    @State private var testingConnection = false
    @State private var connectionResult: String?

    var body: some View {
        NavigationStack {
            Form {
                // Chess Coach API Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Base URL")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com", text: $apiBaseURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Enter OpenAI API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Quick URL presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Presets")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 12) {
                            Button(action: {
                                apiBaseURL = "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"
                            }) {
                                Text("Production")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(apiBaseURL == "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com" ? .blue : .gray)

                            Button(action: {
                                apiBaseURL = "http://localhost:8000"
                            }) {
                                Text("Local Dev")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(apiBaseURL == "http://localhost:8000" ? .blue : .gray)
                        }
                    }

                } header: {
                    Label("Chess Coach API", systemImage: "brain")
                } footer: {
                    Text("Configure the Chess Coach backend server connection. Use localhost for local development or your Mac's IP address for testing on device.")
                }

                // Default Settings Section
                Section {
                    Picker("Default Skill Level", selection: $defaultSkillLevel) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Toggle("Enable Coaching by Default", isOn: $enableCoachingByDefault)

                } header: {
                    Label("Coaching Defaults", systemImage: "graduationcap")
                } footer: {
                    Text("These settings will be applied to new games automatically.")
                }

                // Developer Settings Section
                Section {
                    Toggle("Show Move History", isOn: $shouldShowHistory)

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

                // Reset Section
                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        showingResetAlert = true
                    }
                } footer: {
                    Text("This will reset all Chess Coach settings to their default values.")
                }

                // App Version Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("ChessApp")
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
                        saveSettings()
                        gameState.refreshSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                    gameState.refreshSettings()
                }
            } message: {
                Text("Are you sure you want to reset all settings to their default values?")
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
        let savedURL = UserDefaults.standard.string(forKey: "ChessCoach.apiBaseURL") ?? "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"
        apiBaseURL = savedURL
        originalAPIBaseURL = savedURL
        apiKey = UserDefaults.standard.string(forKey: "ChessCoach.apiKey") ?? ""

        if let savedLevel = UserDefaults.standard.string(forKey: "ChessCoach.defaultSkillLevel"),
           let level = SkillLevel(rawValue: savedLevel) {
            defaultSkillLevel = level
        }

        enableCoachingByDefault = UserDefaults.standard.bool(forKey: "ChessCoach.enabledByDefault")
        shouldShowHistory = UserDefaults.standard.bool(forKey: "ChessCoach.shouldShowHistory")
    }

    private func saveSettings() {
        // Check if API URL has changed
        let urlChanged = apiBaseURL != originalAPIBaseURL

        UserDefaults.standard.set(apiBaseURL, forKey: "ChessCoach.apiBaseURL")
        UserDefaults.standard.set(apiKey.isEmpty ? nil : apiKey, forKey: "ChessCoach.apiKey")
        UserDefaults.standard.set(defaultSkillLevel.rawValue, forKey: "ChessCoach.defaultSkillLevel")
        UserDefaults.standard.set(enableCoachingByDefault, forKey: "ChessCoach.enabledByDefault")
        UserDefaults.standard.set(shouldShowHistory, forKey: "ChessCoach.shouldShowHistory")

        // Reset game if API URL changed
        if urlChanged {
            gameState.resetGameForSettings()
        }
    }

    private func resetToDefaults() {
        apiBaseURL = "https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com"
        apiKey = ""
        defaultSkillLevel = .intermediate
        enableCoachingByDefault = true
        shouldShowHistory = false
        connectionResult = nil

        // Clear from UserDefaults
        let keys = [
            "ChessCoach.apiBaseURL",
            "ChessCoach.apiKey",
            "ChessCoach.defaultSkillLevel",
            "ChessCoach.enabledByDefault",
            "ChessCoach.shouldShowHistory"
        ]

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
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
