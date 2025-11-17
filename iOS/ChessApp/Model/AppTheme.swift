//
//  AppTheme.swift
//  ChessApp
//
//  App theme configuration and color management
//

import SwiftUI

@Observable
final class AppTheme {
    @MainActor static let shared = AppTheme()

    var primaryColor: Color {
        didSet {
            savePrimaryColor()
        }
    }

    private init() {
        // Load saved color or default to blue
        if let savedColor = Self.loadPrimaryColor() {
            self.primaryColor = savedColor
        } else {
            self.primaryColor = .blue
        }
    }

    // MARK: - Available Theme Colors
    static let availableColors: [(name: String, color: Color)] = [
        ("Blue", .blue),
        ("Green", .green),
        ("Purple", .purple),
        ("Cyan", .cyan),
        ("Indigo", .indigo),
        ("Mint", .mint),
    ]

    // MARK: - Persistence
    private static let userDefaultsKey = "AppTheme.primaryColor"

    private func savePrimaryColor() {
        if let colorName = Self.getColorName(primaryColor) {
            UserDefaults.standard.set(colorName, forKey: Self.userDefaultsKey)
        }
    }

    private static func loadPrimaryColor() -> Color? {
        guard let colorName = UserDefaults.standard.string(forKey: userDefaultsKey) else {
            return nil
        }
        return availableColors.first(where: { $0.name == colorName })?.color
    }

    private static func getColorName(_ color: Color) -> String? {
        return availableColors.first(where: { $0.color == color })?.name
    }
}

// MARK: - Theme Extension for Color Applications
extension View {
    /// Applies the app's primary theme color
    func themePrimary() -> some View {
        self.foregroundColor(AppTheme.shared.primaryColor)
    }

    /// Applies the theme color as tint
    func themeTint() -> some View {
        self.tint(AppTheme.shared.primaryColor)
    }
}
