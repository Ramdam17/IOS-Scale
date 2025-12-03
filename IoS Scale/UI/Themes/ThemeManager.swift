//
//  ThemeManager.swift
//  IoS Scale
//
//  Manages app-wide theme settings and color scheme.
//

import SwiftUI
import Combine

/// Observable object managing theme state across the app
@MainActor
final class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeMode {
        didSet {
            saveTheme()
        }
    }
    
    init() {
        let settings = AppSettings.load()
        self.currentTheme = settings.theme
    }
    
    /// The color scheme to apply, nil for system default
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
    
    /// Cycle through available themes
    func cycleTheme() {
        let allThemes = ThemeMode.allCases
        guard let currentIndex = allThemes.firstIndex(of: currentTheme) else { return }
        let nextIndex = (currentIndex + 1) % allThemes.count
        currentTheme = allThemes[nextIndex]
    }
    
    private func saveTheme() {
        var settings = AppSettings.load()
        settings.theme = currentTheme
        settings.save()
    }
}
