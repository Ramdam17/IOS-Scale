//
//  ProjectionCirclesView.swift
//  IoS Scale
//
//  Interactive circles component for Projection modality.
//  Self moves toward and into Other, projecting qualities onto Other.
//  Direction: Self → Other (Self projects onto Other)
//  Opposite of Identification where Other → Self
//

import SwiftUI

/// View displaying projection interaction where Self moves into Other
struct ProjectionCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Projection value: 0 = separate, 1 = fully projected
    @Binding var projectionValue: Double
    
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
                // Direction arrow (Self → Other)
                directionArrow(from: selfCenter, to: otherCenter, geometry: geometry)
                
                // Other circle (stationary, receives Self's projection)
                otherCircleView(position: otherCenter, geometry: geometry)
                
                // Self circle (moves toward Other)
                selfCircleView(position: selfCenter, geometry: geometry)
                
                // Projection effect overlay on Other
                projectionEffect(position: otherCenter, geometry: geometry)
                
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
        .accessibilityLabel("Projection measurement")
        .accessibilityValue("Projection: \(Int(projectionValue * 100)) percent")
        .accessibilityHint("Drag right to increase projection, left to decrease")
    }
    
    // MARK: - Positions
    
    private func selfPosition(geometry: GeometryProxy) -> CGPoint {
        // Self moves from left toward Other based on projectionValue
        let centerY = geometry.size.height * 0.4
        let startX = geometry.size.width * 0.35 // Starting position (left)
        let otherX = geometry.size.width * 0.65
        
        // At value=1, Self is at same position as Other (fully projected)
        let currentX = startX + (otherX - startX) * projectionValue
        
        return CGPoint(x: currentX, y: centerY)
    }
    
    private func otherPosition(geometry: GeometryProxy) -> CGPoint {
        // Other stays on the right, stationary
        let centerY = geometry.size.height * 0.4
        let x = geometry.size.width * 0.65
        return CGPoint(x: x, y: centerY)
    }
    
    // MARK: - Direction Arrow
    
    private func directionArrow(from: CGPoint, to: CGPoint, geometry: GeometryProxy) -> some View {
        let arrowOpacity = max(0, 1 - projectionValue * 1.5) // Fades as projection increases
        
        return ZStack {
            // Arrow line
            Path { path in
                let startX = geometry.size.width * 0.35 + circleSize / 2 + 10
                let endX = to.x - circleSize / 2 - 20
                let y = geometry.size.height * 0.4
                path.move(to: CGPoint(x: startX, y: y))
                path.addLine(to: CGPoint(x: endX, y: y))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        ColorPalette.selfCircleCore.opacity(0.6),
                        ColorPalette.otherCircleCore.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6])
            )
            .opacity(arrowOpacity)
            
            // Arrow head pointing to Other
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ColorPalette.otherCircleCore.opacity(0.7))
                .position(x: to.x - circleSize / 2 - 30, y: to.y)
                .opacity(arrowOpacity)
        }
    }
    
    // MARK: - Self Circle
    
    private func selfCircleView(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Self circle fades and shrinks as it projects onto Other
        let fadeAmount = 1 - projectionValue * 0.8
        let scaleAmount = 1 - projectionValue * 0.5
        
        return Circle()
            .fill(ColorPalette.selfCircleGradient)
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
            .shadow(color: ColorPalette.selfCircleCore.opacity(0.3 * fadeAmount), radius: 10)
            .scaleEffect(scaleAmount)
            .opacity(fadeAmount)
            .position(position)
            .animation(.spring(response: 0.3), value: projectionValue)
    }
    
    // MARK: - Other Circle
    
    private func otherCircleView(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Other circle gets a blue tint as it receives Self's projection
        let blendAmount = projectionValue
        
        return ZStack {
            // Base Other circle
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
            
            // Self's color blending in
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .opacity(blendAmount * 0.6)
            
            // Glow effect when receiving projection
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "00CED1").opacity(blendAmount * 0.4), // Cyan glow
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
                            blendAmount > 0.5 ? Color(hex: "00CED1").opacity(0.5) : Color.white.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: circleSize, height: circleSize)
        )
        .shadow(
            color: blendAmount > 0.7 ? Color(hex: "00CED1").opacity(0.5) : ColorPalette.otherCircleCore.opacity(0.3),
            radius: 10 + blendAmount * 10
        )
        .position(position)
        .animation(.spring(response: 0.3), value: projectionValue)
    }
    
    // MARK: - Projection Effect
    
    private func projectionEffect(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Pulsing rings when projection is high
        let showEffect = projectionValue > 0.7
        
        return ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color(hex: "00CED1").opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
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
        let selfLabelX = geometry.size.width * 0.35 // Fixed position for Self label
        let centerY = geometry.size.height * 0.4
        
        return ZStack {
            // Self label (fades with circle)
            Text("Self")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.selfCircleCore)
                .opacity(1 - projectionValue * 0.8)
                .position(x: selfLabelX, y: centerY + circleSize / 2 + 18)
            
            // Other label
            Text("Other")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.otherCircleCore)
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
                
                // Horizontal drag: right = more projection (Self moves toward Other), left = less
                let dragSensitivity: CGFloat = 250
                let delta = value.translation.width / dragSensitivity
                let adjustedValue = projectionValue + delta * 0.1
                
                // Haptic feedback at thresholds
                if abs(adjustedValue - lastHapticValue) >= hapticThreshold {
                    HapticManager.shared.lightImpact()
                    lastHapticValue = adjustedValue
                }
                
                // Special haptic when fully projected
                if adjustedValue >= 0.98 && projectionValue < 0.98 {
                    HapticManager.shared.success()
                }
                
                withAnimation(.interactiveSpring(response: 0.15)) {
                    projectionValue = min(max(0, adjustedValue), 1)
                }
            }
            .onEnded { _ in
                isDragging = false
                onDraggingChanged?(false)
            }
    }
}

// MARK: - Preview

#Preview("Projection Circles") {
    struct PreviewWrapper: View {
        @State private var projection: Double = 0.3
        
        var body: some View {
            VStack {
                ProjectionCirclesView(
                    projectionValue: $projection,
                    onDraggingChanged: { _ in }
                )
                .frame(height: 300)
                
                Text("Projection: \(Int(projection * 100))%")
                    .font(Typography.headline)
                
                Slider(value: $projection, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Fully Projected") {
    struct PreviewWrapper: View {
        @State private var projection: Double = 0.95
        
        var body: some View {
            ProjectionCirclesView(
                projectionValue: $projection,
                onDraggingChanged: { _ in }
            )
            .frame(height: 300)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
