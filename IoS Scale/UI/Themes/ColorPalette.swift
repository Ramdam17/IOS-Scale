//
//  ColorPalette.swift
//  IoS Scale
//
//  Defines the app's color palette with pastel rainbow unicorn aesthetic.
//

import SwiftUI

// MARK: - Color Palette

enum ColorPalette {
    
    // MARK: - Circle Colors
    
    /// Self circle - Cool Blue
    static let selfCircleCore = Color(hex: "4A90D9")
    static let selfCircleGlow = Color(hex: "7BB3FF")
    
    /// Other circle - Warm Magenta
    static let otherCircleCore = Color(hex: "9B59B6")
    static let otherCircleGlow = Color(hex: "D98EDB")
    
    // MARK: - Background Colors
    
    /// Light mode background colors
    static let lightBackgroundStart = Color(hex: "F8F9FF")  // Soft lavender white
    static let lightBackgroundMid1 = Color(hex: "E8F4F8")   // Pale cyan
    static let lightBackgroundMid2 = Color(hex: "FFF8F0")   // Warm cream
    static let lightBackgroundEnd = Color(hex: "F0FFF4")    // Mint whisper
    
    /// Dark mode background colors
    static let darkBackgroundStart = Color(hex: "1A1A2E")   // Deep navy
    static let darkBackgroundMid1 = Color(hex: "16213E")    // Midnight blue
    static let darkBackgroundMid2 = Color(hex: "1F1135")    // Dark purple
    static let darkBackgroundEnd = Color(hex: "0F0F23")     // Near black
    
    // MARK: - Card Colors
    
    static let cardBackgroundLight = Color.white.opacity(0.8)
    static let cardBackgroundDark = Color(hex: "2A2A3E").opacity(0.6)
    static let cardBorderLight = Color(hex: "E0E0E0").opacity(0.5)
    static let cardBorderDark = Color(hex: "4A4A6A").opacity(0.3)
    
    // MARK: - Semantic Colors
    
    static let success = Color(hex: "27AE60")
    static let successDark = Color(hex: "6BCB77")
    static let destructive = Color(hex: "E74C3C")
    static let destructiveDark = Color(hex: "FF6B6B")
}

// MARK: - Gradients

extension ColorPalette {
    
    /// Self circle radial gradient
    static var selfCircleGradient: RadialGradient {
        RadialGradient(
            colors: [selfCircleCore, selfCircleGlow.opacity(0.6)],
            center: .center,
            startRadius: 0,
            endRadius: 60
        )
    }
    
    /// Other circle radial gradient
    static var otherCircleGradient: RadialGradient {
        RadialGradient(
            colors: [otherCircleCore, otherCircleGlow.opacity(0.6)],
            center: .center,
            startRadius: 0,
            endRadius: 60
        )
    }
    
    /// Overlap zone gradient
    static var overlapGradient: LinearGradient {
        LinearGradient(
            colors: [selfCircleCore.opacity(0.7), otherCircleCore.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Light mode background gradient
    static var lightBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                lightBackgroundStart,
                lightBackgroundMid1,
                lightBackgroundMid2,
                lightBackgroundEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Dark mode background gradient
    static var darkBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                darkBackgroundStart,
                darkBackgroundMid1,
                darkBackgroundMid2,
                darkBackgroundEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Primary button gradient (blue to purple)
    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [selfCircleCore, otherCircleCore],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Color Extension

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
