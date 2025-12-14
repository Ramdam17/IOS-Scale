//
//  IdentificationCirclesView.swift
//  IoS Scale
//
//  Interactive circles component for Identification modality.
//  Other moves toward and into Self, with color blending and opacity changes.
//  Direction: Other → Self (Self absorbs Other's qualities)
//

import SwiftUI

/// View displaying identification interaction where Other moves into Self
struct IdentificationCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Identification value: 0 = separate, 1 = fully identified
    @Binding var identificationValue: Double
    
    /// Callback when dragging starts or ends
    var onDraggingChanged: ((Bool) -> Void)?
    
    // State
    @State private var isDragging = false
    @State private var hasInitialized = false
    @State private var lastHapticValue: Double = 0
    
    // Layout constants
    private var circleSize: CGFloat {
        horizontalSizeClass == .regular ? 100 : 80
    }
    
    private let hapticThreshold: Double = 0.1
    
    var body: some View {
        GeometryReader { geometry in
            let selfCenter = selfPosition(geometry: geometry)
            let otherCenter = otherPosition(geometry: geometry)
            
            ZStack {
                // Direction arrow (Other → Self)
                directionArrow(from: otherCenter, to: selfCenter, geometry: geometry)
                
                // Self circle (stationary, receives Other)
                selfCircleView(position: selfCenter, geometry: geometry)
                
                // Other circle (moves toward Self)
                otherCircleView(position: otherCenter, geometry: geometry)
                
                // Absorption effect overlay on Self
                absorptionEffect(position: selfCenter, geometry: geometry)
                
                // Labels
                circleLabels(selfCenter: selfCenter, otherCenter: otherCenter, geometry: geometry)
            }
            .onChange(of: geometry.size) { _, _ in
                hasInitialized = true
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Identification measurement")
        .accessibilityValue("Identification: \(Int(identificationValue * 100)) percent")
        .accessibilityHint("Drag left to increase identification, right to decrease")
    }
    
    // MARK: - Positions
    
    private func selfPosition(geometry: GeometryProxy) -> CGPoint {
        // Self stays on the left, stationary
        let centerY = geometry.size.height * 0.4
        let x = geometry.size.width * 0.25  // Moved left for more range
        return CGPoint(x: x, y: centerY)
    }
    
    private func otherPosition(geometry: GeometryProxy) -> CGPoint {
        // Other moves from right toward Self based on identificationValue
        let centerY = geometry.size.height * 0.4
        let selfX = geometry.size.width * 0.25
        let startX = geometry.size.width * 0.75 // Starting position (far right) - more range
        
        // At value=1, Other is at same position as Self (fully absorbed)
        let currentX = startX - (startX - selfX) * identificationValue
        
        return CGPoint(x: currentX, y: centerY)
    }
    
    // MARK: - Direction Arrow
    
    private func directionArrow(from: CGPoint, to: CGPoint, geometry: GeometryProxy) -> some View {
        let arrowOpacity = max(0, 1 - identificationValue * 1.5) // Fades as absorption increases
        
        // Calculate arrow position based on actual circle positions
        let gap = from.x - to.x - circleSize  // Space between circles
        let arrowLength = min(gap * 0.6, 60)  // Arrow is 60% of gap, max 60pt
        let centerX = (from.x + to.x) / 2     // Center point between circles
        let centerY = from.y
        
        return ZStack {
            // Only show arrow if there's enough space
            if gap > circleSize * 0.5 {
                // Arrow line (short, centered)
                Path { path in
                    let startX = centerX + arrowLength / 2
                    let endX = centerX - arrowLength / 2
                    path.move(to: CGPoint(x: startX, y: centerY))
                    path.addLine(to: CGPoint(x: endX, y: centerY))
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            ColorPalette.otherCircleCore.opacity(0.6),
                            ColorPalette.selfCircleCore.opacity(0.6)
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6])
                )
                .opacity(arrowOpacity)
                
                // Arrow head pointing to Self (left)
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ColorPalette.selfCircleCore.opacity(0.7))
                    .position(x: centerX - arrowLength / 2 - 10, y: centerY)
                    .opacity(arrowOpacity)
            }
        }
    }
    
    // MARK: - Self Circle
    
    private func selfCircleView(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Self circle gets a purple tint as it absorbs Other's qualities
        let blendAmount = identificationValue
        
        return ZStack {
            // Base Self circle
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
            
            // Other's color blending in
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .opacity(blendAmount * 0.6)
            
            // Glow effect when absorbing
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(blendAmount * 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: circleSize * 0.3,
                        endRadius: circleSize * 0.7
                    )
                )
                .frame(width: circleSize * 1.3, height: circleSize * 1.3)
                .opacity(blendAmount)
        }
        .overlay(
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            blendAmount > 0.5 ? Color(hex: "FFD700").opacity(0.5) : Color.white.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: circleSize, height: circleSize)
        )
        .shadow(
            color: blendAmount > 0.7 ? Color(hex: "FFD700").opacity(0.5) : ColorPalette.selfCircleCore.opacity(0.3),
            radius: 10 + blendAmount * 10
        )
        .position(position)
        .animation(.spring(response: 0.3), value: identificationValue)
    }
    
    // MARK: - Other Circle
    
    private func otherCircleView(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Other circle fades and shrinks as it's absorbed
        let fadeAmount = 1 - identificationValue * 0.8
        let scaleAmount = 1 - identificationValue * 0.5
        
        return Circle()
            .fill(ColorPalette.otherCircleGradient)
            .frame(width: circleSize, height: circleSize)
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.white.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: ColorPalette.otherCircleCore.opacity(0.3 * fadeAmount), radius: 10)
            .scaleEffect(scaleAmount)
            .opacity(fadeAmount)
            .position(position)
            .animation(.spring(response: 0.3), value: identificationValue)
    }
    
    // MARK: - Absorption Effect
    
    private func absorptionEffect(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Pulsing rings when absorption is high
        let showEffect = identificationValue > 0.7
        
        return ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color(hex: "FFD700").opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .frame(
                        width: circleSize + CGFloat(index) * 20 + (showEffect ? 10 : 0),
                        height: circleSize + CGFloat(index) * 20 + (showEffect ? 10 : 0)
                    )
                    .scaleEffect(showEffect ? 1.1 : 1.0)
                    .opacity(showEffect ? 1 : 0)
            }
        }
        .position(position)
        .animation(
            showEffect
                ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                : .default,
            value: showEffect
        )
    }
    
    // MARK: - Labels
    
    private func circleLabels(selfCenter: CGPoint, otherCenter: CGPoint, geometry: GeometryProxy) -> some View {
        ZStack {
            // Self label
            Text("Self")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.selfCircleCore)
                .position(x: selfCenter.x, y: selfCenter.y + circleSize / 2 + 18)
            
            // Other label (fades with circle)
            Text("Other")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.otherCircleCore)
                .opacity(1 - identificationValue * 0.8)
                .position(x: otherCenter.x, y: otherCenter.y + circleSize / 2 + 18)
        }
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    onDraggingChanged?(true)
                    HapticManager.shared.lightImpact()
                }
                
                // Horizontal drag: left = more identification (Other moves toward Self), right = less
                // Improved sensitivity for better control
                let dragSensitivity: CGFloat = 200
                let delta = -value.translation.width / dragSensitivity
                let adjustedValue = identificationValue + delta * 0.15
                
                // Haptic feedback at thresholds
                if abs(adjustedValue - lastHapticValue) >= hapticThreshold {
                    HapticManager.shared.lightImpact()
                    lastHapticValue = adjustedValue
                }
                
                // Special haptic when fully identified
                if adjustedValue >= 0.98 && identificationValue < 0.98 {
                    HapticManager.shared.success()
                }
                
                withAnimation(.interactiveSpring(response: 0.15)) {
                    identificationValue = min(max(0, adjustedValue), 1)
                }
            }
            .onEnded { _ in
                isDragging = false
                onDraggingChanged?(false)
            }
    }
}

// MARK: - Preview

#Preview("Identification Circles") {
    struct PreviewWrapper: View {
        @State private var identification: Double = 0.3
        
        var body: some View {
            VStack {
                IdentificationCirclesView(
                    identificationValue: $identification,
                    onDraggingChanged: { _ in }
                )
                .frame(height: 300)
                
                Text("Identification: \(Int(identification * 100))%")
                    .font(Typography.headline)
                
                Slider(value: $identification, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Fully Identified") {
    struct PreviewWrapper: View {
        @State private var identification: Double = 0.95
        
        var body: some View {
            IdentificationCirclesView(
                identificationValue: $identification,
                onDraggingChanged: { _ in }
            )
            .frame(height: 300)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
