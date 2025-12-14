//
//  ProximityCirclesView.swift
//  IoS Scale
//
//  Interactive circles component for Proximity modality.
//  Features a connecting line showing distance, circles cannot overlap.
//

import SwiftUI

/// View displaying two interactive circles with a connecting line
/// Circles can be dragged closer but cannot overlap
struct ProximityCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Proximity value: 0 = far apart, 1 = touching
    @Binding var proximityValue: Double
    
    /// Normalized self position: 0 = left edge, 1 = right edge
    @Binding var selfPositionNormalized: Double
    
    /// Normalized other position: 0 = left edge, 1 = right edge
    @Binding var otherPositionNormalized: Double
    
    /// Callback when dragging starts or ends
    var onDraggingChanged: ((Bool) -> Void)?
    
    // State
    @State private var isDragging = false
    @State private var draggedCircle: DraggedCircle? = nil
    @State private var selfPosition: CGPoint = .zero
    @State private var otherPosition: CGPoint = .zero
    @State private var hasInitialized = false
    @State private var lastHapticValue: Double = 0
    
    private enum DraggedCircle {
        case selfCircle
        case otherCircle
    }
    
    // Layout constants
    private var circleSize: CGFloat {
        horizontalSizeClass == .regular ? 100 : 80
    }
    
    private let hapticThreshold: Double = 0.1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connecting line
                connectingLine(geometry: geometry)
                
                // Distance indicator on the line
                distanceIndicator(geometry: geometry)
                
                // Self circle (left)
                selfCircleView(geometry: geometry)
                
                // Other circle (right)
                otherCircleView(geometry: geometry)
                
                // Labels
                circleLabels(geometry: geometry)
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                // Initialize or update positions when geometry changes
                if !hasInitialized || abs(newSize.width - oldSize.width) > 10 {
                    initializePositions(geometry: geometry)
                    hasInitialized = true
                }
            }
            .onChange(of: proximityValue) { oldValue, newValue in
                // Update circle positions when proximityValue changes from slider
                // Only update if not currently dragging (to avoid conflicts)
                if draggedCircle == nil && hasInitialized {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        updatePositionsFromProximity(geometry: geometry)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Proximity measurement circles")
        .accessibilityValue("Proximity: \(Int(proximityValue * 100)) percent")
        .accessibilityHint("Drag circles closer or further apart")
    }
    
    // MARK: - Connecting Line
    
    private func connectingLine(geometry: GeometryProxy) -> some View {
        let selfPos = effectiveSelfPosition(geometry: geometry)
        let otherPos = effectiveOtherPosition(geometry: geometry)
        
        return Path { path in
            path.move(to: CGPoint(x: selfPos.x + circleSize / 2, y: selfPos.y))
            path.addLine(to: CGPoint(x: otherPos.x - circleSize / 2, y: otherPos.y))
        }
        .stroke(
            lineGradient,
            style: StrokeStyle(lineWidth: lineThickness, lineCap: .round)
        )
        .shadow(color: lineGlowColor, radius: 8)
    }
    
    private var lineGradient: LinearGradient {
        LinearGradient(
            colors: [
                ColorPalette.selfCircleCore.opacity(0.6),
                proximityValue > 0.7 ? Color(hex: "FFD700").opacity(0.8) : Color.gray.opacity(0.4),
                ColorPalette.otherCircleCore.opacity(0.6)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var lineThickness: CGFloat {
        // Line gets thicker as circles get closer
        3 + (proximityValue * 5)
    }
    
    private var lineGlowColor: Color {
        if proximityValue > 0.8 {
            return Color(hex: "FFD700").opacity(0.5)
        } else if proximityValue > 0.5 {
            return Color.purple.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Distance Indicator
    
    private func distanceIndicator(geometry: GeometryProxy) -> some View {
        let selfPos = effectiveSelfPosition(geometry: geometry)
        let otherPos = effectiveOtherPosition(geometry: geometry)
        let centerX = (selfPos.x + otherPos.x) / 2
        let centerY = selfPos.y
        
        return Group {
            if proximityValue >= 0.95 {
                // Heart or connection symbol when touching
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: 10)
                    .position(x: centerX, y: centerY)
            } else {
                // Pulsing dot on the line
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                proximityValue > 0.7 ? Color(hex: "FFD700") : Color.purple.opacity(0.6)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 8
                        )
                    )
                    .frame(width: 12 + proximityValue * 8, height: 12 + proximityValue * 8)
                    .shadow(color: proximityValue > 0.7 ? Color(hex: "FFD700").opacity(0.5) : Color.purple.opacity(0.3), radius: 6)
                    .position(x: centerX, y: centerY)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: proximityValue)
    }
    
    // MARK: - Self Circle
    
    private func selfCircleView(geometry: GeometryProxy) -> some View {
        let position = effectiveSelfPosition(geometry: geometry)
        let isBeingDragged = draggedCircle == .selfCircle
        
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
            .shadow(color: ColorPalette.selfCircleCore.opacity(isBeingDragged ? 0.6 : 0.3), radius: isBeingDragged ? 15 : 10)
            .scaleEffect(isBeingDragged ? 1.1 : 1.0)
            .position(position)
            .gesture(selfDragGesture(geometry: geometry))
            .animation(.spring(response: 0.3), value: isBeingDragged)
    }
    
    private func selfDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if draggedCircle == nil {
                    draggedCircle = .selfCircle
                    isDragging = true
                    onDraggingChanged?(true)
                    HapticManager.shared.lightImpact()
                }
                
                guard draggedCircle == .selfCircle else { return }
                
                let centerY = geometry.size.height / 2
                let minX = circleSize / 2 + 10
                let maxX = otherPosition.x - circleSize - 5 // Can't overlap other circle
                
                let newX = min(max(minX, value.location.x), maxX)
                selfPosition = CGPoint(x: newX, y: centerY)
                
                updateProximityValue(geometry: geometry)
            }
            .onEnded { _ in
                draggedCircle = nil
                isDragging = false
                onDraggingChanged?(false)
            }
    }
    
    // MARK: - Other Circle
    
    private func otherCircleView(geometry: GeometryProxy) -> some View {
        let position = effectiveOtherPosition(geometry: geometry)
        let isBeingDragged = draggedCircle == .otherCircle
        
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
            .shadow(color: ColorPalette.otherCircleCore.opacity(isBeingDragged ? 0.6 : 0.3), radius: isBeingDragged ? 15 : 10)
            .scaleEffect(isBeingDragged ? 1.1 : 1.0)
            .position(position)
            .gesture(otherDragGesture(geometry: geometry))
            .animation(.spring(response: 0.3), value: isBeingDragged)
    }
    
    private func otherDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if draggedCircle == nil {
                    draggedCircle = .otherCircle
                    isDragging = true
                    onDraggingChanged?(true)
                    HapticManager.shared.lightImpact()
                }
                
                guard draggedCircle == .otherCircle else { return }
                
                let centerY = geometry.size.height / 2
                let minX = selfPosition.x + circleSize + 5 // Can't overlap self circle
                let maxX = geometry.size.width - circleSize / 2 - 10
                
                let newX = min(max(minX, value.location.x), maxX)
                otherPosition = CGPoint(x: newX, y: centerY)
                
                updateProximityValue(geometry: geometry)
            }
            .onEnded { _ in
                draggedCircle = nil
                isDragging = false
                onDraggingChanged?(false)
            }
    }
    
    // MARK: - Labels
    
    private func circleLabels(geometry: GeometryProxy) -> some View {
        let selfPos = effectiveSelfPosition(geometry: geometry)
        let otherPos = effectiveOtherPosition(geometry: geometry)
        
        return ZStack {
            Text("Self")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.selfCircleCore)
                .position(x: selfPos.x, y: selfPos.y + circleSize / 2 + 18)
            
            Text("Other")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.otherCircleCore)
                .position(x: otherPos.x, y: otherPos.y + circleSize / 2 + 18)
        }
    }
    
    // MARK: - Position Helpers
    
    private func effectiveSelfPosition(geometry: GeometryProxy) -> CGPoint {
        if hasInitialized {
            return selfPosition
        } else {
            return calculateInitialSelfPosition(geometry: geometry)
        }
    }
    
    private func effectiveOtherPosition(geometry: GeometryProxy) -> CGPoint {
        if hasInitialized {
            return otherPosition
        } else {
            return calculateInitialOtherPosition(geometry: geometry)
        }
    }
    
    private func calculateInitialSelfPosition(geometry: GeometryProxy) -> CGPoint {
        let centerY = geometry.size.height / 2
        let maxDistance = geometry.size.width - circleSize - 40
        let currentDistance = maxDistance * (1 - proximityValue)
        let centerX = geometry.size.width / 2
        return CGPoint(x: centerX - currentDistance / 2, y: centerY)
    }
    
    private func calculateInitialOtherPosition(geometry: GeometryProxy) -> CGPoint {
        let centerY = geometry.size.height / 2
        let maxDistance = geometry.size.width - circleSize - 40
        let currentDistance = maxDistance * (1 - proximityValue)
        let centerX = geometry.size.width / 2
        return CGPoint(x: centerX + currentDistance / 2, y: centerY)
    }
    
    private func initializePositions(geometry: GeometryProxy) {
        selfPosition = calculateInitialSelfPosition(geometry: geometry)
        otherPosition = calculateInitialOtherPosition(geometry: geometry)
        updateNormalizedPositions(geometry: geometry)
    }
    
    private func updatePositionsFromProximity(geometry: GeometryProxy) {
        // Update circle positions based on the current proximityValue
        // This is called when the slider changes the value externally
        // ADAPTIVE: Keep current center point, adjust distance based on available space
        
        let centerY = geometry.size.height / 2
        
        // Calculate current center point between circles
        let currentCenterX = (selfPosition.x + otherPosition.x) / 2
        
        // Calculate max distance from center to each side
        let minSelfX = circleSize / 2 + 10
        let maxOtherX = geometry.size.width - circleSize / 2 - 10
        let spaceLeft = currentCenterX - minSelfX
        let spaceRight = maxOtherX - currentCenterX
        let maxHalfDistance = max(circleSize / 2, min(spaceLeft, spaceRight))
        
        // Calculate half distance based on proximity
        // When proximityValue = 0: circles are maxHalfDistance apart from center (far apart)
        // When proximityValue = 1: circles are circleSize/2 from center (touching)
        let halfDistance = maxHalfDistance * (1 - proximityValue) + (circleSize / 2) * proximityValue
        
        selfPosition = CGPoint(x: currentCenterX - halfDistance, y: centerY)
        otherPosition = CGPoint(x: currentCenterX + halfDistance, y: centerY)
        
        updateNormalizedPositions(geometry: geometry)
    }
    
    private func updateProximityValue(geometry: GeometryProxy) {
        // Calculate proximity based on distance between circles
        let distance = otherPosition.x - selfPosition.x - circleSize
        let maxDistance = geometry.size.width - circleSize * 2 - 40
        
        // Proximity: 0 = far, 1 = touching
        let newProximity = 1 - (distance / maxDistance)
        let clampedProximity = min(max(0, newProximity), 1)
        
        // Haptic feedback at thresholds
        if abs(clampedProximity - lastHapticValue) >= hapticThreshold {
            HapticManager.shared.lightImpact()
            lastHapticValue = clampedProximity
        }
        
        // Special haptic when touching
        if clampedProximity >= 0.98 && proximityValue < 0.98 {
            HapticManager.shared.success()
        }
        
        proximityValue = clampedProximity
        
        // Update normalized positions
        updateNormalizedPositions(geometry: geometry)
    }
    
    private func updateNormalizedPositions(geometry: GeometryProxy) {
        // Calculate normalized positions (0 = left edge, 1 = right edge)
        let minX = circleSize / 2 + 10
        let maxX = geometry.size.width - circleSize / 2 - 10
        let range = maxX - minX
        
        if range > 0 {
            selfPositionNormalized = (selfPosition.x - minX) / range
            otherPositionNormalized = (otherPosition.x - minX) / range
        }
    }
}

// MARK: - Preview

#Preview("Proximity Circles") {
    struct PreviewWrapper: View {
        @State private var proximity: Double = 0.3
        @State private var selfPos: Double = 0.25
        @State private var otherPos: Double = 0.75
        
        var body: some View {
            VStack {
                ProximityCirclesView(
                    proximityValue: $proximity,
                    selfPositionNormalized: $selfPos,
                    otherPositionNormalized: $otherPos,
                    onDraggingChanged: { _ in }
                )
                .frame(height: 300)
                
                Text("Proximity: \(Int(proximity * 100))%")
                    .font(Typography.headline)
                
                Text("Self: \(Int(selfPos * 100))% | Other: \(Int(otherPos * 100))%")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                
                Slider(value: $proximity, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Proximity - Close") {
    struct PreviewWrapper: View {
        @State private var proximity: Double = 0.9
        @State private var selfPos: Double = 0.4
        @State private var otherPos: Double = 0.6
        
        var body: some View {
            ProximityCirclesView(
                proximityValue: $proximity,
                selfPositionNormalized: $selfPos,
                otherPositionNormalized: $otherPos,
                onDraggingChanged: { _ in }
            )
            .frame(height: 300)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
