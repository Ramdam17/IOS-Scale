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
    @AppStorage("themeMode") var themeMode: ThemeMode = .system {
        didSet {
            objectWillChange.send()
        }
    }
    
    init() {}
    
    /// The color scheme to apply, nil for system default
    var colorScheme: ColorScheme? {
        themeMode.colorScheme
    }
    
    /// Cycle through available themes
    func cycleTheme() {
        let allThemes = ThemeMode.allCases
        guard let currentIndex = allThemes.firstIndex(of: themeMode) else { return }
        let nextIndex = (currentIndex + 1) % allThemes.count
        themeMode = allThemes[nextIndex]
    }
}
