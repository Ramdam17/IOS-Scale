//
//  LiquidGlassCard.swift
//  IoS Scale
//
//  A card component with Apple Liquid Glass aesthetic.
//

import SwiftUI

/// A card with translucent glass effect following Apple's Liquid Glass design
struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let content: Content
    var tintColor: Color?
    var isExpanded: Bool = false
    
    init(
        tintColor: Color? = nil,
        isExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.tintColor = tintColor
        self.isExpanded = isExpanded
    }
    
    var body: some View {
        content
            .padding(Spacing.md)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
            .overlay(borderOverlay)
            .shadow(
                color: shadowColor,
                radius: LayoutConstants.cardShadowRadius,
                x: 0,
                y: 4
            )
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        if colorScheme == .dark {
            darkBackground
        } else {
            lightBackground
        }
    }
    
    private var lightBackground: some View {
        ZStack {
            // Base material
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                .fill(.ultraThinMaterial)
            
            // Tint overlay if provided
            if let tint = tintColor {
                RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                    .fill(tint.opacity(0.08))
            }
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var darkBackground: some View {
        ZStack {
            // Base material - slightly more opaque for dark mode
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                .fill(.regularMaterial)
            
            // Tint overlay if provided
            if let tint = tintColor {
                RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                    .fill(tint.opacity(0.12))
            }
            
            // Subtle gradient overlay for depth
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    // MARK: - Border
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        borderColor.opacity(0.6),
                        borderColor.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private var borderColor: Color {
        colorScheme == .dark 
            ? ColorPalette.cardBorderDark 
            : ColorPalette.cardBorderLight
    }
    
    // MARK: - Shadow
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            // Glow effect for dark mode
            return (tintColor ?? ColorPalette.selfCircleGlow).opacity(0.2)
        } else {
            return Color.black.opacity(LayoutConstants.cardShadowOpacity)
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    VStack(spacing: Spacing.md) {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Basic IOS")
                    .font(Typography.headline)
                Text("Classic distance-based measurement")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        LiquidGlassCard(tintColor: Color(hex: "74B9FF")) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("With Tint")
                    .font(Typography.headline)
                Text("Card with blue tint color")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
    .background(ColorPalette.lightBackgroundGradient)
}

#Preview("Dark Mode") {
    VStack(spacing: Spacing.md) {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Basic IOS")
                    .font(Typography.headline)
                Text("Classic distance-based measurement")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        LiquidGlassCard(tintColor: Color(hex: "FD79A8")) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("With Tint")
                    .font(Typography.headline)
                Text("Card with pink tint color")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
    .background(ColorPalette.darkBackgroundGradient)
    .preferredColorScheme(.dark)
}
