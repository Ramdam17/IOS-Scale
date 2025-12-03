//
//  Spacing.swift
//  IoS Scale
//
//  Defines the app's spacing scale for consistent layout.
//

import SwiftUI

// MARK: - Spacing

enum Spacing {
    /// Extra extra small: 4pt
    static let xxs: CGFloat = 4
    
    /// Extra small: 8pt
    static let xs: CGFloat = 8
    
    /// Small: 12pt
    static let sm: CGFloat = 12
    
    /// Medium: 16pt (base unit)
    static let md: CGFloat = 16
    
    /// Large: 24pt
    static let lg: CGFloat = 24
    
    /// Extra large: 32pt
    static let xl: CGFloat = 32
    
    /// Extra extra large: 48pt
    static let xxl: CGFloat = 48
}

// MARK: - Layout Constants

enum LayoutConstants {
    /// Standard corner radius for cards
    static let cardCornerRadius: CGFloat = 20
    
    /// Standard corner radius for buttons
    static let buttonCornerRadius: CGFloat = 16
    
    /// Standard corner radius for small elements
    static let smallCornerRadius: CGFloat = 8
    
    /// Icon size in cards
    static let cardIconSize: CGFloat = 44
    
    /// Base circle diameter for iPhone
    static let circleBaseDiameter: CGFloat = 120
    
    /// Base circle diameter for iPad
    static let circleBaseDiameterPad: CGFloat = 180
    
    /// Minimum scale for circles
    static let minCircleScale: Double = 0.2
    
    /// Maximum scale for circles
    static let maxCircleScale: Double = 2.0
    
    /// Default scale for circles
    static let defaultCircleScale: Double = 1.0
    
    /// Slider track height
    static let sliderTrackHeight: CGFloat = 8
    
    /// Slider thumb diameter
    static let sliderThumbDiameter: CGFloat = 28
    
    /// Shadow radius for cards
    static let cardShadowRadius: CGFloat = 10
    
    /// Shadow opacity for cards
    static let cardShadowOpacity: Double = 0.1
}

// MARK: - Adaptive Spacing

extension Spacing {
    /// Returns adaptive spacing based on horizontal size class
    static func adaptive(
        compact: CGFloat,
        regular: CGFloat,
        for sizeClass: UserInterfaceSizeClass?
    ) -> CGFloat {
        sizeClass == .regular ? regular : compact
    }
}

// MARK: - View Extension

extension View {
    /// Apply standard card padding
    func cardPadding() -> some View {
        self.padding(Spacing.md)
    }
    
    /// Apply standard screen padding
    func screenPadding() -> some View {
        self.padding(.horizontal, Spacing.md)
    }
    
    /// Apply standard section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, Spacing.lg)
    }
}
