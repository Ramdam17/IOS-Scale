//
//  GradientBackground.swift
//  IoS Scale
//
//  A background view with adaptive gradient based on color scheme.
//

import SwiftUI

/// Full-screen gradient background that adapts to light/dark mode
struct GradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            if colorScheme == .dark {
                ColorPalette.darkBackgroundGradient
            } else {
                ColorPalette.lightBackgroundGradient
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - View Modifier

extension View {
    /// Apply the app's gradient background
    func gradientBackground() -> some View {
        self.background(GradientBackground())
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    Text("Hello, World!")
        .font(Typography.largeTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gradientBackground()
}

#Preview("Dark Mode") {
    Text("Hello, World!")
        .font(Typography.largeTitle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gradientBackground()
        .preferredColorScheme(.dark)
}
