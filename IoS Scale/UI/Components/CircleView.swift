//
//  CircleView.swift
//  IoS Scale
//
//  Interactive circle component for IOS Scale measurements.
//

import SwiftUI

/// Type of circle in the IOS Scale
enum CircleType {
    case selfCircle
    case otherCircle
    
    /// The gradient fill for this circle type
    var gradient: RadialGradient {
        switch self {
        case .selfCircle:
            return ColorPalette.selfCircleGradient
        case .otherCircle:
            return ColorPalette.otherCircleGradient
        }
    }
    
    /// The glow color for dark mode
    var glowColor: Color {
        switch self {
        case .selfCircle:
            return ColorPalette.selfCircleGlow
        case .otherCircle:
            return ColorPalette.otherCircleGlow
        }
    }
    
    /// Accessibility label for the circle
    var accessibilityLabel: String {
        switch self {
        case .selfCircle:
            return "Self circle"
        case .otherCircle:
            return "Other circle"
        }
    }
}

/// An interactive circle used in IOS Scale measurements
struct CircleView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let type: CircleType
    let diameter: CGFloat
    var scale: Double = 1.0
    var isDragging: Bool = false
    
    var body: some View {
        Circle()
            .fill(type.gradient)
            .frame(width: scaledDiameter, height: scaledDiameter)
            .overlay(glowOverlay)
            .shadow(
                color: shadowColor,
                radius: isDragging ? 15 : 10,
                x: 0,
                y: isDragging ? 8 : 4
            )
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            .accessibilityLabel(type.accessibilityLabel)
    }
    
    // MARK: - Computed Properties
    
    private var scaledDiameter: CGFloat {
        diameter * scale
    }
    
    @ViewBuilder
    private var glowOverlay: some View {
        if colorScheme == .dark {
            Circle()
                .stroke(type.glowColor.opacity(0.5), lineWidth: 2)
                .blur(radius: 4)
        }
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return type.glowColor.opacity(isDragging ? 0.4 : 0.3)
        } else {
            return Color.black.opacity(isDragging ? 0.2 : 0.15)
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    HStack(spacing: 40) {
        CircleView(type: .selfCircle, diameter: 120)
        CircleView(type: .otherCircle, diameter: 120)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorPalette.lightBackgroundGradient)
}

#Preview("Dark Mode") {
    HStack(spacing: 40) {
        CircleView(type: .selfCircle, diameter: 120)
        CircleView(type: .otherCircle, diameter: 120)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorPalette.darkBackgroundGradient)
    .preferredColorScheme(.dark)
}

#Preview("Scaled") {
    HStack(spacing: 40) {
        CircleView(type: .selfCircle, diameter: 120, scale: 0.5)
        CircleView(type: .otherCircle, diameter: 120, scale: 1.5)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorPalette.lightBackgroundGradient)
}

#Preview("Dragging State") {
    HStack(spacing: 40) {
        CircleView(type: .selfCircle, diameter: 120, isDragging: true)
        CircleView(type: .otherCircle, diameter: 120)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorPalette.lightBackgroundGradient)
}
