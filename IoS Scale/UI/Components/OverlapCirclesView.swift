//
//  OverlapCirclesView.swift
//  IoS Scale
//
//  Interactive circles component for Overlap modality.
//  Features highlighted intersection zone and vertical drag gesture.
//

import SwiftUI

/// View displaying two interactive circles with emphasized overlap visualization
/// Uses vertical drag to adjust overlap amount
struct OverlapCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// The overlap value between 0 (no overlap) and 1 (complete overlap)
    @Binding var overlapValue: Double
    
    /// Callback when dragging starts or ends
    var onDraggingChanged: ((Bool) -> Void)?
    
    // State
    @State private var isDragging = false
    @State private var initialOverlapValue: Double = 0
    @State private var lastHapticValue: Double = 0
    
    // Constants
    private let hapticThreshold: Double = 0.05
    
    var body: some View {
        GeometryReader { geometry in
            let circleDiameter = calculateCircleDiameter(for: geometry.size)
            let positions = calculatePositions(
                containerSize: geometry.size,
                circleDiameter: circleDiameter
            )
            
            ZStack {
                // Background intersection zone highlight (always visible when overlapping)
                if overlapValue > 0.02 {
                    intersectionHighlight(
                        diameter: circleDiameter,
                        positions: positions,
                        containerSize: geometry.size
                    )
                }
                
                // Self circle (left)
                overlappingCircle(
                    type: .selfCircle,
                    diameter: circleDiameter,
                    position: positions.selfCenter
                )
                
                // Other circle (right)
                overlappingCircle(
                    type: .otherCircle,
                    diameter: circleDiameter,
                    position: positions.otherCenter
                )
                
                // Intersection zone overlay (prominent)
                if overlapValue > 0.05 {
                    intersectionZone(
                        diameter: circleDiameter,
                        positions: positions
                    )
                }
                
                // Drag indicator
                dragIndicator(in: geometry.size)
                
                // Labels
                circleLabels(positions: positions, diameter: circleDiameter)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(createVerticalDragGesture(in: geometry.size))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overlap measurement circles")
        .accessibilityValue("Overlap: \(Int(overlapValue * 100)) percent")
        .accessibilityHint("Drag up to increase overlap, down to decrease")
    }
    
    // MARK: - Circle Positioning
    
    private struct CirclePositions {
        let selfCenter: CGPoint
        let otherCenter: CGPoint
    }
    
    private func calculateCircleDiameter(for size: CGSize) -> CGFloat {
        let baseDiameter = horizontalSizeClass == .regular
            ? LayoutConstants.circleBaseDiameterPad
            : LayoutConstants.circleBaseDiameter
        
        // Ensure circles fit in container
        let maxDiameter = min(size.width / 2.2, size.height * 0.6)
        return min(baseDiameter, maxDiameter)
    }
    
    private func calculatePositions(
        containerSize: CGSize,
        circleDiameter: CGFloat
    ) -> CirclePositions {
        let centerY = containerSize.height * 0.4
        
        // Calculate horizontal positions based on overlap
        // overlap = 0 -> circles just touching (separation = diameter)
        // overlap = 1 -> circles completely overlap (same position, separation = 0)
        let maxSeparation = circleDiameter  // Circles just touching when overlap = 0
        let minSeparation: CGFloat = 0  // Fully merged when overlap = 1
        
        let separation = maxSeparation * (1 - overlapValue)
        
        let centerX = containerSize.width / 2
        
        return CirclePositions(
            selfCenter: CGPoint(x: centerX - separation / 2, y: centerY),
            otherCenter: CGPoint(x: centerX + separation / 2, y: centerY)
        )
    }
    
    // MARK: - Visual Components
    
    @ViewBuilder
    private func overlappingCircle(type: CircleType, diameter: CGFloat, position: CGPoint) -> some View {
        Circle()
            .fill(type == .selfCircle ? ColorPalette.selfCircleGradient : ColorPalette.otherCircleGradient)
            .frame(width: diameter, height: diameter)
            .shadow(
                color: type == .selfCircle
                    ? ColorPalette.selfCircleGlow.opacity(isDragging ? 0.6 : 0.4)
                    : ColorPalette.otherCircleGlow.opacity(isDragging ? 0.6 : 0.4),
                radius: isDragging ? 20 : 15
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        type == .selfCircle
                            ? ColorPalette.selfCircleGlow.opacity(0.5)
                            : ColorPalette.otherCircleGlow.opacity(0.5),
                        lineWidth: 2
                    )
            )
            .position(position)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: overlapValue)
    }
    
    @ViewBuilder
    private func intersectionHighlight(
        diameter: CGFloat,
        positions: CirclePositions,
        containerSize: CGSize
    ) -> some View {
        // Subtle background glow for intersection area
        let glowSize = diameter * overlapValue * 1.5
        
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: "FFD700").opacity(0.2 * overlapValue),  // Golden glow
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: glowSize / 2
                )
            )
            .frame(width: glowSize, height: glowSize)
            .position(
                x: (positions.selfCenter.x + positions.otherCenter.x) / 2,
                y: positions.selfCenter.y
            )
            .blur(radius: 20)
    }
    
    @ViewBuilder
    private func intersectionZone(
        diameter: CGFloat,
        positions: CirclePositions
    ) -> some View {
        // Lens-shaped intersection zone
        let intersectionWidth = diameter * overlapValue * 0.8
        let intersectionHeight = diameter * min(0.9, 0.4 + overlapValue * 0.5)
        
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "FFD700").opacity(0.6),  // Golden
                        Color(hex: "FFA500").opacity(0.6)   // Orange
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: intersectionWidth, height: intersectionHeight)
            .overlay(
                Ellipse()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color(hex: "FFD700").opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 10)
            .position(
                x: (positions.selfCenter.x + positions.otherCenter.x) / 2,
                y: positions.selfCenter.y
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: overlapValue)
    }
    
    @ViewBuilder
    private func dragIndicator(in size: CGSize) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "chevron.up")
                .font(.system(size: 16, weight: .semibold))
            
            Text("Drag to adjust")
                .font(Typography.caption)
            
            Image(systemName: "chevron.down")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(.secondary.opacity(isDragging ? 0.3 : 0.6))
        .position(x: size.width / 2, y: size.height * 0.85)
        .opacity(isDragging ? 0.3 : 1)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }
    
    @ViewBuilder
    private func circleLabels(positions: CirclePositions, diameter: CGFloat) -> some View {
        // Self label
        Text("Self")
            .font(Typography.caption)
            .foregroundStyle(.secondary)
            .position(
                x: positions.selfCenter.x - diameter * 0.4,
                y: positions.selfCenter.y + diameter * 0.7
            )
        
        // Other label
        Text("Other")
            .font(Typography.caption)
            .foregroundStyle(.secondary)
            .position(
                x: positions.otherCenter.x + diameter * 0.4,
                y: positions.otherCenter.y + diameter * 0.7
            )
    }
    
    // MARK: - Gestures
    
    private func createVerticalDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                // Set initial value on drag start
                if !isDragging {
                    initialOverlapValue = overlapValue
                    lastHapticValue = overlapValue
                    isDragging = true
                    onDraggingChanged?(true)
                }
                
                // Vertical drag: up = more overlap, down = less overlap
                let dragRange = size.height * 0.4
                let normalizedDelta = -value.translation.height / dragRange
                
                let newValue = min(max(0, initialOverlapValue + normalizedDelta), 1)
                
                // Haptic feedback at thresholds
                if abs(newValue - lastHapticValue) >= hapticThreshold {
                    HapticManager.shared.lightImpact()
                    lastHapticValue = newValue
                }
                
                // Boundary haptic
                if (newValue <= 0.01 && overlapValue > 0.01) || (newValue >= 0.99 && overlapValue < 0.99) {
                    HapticManager.shared.boundaryReached()
                }
                
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
                    overlapValue = newValue
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isDragging = false
                    onDraggingChanged?(false)
                }
            }
    }
}

// MARK: - Preview

#Preview("Overlap Circles") {
    struct PreviewWrapper: View {
        @State private var overlap = 0.3
        
        var body: some View {
            VStack {
                OverlapCirclesView(
                    overlapValue: $overlap,
                    onDraggingChanged: { _ in }
                )
                .frame(height: 350)
                
                HStack {
                    Text("Overlap:")
                        .foregroundStyle(.secondary)
                    Text("\(Int(overlap * 100))%")
                        .fontWeight(.semibold)
                }
                .font(Typography.body)
                
                Slider(value: $overlap, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Full Overlap") {
    struct PreviewWrapper: View {
        @State private var overlap = 0.95
        
        var body: some View {
            OverlapCirclesView(
                overlapValue: $overlap,
                onDraggingChanged: { _ in }
            )
            .frame(height: 350)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
