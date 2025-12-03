//
//  AppSettings.swift
//  IoS Scale
//
//  User preferences and app settings.
//

import Foundation
import SwiftUI

/// User preferences stored in UserDefaults
struct AppSettings: Codable {
    /// Theme preference
    var theme: ThemeMode = .system
    
    /// Behavior when starting a new measurement
    var resetBehavior: ResetBehavior = .resetToDefault
    
    /// Export format preference
    var exportFormat: ExportFormat = .csv
    
    /// Whether to include metadata in exports
    var includeMetadataInExport: Bool = true
    
    /// Decimal separator for exports
    var decimalSeparator: DecimalSeparator = .point
    
    /// Whether iCloud sync is enabled
    var iCloudSyncEnabled: Bool = false
    
    /// Whether biometric authentication is enabled
    var biometricAuthEnabled: Bool = false
    
    /// Whether haptic feedback is enabled
    var hapticFeedbackEnabled: Bool = true
}

// MARK: - Theme Mode

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case system
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Reset Behavior

enum ResetBehavior: String, Codable, CaseIterable, Identifiable {
    case keepPosition = "keep_position"
    case resetToDefault = "reset_to_default"
    case randomPosition = "random_position"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .keepPosition: return "Keep Position"
        case .resetToDefault: return "Reset to Default"
        case .randomPosition: return "Random Position"
        }
    }
    
    var description: String {
        switch self {
        case .keepPosition:
            return "Start new measurement from previous position"
        case .resetToDefault:
            return "Reset circles to default positions"
        case .randomPosition:
            return "Start from a random position each time"
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, Codable, CaseIterable, Identifiable {
    case csv
    case tsv
    case json
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.uppercased()
    }
    
    var fileExtension: String {
        rawValue
    }
    
    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .tsv: return "text/tab-separated-values"
        case .json: return "application/json"
        }
    }
}

// MARK: - Decimal Separator

enum DecimalSeparator: String, Codable, CaseIterable, Identifiable {
    case point = "."
    case comma = ","
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .point: return "Point (.)"
        case .comma: return "Comma (,)"
        }
    }
}

// MARK: - UserDefaults Storage

extension AppSettings {
    private static let storageKey = "app_settings"
    
    /// Load settings from UserDefaults
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    /// Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
