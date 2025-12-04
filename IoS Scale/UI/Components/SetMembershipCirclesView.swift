//
//  SetMembershipCirclesView.swift
//  IoS Scale
//
//  Interactive circles component for Set Membership modality.
//  Features a rectangle "set" and two draggable circles.
//

import SwiftUI

/// View displaying a "set" rectangle with two interactive circles
/// that can be dragged inside or outside the set
struct SetMembershipCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Whether Self is inside the set
    @Binding var selfInSet: Bool
    
    /// Whether Other is inside the set
    @Binding var otherInSet: Bool
    
    /// Callback when dragging starts or ends
    var onDraggingChanged: ((Bool) -> Void)?
    
    /// Callback to toggle Self in/out (triggered by external button)
    var onToggleSelf: (() -> Void)?
    
    /// Callback to toggle Other in/out (triggered by external button)
    var onToggleOther: (() -> Void)?
    
    // State
    @State private var selfPosition: CGPoint = .zero
    @State private var otherPosition: CGPoint = .zero
    @State private var isDraggingSelf = false
    @State private var isDraggingOther = false
    @State private var hasInitialized = false
    @State private var currentGeometry: GeometryProxy?
    
    // Layout constants
    private var setWidth: CGFloat {
        horizontalSizeClass == .regular ? 280 : 200
    }
    
    private var setHeight: CGFloat {
        horizontalSizeClass == .regular ? 180 : 140
    }
    
    private var circleSize: CGFloat {
        horizontalSizeClass == .regular ? 80 : 70
    }
    
    // Outside positions - clearly outside the set but visible on screen
    private func outsideLeftX(geometry: GeometryProxy) -> CGFloat {
        // Position Self circle to the left, ensuring it stays fully visible
        // At minimum: circleSize/2 margin from edge
        let minX = circleSize / 2 + 10
        let center = geometry.size.width / 2
        let idealX = center - setWidth / 2 - circleSize / 2 - 15
        return max(minX, idealX)
    }
    
    private func outsideRightX(geometry: GeometryProxy) -> CGFloat {
        // Position Other circle to the right, ensuring it stays fully visible
        let maxX = geometry.size.width - circleSize / 2 - 10
        let center = geometry.size.width / 2
        let idealX = center + setWidth / 2 + circleSize / 2 + 15
        return min(maxX, idealX)
    }
    
    // Inside positions - clearly inside the set
    private func insideLeftX(geometry: GeometryProxy) -> CGFloat {
        let center = geometry.size.width / 2
        return center - setWidth / 4 + circleSize / 4
    }
    
    private func insideRightX(geometry: GeometryProxy) -> CGFloat {
        let center = geometry.size.width / 2
        return center + setWidth / 4 - circleSize / 4
    }
    
    private func insideCenterX(geometry: GeometryProxy) -> CGFloat {
        geometry.size.width / 2
    }
    
    // MARK: - Computed Positions
    
    /// Calculate the correct X position for Self circle
    private func selfTargetX(geometry: GeometryProxy) -> CGFloat {
        if selfInSet {
            return otherInSet ? insideLeftX(geometry: geometry) : insideCenterX(geometry: geometry)
        } else {
            return outsideLeftX(geometry: geometry)
        }
    }
    
    /// Calculate the correct X position for Other circle
    private func otherTargetX(geometry: GeometryProxy) -> CGFloat {
        if otherInSet {
            return selfInSet ? insideRightX(geometry: geometry) : insideCenterX(geometry: geometry)
        } else {
            return outsideRightX(geometry: geometry)
        }
    }
    
    /// Get the actual Self position (computed if not yet initialized, state otherwise)
    private func effectiveSelfPosition(geometry: GeometryProxy, setRect: CGRect) -> CGPoint {
        if hasInitialized {
            return selfPosition
        } else {
            return CGPoint(x: selfTargetX(geometry: geometry), y: setRect.midY)
        }
    }
    
    /// Get the actual Other position (computed if not yet initialized, state otherwise)
    private func effectiveOtherPosition(geometry: GeometryProxy, setRect: CGRect) -> CGPoint {
        if hasInitialized {
            return otherPosition
        } else {
            return CGPoint(x: otherTargetX(geometry: geometry), y: setRect.midY)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let setRect = CGRect(
                x: center.x - setWidth / 2,
                y: center.y - setHeight / 2,
                width: setWidth,
                height: setHeight
            )
            
            ZStack {
                // The "set" rectangle
                setRectangleView(setRect: setRect)
                
                // Set label
                VStack {
                    Text("THE SET")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.top, center.y - setHeight / 2 - 30)
                    Spacer()
                }
                
                // Self circle
                selfCircleView(geometry: geometry, setRect: setRect)
                
                // Other circle
                otherCircleView(geometry: geometry, setRect: setRect)
                
                // Labels
                circleLabels(geometry: geometry, setRect: setRect)
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                // Always reinitialize when geometry changes significantly
                let heightDiff = abs(newSize.height - oldSize.height)
                if heightDiff > 10 && newSize.height > 50 {
                    let newSetRect = CGRect(
                        x: newSize.width / 2 - setWidth / 2,
                        y: newSize.height / 2 - setHeight / 2,
                        width: setWidth,
                        height: setHeight
                    )
                    initializePositions(geometry: geometry, setRect: newSetRect)
                    hasInitialized = true
                    currentGeometry = geometry
                }
            }
            .onChange(of: selfInSet) { oldValue, newValue in
                // Only react to external changes (not from dragging)
                if !isDraggingSelf && hasInitialized {
                    snapSelfPosition(setRect: setRect, geometry: geometry)
                    // Also adjust other if needed
                    snapOtherPosition(setRect: setRect, geometry: geometry)
                }
            }
            .onChange(of: otherInSet) { oldValue, newValue in
                // Only react to external changes (not from dragging)
                if !isDraggingOther && hasInitialized {
                    snapOtherPosition(setRect: setRect, geometry: geometry)
                    // Also adjust self if needed
                    snapSelfPosition(setRect: setRect, geometry: geometry)
                }
            }
        }
    }
    
    // MARK: - Set Rectangle
    
    private func setRectangleView(setRect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(setFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(setBorderGradient, lineWidth: 3)
            )
            .frame(width: setWidth, height: setHeight)
            .position(x: setRect.midX, y: setRect.midY)
            .shadow(color: setGlowColor, radius: 15)
    }
    
    private var setFillColor: some ShapeStyle {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.03)
    }
    
    private var setBorderGradient: some ShapeStyle {
        LinearGradient(
            colors: membershipBorderColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var membershipBorderColors: [Color] {
        let bothIn = selfInSet && otherInSet
        let noneIn = !selfInSet && !otherInSet
        
        if bothIn {
            // Golden glow when both are in
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        } else if noneIn {
            // Gray when neither
            return [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
        } else {
            // Mixed colors when partial
            return [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]
        }
    }
    
    private var setGlowColor: Color {
        if selfInSet && otherInSet {
            return Color(hex: "FFD700").opacity(0.3)
        } else if !selfInSet && !otherInSet {
            return Color.gray.opacity(0.1)
        } else {
            return Color.purple.opacity(0.2)
        }
    }
    
    // MARK: - Self Circle
    
    private func selfCircleView(geometry: GeometryProxy, setRect: CGRect) -> some View {
        let position = effectiveSelfPosition(geometry: geometry, setRect: setRect)
        
        return Circle()
            .fill(ColorPalette.selfCircleGradient)
            .frame(width: circleSize, height: circleSize)
            .overlay(
                Circle()
                    .strokeBorder(
                        selfInSet
                            ? LinearGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
            )
            .shadow(color: ColorPalette.selfCircleCore.opacity(isDraggingSelf ? 0.6 : 0.3), radius: isDraggingSelf ? 15 : 8)
            .scaleEffect(isDraggingSelf ? 1.1 : 1.0)
            .position(position)
            .gesture(selfDragGesture(geometry: geometry, setRect: setRect))
            .animation(.spring(response: 0.3), value: isDraggingSelf)
            .animation(.spring(response: 0.3), value: selfInSet)
            .accessibilityLabel("Self circle")
            .accessibilityValue(selfInSet ? "Inside the set" : "Outside the set")
            .accessibilityHint("Drag to move inside or outside the set")
    }
    
    private func selfDragGesture(geometry: GeometryProxy, setRect: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDraggingSelf {
                    isDraggingSelf = true
                    onDraggingChanged?(true)
                    HapticManager.shared.lightImpact()
                }
                
                // HORIZONTAL DRAG ONLY - keep Y fixed at set center
                let centerY = setRect.midY
                let newX = min(max(circleSize / 2, value.location.x), geometry.size.width - circleSize / 2)
                selfPosition = CGPoint(x: newX, y: centerY)
                
                // Check if inside set (based on X position relative to set bounds)
                let inSet = isCircleInSet(position: selfPosition, setRect: setRect)
                if inSet != selfInSet {
                    selfInSet = inSet
                    HapticManager.shared.mediumImpact()
                }
            }
            .onEnded { _ in
                isDraggingSelf = false
                onDraggingChanged?(false)
                
                // Snap to the exact same positions as the buttons
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    let centerY = setRect.midY
                    if selfInSet {
                        // Inside: use exact button position logic
                        let targetX = otherInSet ? insideLeftX(geometry: geometry) : insideCenterX(geometry: geometry)
                        selfPosition = CGPoint(x: targetX, y: centerY)
                        // Also reposition other if needed
                        if otherInSet {
                            otherPosition = CGPoint(x: insideRightX(geometry: geometry), y: centerY)
                        }
                    } else {
                        // Outside: exact left position
                        selfPosition = CGPoint(x: outsideLeftX(geometry: geometry), y: centerY)
                        // If other is now alone inside, center it
                        if otherInSet {
                            otherPosition = CGPoint(x: insideCenterX(geometry: geometry), y: centerY)
                        }
                    }
                }
            }
    }
    
    // MARK: - Other Circle
    
    private func otherCircleView(geometry: GeometryProxy, setRect: CGRect) -> some View {
        let position = effectiveOtherPosition(geometry: geometry, setRect: setRect)
        
        return Circle()
            .fill(ColorPalette.otherCircleGradient)
            .frame(width: circleSize, height: circleSize)
            .overlay(
                Circle()
                    .strokeBorder(
                        otherInSet
                            ? LinearGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
            )
            .shadow(color: ColorPalette.otherCircleCore.opacity(isDraggingOther ? 0.6 : 0.3), radius: isDraggingOther ? 15 : 8)
            .scaleEffect(isDraggingOther ? 1.1 : 1.0)
            .position(position)
            .gesture(otherDragGesture(geometry: geometry, setRect: setRect))
            .animation(.spring(response: 0.3), value: isDraggingOther)
            .animation(.spring(response: 0.3), value: otherInSet)
            .accessibilityLabel("Other circle")
            .accessibilityValue(otherInSet ? "Inside the set" : "Outside the set")
            .accessibilityHint("Drag to move inside or outside the set")
    }
    
    private func otherDragGesture(geometry: GeometryProxy, setRect: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDraggingOther {
                    isDraggingOther = true
                    onDraggingChanged?(true)
                    HapticManager.shared.lightImpact()
                }
                
                // HORIZONTAL DRAG ONLY - keep Y fixed at set center
                let centerY = setRect.midY
                let newX = min(max(circleSize / 2, value.location.x), geometry.size.width - circleSize / 2)
                otherPosition = CGPoint(x: newX, y: centerY)
                
                // Check if inside set (based on X position relative to set bounds)
                let inSet = isCircleInSet(position: otherPosition, setRect: setRect)
                if inSet != otherInSet {
                    otherInSet = inSet
                    HapticManager.shared.mediumImpact()
                }
            }
            .onEnded { _ in
                isDraggingOther = false
                onDraggingChanged?(false)
                
                // Snap to the exact same positions as the buttons
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    let centerY = setRect.midY
                    if otherInSet {
                        // Inside: use exact button position logic
                        let targetX = selfInSet ? insideRightX(geometry: geometry) : insideCenterX(geometry: geometry)
                        otherPosition = CGPoint(x: targetX, y: centerY)
                        // Also reposition self if needed
                        if selfInSet {
                            selfPosition = CGPoint(x: insideLeftX(geometry: geometry), y: centerY)
                        }
                    } else {
                        // Outside: exact right position
                        otherPosition = CGPoint(x: outsideRightX(geometry: geometry), y: centerY)
                        // If self is now alone inside, center it
                        if selfInSet {
                            selfPosition = CGPoint(x: insideCenterX(geometry: geometry), y: centerY)
                        }
                    }
                }
            }
    }
    
    // MARK: - Circle Labels
    
    private func circleLabels(geometry: GeometryProxy, setRect: CGRect) -> some View {
        let selfPos = effectiveSelfPosition(geometry: geometry, setRect: setRect)
        let otherPos = effectiveOtherPosition(geometry: geometry, setRect: setRect)
        
        return ZStack {
            // Self label
            Text("Self")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.selfCircleCore)
                .position(x: selfPos.x, y: selfPos.y + circleSize / 2 + 15)
            
            // Other label
            Text("Other")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.otherCircleCore)
                .position(x: otherPos.x, y: otherPos.y + circleSize / 2 + 15)
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializePositions(geometry: GeometryProxy, setRect: CGRect) {
        // Use the set rectangle's vertical center for consistent positioning
        let centerY = setRect.midY
        
        // Self position
        if selfInSet {
            let targetX = otherInSet ? insideLeftX(geometry: geometry) : insideCenterX(geometry: geometry)
            selfPosition = CGPoint(x: targetX, y: centerY)
        } else {
            selfPosition = CGPoint(x: outsideLeftX(geometry: geometry), y: centerY)
        }
        
        // Other position
        if otherInSet {
            let targetX = selfInSet ? insideRightX(geometry: geometry) : insideCenterX(geometry: geometry)
            otherPosition = CGPoint(x: targetX, y: centerY)
        } else {
            otherPosition = CGPoint(x: outsideRightX(geometry: geometry), y: centerY)
        }
    }
    
    private func isCircleInSet(position: CGPoint, setRect: CGRect) -> Bool {
        // Check if circle center is inside the set rectangle
        return setRect.contains(position)
    }
    
    private func snapSelfPosition(setRect: CGRect, geometry: GeometryProxy) {
        let centerY = setRect.midY
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if selfInSet {
                // Inside: left side if other is also in, center if alone
                let targetX = otherInSet ? insideLeftX(geometry: geometry) : insideCenterX(geometry: geometry)
                selfPosition = CGPoint(x: targetX, y: centerY)
            } else {
                // Outside: always to the left
                selfPosition = CGPoint(x: outsideLeftX(geometry: geometry), y: centerY)
            }
        }
    }
    
    private func snapOtherPosition(setRect: CGRect, geometry: GeometryProxy) {
        let centerY = setRect.midY
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if otherInSet {
                // Inside: right side if self is also in, center if alone
                let targetX = selfInSet ? insideRightX(geometry: geometry) : insideCenterX(geometry: geometry)
                otherPosition = CGPoint(x: targetX, y: centerY)
            } else {
                // Outside: always to the right
                otherPosition = CGPoint(x: outsideRightX(geometry: geometry), y: centerY)
            }
        }
    }
}

// MARK: - Preview

#Preview("Set Membership Circles") {
    struct PreviewWrapper: View {
        @State private var selfInSet = true
        @State private var otherInSet = false
        
        var body: some View {
            VStack {
                SetMembershipCirclesView(
                    selfInSet: $selfInSet,
                    otherInSet: $otherInSet,
                    onDraggingChanged: { _ in }
                )
                .frame(height: 350)
                
                HStack {
                    Text("Self: \(selfInSet ? "In" : "Out")")
                        .foregroundStyle(ColorPalette.selfCircleCore)
                    Spacer()
                    Text("Other: \(otherInSet ? "In" : "Out")")
                        .foregroundStyle(ColorPalette.otherCircleCore)
                }
                .font(Typography.body)
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Both In Set") {
    struct PreviewWrapper: View {
        @State private var selfInSet = true
        @State private var otherInSet = true
        
        var body: some View {
            SetMembershipCirclesView(
                selfInSet: $selfInSet,
                otherInSet: $otherInSet,
                onDraggingChanged: { _ in }
            )
            .frame(height: 350)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Neither In Set") {
    struct PreviewWrapper: View {
        @State private var selfInSet = false
        @State private var otherInSet = false
        
        var body: some View {
            SetMembershipCirclesView(
                selfInSet: $selfInSet,
                otherInSet: $otherInSet,
                onDraggingChanged: { _ in }
            )
            .frame(height: 350)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
