//
//  IOSSlider.swift
//  IoS Scale
//
//  Custom slider component for IOS Scale measurements.
//

import SwiftUI

/// A custom slider styled for IOS Scale measurements
struct IOSSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var onEditingChanged: ((Bool) -> Void)?
    
    @State private var isDragging = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Layout constants
    private let trackHeight: CGFloat = LayoutConstants.sliderTrackHeight
    private let thumbDiameter: CGFloat = LayoutConstants.sliderThumbDiameter
    
    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - thumbDiameter
            let thumbPosition = thumbDiameter / 2 + trackWidth * normalizedValue
            
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(trackBackgroundColor)
                    .frame(height: trackHeight)
                
                // Filled track
                Capsule()
                    .fill(ColorPalette.primaryButtonGradient)
                    .frame(width: thumbPosition, height: trackHeight)
                
                // Thumb
                Circle()
                    .fill(thumbFill)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .shadow(
                        color: thumbShadowColor,
                        radius: isDragging ? 8 : 4,
                        x: 0,
                        y: isDragging ? 4 : 2
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .position(x: thumbPosition, y: geometry.size.height / 2)
            }
            .frame(height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged?(true)
                            HapticManager.shared.lightImpact()
                        }
                        
                        let newValue = (gesture.location.x - thumbDiameter / 2) / trackWidth
                        value = min(max(range.lowerBound, range.lowerBound + newValue * (range.upperBound - range.lowerBound)), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged?(false)
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .frame(height: thumbDiameter)
        .accessibilityValue("\(Int(normalizedValue * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + 0.1, range.upperBound)
            case .decrement:
                value = max(value - 0.1, range.lowerBound)
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var normalizedValue: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private var trackBackgroundColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.15) 
            : Color.black.opacity(0.1)
    }
    
    private var thumbFill: some ShapeStyle {
        colorScheme == .dark
            ? Color.white
            : Color.white
    }
    
    private var thumbShadowColor: Color {
        colorScheme == .dark
            ? ColorPalette.selfCircleGlow.opacity(0.3)
            : Color.black.opacity(0.15)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    VStack(spacing: 40) {
        IOSSlider(value: .constant(0.0))
        IOSSlider(value: .constant(0.5))
        IOSSlider(value: .constant(1.0))
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorPalette.lightBackgroundGradient)
}

#Preview("Dark Mode") {
    VStack(spacing: 40) {
        IOSSlider(value: .constant(0.0))
        IOSSlider(value: .constant(0.5))
        IOSSlider(value: .constant(1.0))
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorPalette.darkBackgroundGradient)
    .preferredColorScheme(.dark)
}

#Preview("Interactive") {
    struct PreviewWrapper: View {
        @State private var value = 0.5
        
        var body: some View {
            VStack(spacing: 40) {
                Text("Value: \(value, specifier: "%.2f")")
                    .font(Typography.numeric)
                
                IOSSlider(value: $value)
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.lightBackgroundGradient)
        }
    }
    
    return PreviewWrapper()
}
