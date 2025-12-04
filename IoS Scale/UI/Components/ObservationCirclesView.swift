//
//  ObservationCirclesView.swift
//  IoS Scale
//
//  Interactive circles component for Observation modality.
//  Visualizes the transition from observer (outside) to participant (immersed).
//  Eye icon fades as Self becomes more integrated with Other.
//

import SwiftUI

/// View displaying observation/participation transition
struct ObservationCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Participation value: 0 = observer (outside), 1 = participant (immersed)
    @Binding var participationValue: Double
    
    /// Callback when dragging starts or ends
    var onDraggingChanged: ((Bool) -> Void)?
    
    // State
    @State private var isDragging = false
    @State private var hasInitialized = false
    @State private var lastHapticValue: Double = 0
    
    // Layout constants
    private var circleSize: CGFloat {
        horizontalSizeClass == .regular ? 90 : 70
    }
    
    private let hapticThreshold: Double = 0.1
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height * 0.45
            
            ZStack {
                // Scene frame (the "window" being observed/participated in)
                sceneFrame(geometry: geometry, centerX: centerX, centerY: centerY)
                
                // The Self-Other pair (scene content)
                sceneContent(geometry: geometry, centerX: centerX, centerY: centerY)
                
                // Observer eye (fades as participation increases)
                observerEye(geometry: geometry, centerX: centerX, centerY: centerY)
                
                // Self indicator (shows Self position relative to scene)
                selfIndicator(geometry: geometry, centerX: centerX, centerY: centerY)
                
                // Immersion effect (glowing border when fully immersed)
                immersionEffect(geometry: geometry, centerX: centerX, centerY: centerY)
            }
            .onChange(of: geometry.size) { _, _ in
                hasInitialized = true
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Observation measurement")
        .accessibilityValue("Participation: \(Int(participationValue * 100)) percent")
        .accessibilityHint("Drag right to increase participation, left to observe more")
    }
    
    // MARK: - Scene Frame
    
    private func sceneFrame(geometry: GeometryProxy, centerX: CGFloat, centerY: CGFloat) -> some View {
        let frameWidth = geometry.size.width * 0.65
        let frameHeight = geometry.size.height * 0.55
        
        // Frame scales up as we become more immersed
        let scaleEffect = 1 + participationValue * 0.2
        
        return RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.secondary.opacity(0.3),
                        Color.secondary.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 2
            )
            .frame(width: frameWidth, height: frameHeight)
            .scaleEffect(scaleEffect)
            .position(x: centerX, y: centerY)
            .animation(.spring(response: 0.4), value: participationValue)
    }
    
    // MARK: - Scene Content (Self-Other pair)
    
    private func sceneContent(geometry: GeometryProxy, centerX: CGFloat, centerY: CGFloat) -> some View {
        // Scene becomes clearer/larger as we participate more
        let clarity = 0.4 + participationValue * 0.6
        let scaleEffect = 0.7 + participationValue * 0.4
        let blurAmount = (1 - participationValue) * 3
        
        return ZStack {
            // Other circle (always in scene)
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize * 0.9, height: circleSize * 0.9)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: ColorPalette.otherCircleCore.opacity(0.3), radius: 6)
                .position(x: centerX + 25, y: centerY)
            
            // Self circle in scene (becomes visible as we participate)
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize * 0.9, height: circleSize * 0.9)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: ColorPalette.selfCircleCore.opacity(0.3), radius: 6)
                .position(x: centerX - 25, y: centerY)
                .opacity(participationValue)
            
            // Labels inside scene
            Text("Other")
                .font(Typography.caption2)
                .foregroundStyle(ColorPalette.otherCircleCore)
                .position(x: centerX + 25, y: centerY + circleSize * 0.55)
            
            if participationValue > 0.3 {
                Text("Self")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorPalette.selfCircleCore)
                    .position(x: centerX - 25, y: centerY + circleSize * 0.55)
                    .opacity(min(1, (participationValue - 0.3) * 2))
            }
        }
        .opacity(clarity)
        .scaleEffect(scaleEffect)
        .blur(radius: blurAmount)
        .animation(.spring(response: 0.4), value: participationValue)
    }
    
    // MARK: - Observer Eye
    
    private func observerEye(geometry: GeometryProxy, centerX: CGFloat, centerY: CGFloat) -> some View {
        let eyeOpacity = max(0, 1 - participationValue * 1.5)
        let eyeY = centerY - geometry.size.height * 0.25
        
        return VStack(spacing: 4) {
            Image(systemName: "eye.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.secondary, Color.secondary.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("Observing")
                .font(Typography.caption2)
                .foregroundStyle(.secondary)
        }
        .opacity(eyeOpacity)
        .scaleEffect(1 - participationValue * 0.3)
        .position(x: centerX, y: eyeY)
        .animation(.spring(response: 0.3), value: participationValue)
    }
    
    // MARK: - Self Indicator (outside → inside)
    
    private func selfIndicator(geometry: GeometryProxy, centerX: CGFloat, centerY: CGFloat) -> some View {
        // Self starts outside the frame and moves inside
        let outsideY = centerY + geometry.size.height * 0.35
        let insideY = centerY
        let currentY = outsideY - (outsideY - insideY) * participationValue
        
        let indicatorOpacity = max(0, 1 - participationValue * 1.2)
        
        return VStack(spacing: 2) {
            // Small Self circle indicator
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                )
            
            // Arrow pointing up (entering)
            if participationValue < 0.5 {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ColorPalette.selfCircleCore)
                    .opacity(0.7)
            }
        }
        .opacity(indicatorOpacity)
        .position(x: centerX - 25, y: currentY)
        .animation(.spring(response: 0.4), value: participationValue)
    }
    
    // MARK: - Immersion Effect
    
    private func immersionEffect(geometry: GeometryProxy, centerX: CGFloat, centerY: CGFloat) -> some View {
        let showEffect = participationValue > 0.7
        let frameWidth = geometry.size.width * 0.65 * (1 + participationValue * 0.2)
        let frameHeight = geometry.size.height * 0.55 * (1 + participationValue * 0.2)
        
        return ZStack {
            // Glowing border when immersed
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            ColorPalette.selfCircleCore.opacity(0.6),
                            ColorPalette.otherCircleCore.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: frameWidth + 8, height: frameHeight + 8)
                .blur(radius: 4)
                .opacity(showEffect ? 1 : 0)
            
            // "Immersed" indicator
            if participationValue > 0.85 {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                    Text("Immersed")
                        .font(Typography.caption2)
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "81ECEC"), Color(hex: "74B9FF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .position(x: centerX, y: centerY - geometry.size.height * 0.22)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .position(x: centerX, y: centerY)
        .animation(
            showEffect
                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                : .spring(response: 0.3),
            value: showEffect
        )
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
                
                // Horizontal drag: right = more participation, left = more observation
                let dragSensitivity: CGFloat = 250
                let delta = value.translation.width / dragSensitivity
                let adjustedValue = participationValue + delta * 0.1
                
                // Haptic feedback at thresholds
                if abs(adjustedValue - lastHapticValue) >= hapticThreshold {
                    HapticManager.shared.lightImpact()
                    lastHapticValue = adjustedValue
                }
                
                // Special haptic when fully immersed
                if adjustedValue >= 0.98 && participationValue < 0.98 {
                    HapticManager.shared.success()
                }
                
                withAnimation(.interactiveSpring(response: 0.15)) {
                    participationValue = min(max(0, adjustedValue), 1)
                }
            }
            .onEnded { _ in
                isDragging = false
                onDraggingChanged?(false)
            }
    }
}

// MARK: - Preview

#Preview("Observation Circles") {
    struct PreviewWrapper: View {
        @State private var participation: Double = 0.3
        
        var body: some View {
            VStack {
                ObservationCirclesView(
                    participationValue: $participation,
                    onDraggingChanged: { _ in }
                )
                .frame(height: 350)
                
                Text("Participation: \(Int(participation * 100))%")
                    .font(Typography.headline)
                
                Slider(value: $participation, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Pure Observer") {
    struct PreviewWrapper: View {
        @State private var participation: Double = 0.0
        
        var body: some View {
            ObservationCirclesView(
                participationValue: $participation,
                onDraggingChanged: { _ in }
            )
            .frame(height: 350)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Fully Immersed") {
    struct PreviewWrapper: View {
        @State private var participation: Double = 0.95
        
        var body: some View {
            ObservationCirclesView(
                participationValue: $participation,
                onDraggingChanged: { _ in }
            )
            .frame(height: 350)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
