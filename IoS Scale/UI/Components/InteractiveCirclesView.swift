//
//  InteractiveCirclesView.swift
//  IoS Scale
//
//  The main interactive component showing two circles for IOS Scale measurements.
//

import SwiftUI

/// View displaying two interactive circles with overlap visualization
struct InteractiveCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// The overlap value between 0 (distant) and 1 (merged)
    @Binding var overlapValue: Double
    
    /// Optional self circle scale (for Advanced IOS)
    @Binding var selfScale: Double
    
    /// Optional other circle scale (for Advanced IOS)
    @Binding var otherScale: Double
    
    /// Whether scaling is enabled (Advanced IOS mode)
    var scalingEnabled: Bool = false
    
    /// Callback when dragging starts or ends
    var onDraggingChanged: ((Bool) -> Void)?
    
    // State
    @State private var isDraggingSelf = false
    @State private var isDraggingOther = false
    @State private var initialOverlapValue: Double = 0
    @State private var lastHapticValue: Double = 0
    
    // Constants
    private let hapticThreshold: Double = 0.05
    
    var body: some View {
        GeometryReader { geometry in
            let circleDiameter = calculateCircleDiameter(for: geometry.size)
            let positions = calculatePositions(
                containerWidth: geometry.size.width,
                circleDiameter: circleDiameter
            )
            
            ZStack {
                // Connection line (optional visual)
                if overlapValue < 0.3 {
                    connectionLine(
                        from: positions.selfCenter,
                        to: positions.otherCenter,
                        opacity: 1 - (overlapValue / 0.3)
                    )
                }
                
                // Overlap zone (when circles intersect)
                if overlapValue > 0.1 {
                    overlapZone(
                        diameter: circleDiameter,
                        positions: positions
                    )
                }
                
                // Self circle (left)
                CircleView(
                    type: .selfCircle,
                    diameter: circleDiameter,
                    scale: selfScale,
                    isDragging: isDraggingSelf
                )
                .position(positions.selfCenter)
                .gesture(createDragGesture(
                    containerWidth: geometry.size.width,
                    circleDiameter: circleDiameter,
                    isSelf: true
                ))
                .simultaneousGesture(scalingEnabled ? createScaleGesture(isSelf: true) : nil)
                
                // Other circle (right)
                CircleView(
                    type: .otherCircle,
                    diameter: circleDiameter,
                    scale: otherScale,
                    isDragging: isDraggingOther
                )
                .position(positions.otherCenter)
                .gesture(createDragGesture(
                    containerWidth: geometry.size.width,
                    circleDiameter: circleDiameter,
                    isSelf: false
                ))
                .simultaneousGesture(scalingEnabled ? createScaleGesture(isSelf: false) : nil)
                
                // Labels
                VStack {
                    Spacer()
                    HStack {
                        Text("Self")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Other")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, Spacing.xl)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("IOS Scale circles")
        .accessibilityValue("Overlap: \(Int(overlapValue * 100)) percent")
        .accessibilityHint("Drag circles horizontally to adjust closeness")
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
        
        // Ensure circles fit in container with some padding
        let maxDiameter = min(size.width / 2.5, size.height * 0.6)
        return min(baseDiameter, maxDiameter)
    }
    
    private func calculatePositions(
        containerWidth: CGFloat,
        circleDiameter: CGFloat
    ) -> CirclePositions {
        let centerY = circleDiameter / 2 + Spacing.xl
        let padding = circleDiameter * 0.3
        
        // Calculate the range of movement
        let minSeparation: CGFloat = 0 // Fully merged (same position)
        let maxSeparation = containerWidth - circleDiameter - padding * 2
        
        // Map overlap value to separation
        // overlapValue = 0 -> max separation (distant)
        // overlapValue = 1 -> min separation (merged/overlapping)
        let separation = maxSeparation - overlapValue * (maxSeparation - minSeparation)
        
        let centerX = containerWidth / 2
        let selfCenterX = centerX - separation / 2
        let otherCenterX = centerX + separation / 2
        
        return CirclePositions(
            selfCenter: CGPoint(x: selfCenterX, y: centerY),
            otherCenter: CGPoint(x: otherCenterX, y: centerY)
        )
    }
    
    // MARK: - Gestures
    
    private func createDragGesture(
        containerWidth: CGFloat,
        circleDiameter: CGFloat,
        isSelf: Bool
    ) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                // Set initial value on drag start
                if !isDraggingSelf && !isDraggingOther {
                    initialOverlapValue = overlapValue
                    lastHapticValue = overlapValue
                }
                
                if isSelf {
                    isDraggingSelf = true
                } else {
                    isDraggingOther = true
                }
                onDraggingChanged?(true)
                
                // Calculate movement range
                let movementRange = containerWidth * 0.4
                
                // Calculate delta based on drag translation
                // Self dragging right = increase overlap (circles closer)
                // Other dragging left = increase overlap (circles closer)
                let dragDelta = isSelf ? value.translation.width : -value.translation.width
                let normalizedDelta = dragDelta / movementRange
                
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
                    isDraggingSelf = false
                    isDraggingOther = false
                    onDraggingChanged?(false)
                }
            }
    }
    
    private func createScaleGesture(isSelf: Bool) -> some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let currentScale = isSelf ? selfScale : otherScale
                let newScale = min(max(
                    LayoutConstants.minCircleScale,
                    currentScale * scale
                ), LayoutConstants.maxCircleScale)
                
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7)) {
                    if isSelf {
                        selfScale = newScale
                    } else {
                        otherScale = newScale
                    }
                }
            }
    }
    
    // MARK: - Visual Elements
    
    @ViewBuilder
    private func connectionLine(from: CGPoint, to: CGPoint, opacity: Double) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            colorScheme == .dark
                ? Color.white.opacity(0.2 * opacity)
                : Color.black.opacity(0.1 * opacity),
            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
        )
    }
    
    @ViewBuilder
    private func overlapZone(diameter: CGFloat, positions: CirclePositions) -> some View {
        let overlapIntensity = min(1, overlapValue * 1.5)
        
        Ellipse()
            .fill(ColorPalette.overlapGradient.opacity(overlapIntensity * 0.6))
            .frame(
                width: diameter * 0.3 * overlapValue,
                height: diameter * 0.8
            )
            .position(
                x: (positions.selfCenter.x + positions.otherCenter.x) / 2,
                y: positions.selfCenter.y
            )
            .blur(radius: 10)
    }
}

// MARK: - Preview

#Preview("Interactive") {
    struct PreviewWrapper: View {
        @State private var overlap = 0.3
        @State private var selfScale = 1.0
        @State private var otherScale = 1.0
        
        var body: some View {
            VStack {
                InteractiveCirclesView(
                    overlapValue: $overlap,
                    selfScale: $selfScale,
                    otherScale: $otherScale
                )
                .frame(height: 250)
                
                IOSSlider(value: $overlap)
                    .padding(.horizontal, Spacing.lg)
                
                Text("Overlap: \(overlap, specifier: "%.2f")")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("With Scaling") {
    struct PreviewWrapper: View {
        @State private var overlap = 0.5
        @State private var selfScale = 1.0
        @State private var otherScale = 1.5
        
        var body: some View {
            VStack {
                InteractiveCirclesView(
                    overlapValue: $overlap,
                    selfScale: $selfScale,
                    otherScale: $otherScale,
                    scalingEnabled: true
                )
                .frame(height: 300)
                
                HStack {
                    Text("Self: \(selfScale, specifier: "%.1f")x")
                    Spacer()
                    Text("Other: \(otherScale, specifier: "%.1f")x")
                }
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
