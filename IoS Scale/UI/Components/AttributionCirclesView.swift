//
//  AttributionCirclesView.swift
//  IoS Scale
//
//  Interactive circles component for Attribution modality.
//  Circles move on a similarity axis: converge when similar, diverge when different.
//  Measures perceived similarity between Self and Other.
//

import SwiftUI

/// View displaying attribution/similarity interaction on a horizontal axis
struct AttributionCirclesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Similarity value: 0 = very different (far apart), 1 = very similar (close/overlapping)
    @Binding var similarityValue: Double
    
    /// Callback when dragging starts or ends
    var onDraggingChanged: ((Bool) -> Void)?
    
    // State
    @State private var isDragging = false
    @State private var hasInitialized = false
    @State private var lastHapticValue: Double = 0
    @State private var initialSimilarityValue: Double = 0
    
    // Layout constants
    private var circleSize: CGFloat {
        horizontalSizeClass == .regular ? 90 : 70
    }
    
    private let hapticThreshold: Double = 0.1
    
    var body: some View {
        GeometryReader { geometry in
            let centerY = geometry.size.height * 0.45
            let selfCenter = selfPosition(geometry: geometry)
            let otherCenter = otherPosition(geometry: geometry)
            
            ZStack {
                // Connection line between circles
                connectionLine(from: selfCenter, to: otherCenter)
                
                // Self circle (left side)
                selfCircleView(position: selfCenter, geometry: geometry)
                
                // Other circle (right side)
                otherCircleView(position: otherCenter, geometry: geometry)
                
                // Similarity indicator at center
                similarityIndicator(geometry: geometry, centerY: centerY)
                
                // Labels
                circleLabels(selfCenter: selfCenter, otherCenter: otherCenter)
            }
            .onChange(of: geometry.size) { _, _ in
                hasInitialized = true
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Attribution measurement")
        .accessibilityValue("Similarity: \(Int(similarityValue * 100)) percent")
        .accessibilityHint("Drag to adjust perceived similarity between Self and Other")
    }
    
    // MARK: - Positions
    
    private func selfPosition(geometry: GeometryProxy) -> CGPoint {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.45
        let maxSeparation = geometry.size.width * 0.35
        
        // At value=0 (different), circles are far apart
        // At value=1 (similar), circles are close/overlapping
        let separation = maxSeparation * (1 - similarityValue)
        
        return CGPoint(x: centerX - separation, y: centerY)
    }
    
    private func otherPosition(geometry: GeometryProxy) -> CGPoint {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.45
        let maxSeparation = geometry.size.width * 0.35
        
        let separation = maxSeparation * (1 - similarityValue)
        
        return CGPoint(x: centerX + separation, y: centerY)
    }
    
    // MARK: - Connection Line
    
    private func connectionLine(from: CGPoint, to: CGPoint) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            LinearGradient(
                colors: [
                    ColorPalette.selfCircleCore.opacity(0.4),
                    ColorPalette.otherCircleCore.opacity(0.4)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4])
        )
        .animation(.spring(response: 0.3), value: similarityValue)
    }
    
    // MARK: - Self Circle
    
    private func selfCircleView(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Self circle grows slightly when similar
        let scaleBonus = similarityValue * 0.15
        
        return ZStack {
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
            
            // Blend effect when very similar
            if similarityValue > 0.7 {
                Circle()
                    .fill(ColorPalette.otherCircleGradient)
                    .frame(width: circleSize, height: circleSize)
                    .opacity((similarityValue - 0.7) * 1.5)
            }
        }
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
        .shadow(color: ColorPalette.selfCircleCore.opacity(0.3), radius: 8)
        .scaleEffect(1 + scaleBonus)
        .position(position)
        .animation(.spring(response: 0.3), value: similarityValue)
    }
    
    // MARK: - Other Circle
    
    private func otherCircleView(position: CGPoint, geometry: GeometryProxy) -> some View {
        // Other circle grows slightly when similar
        let scaleBonus = similarityValue * 0.15
        
        return ZStack {
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
            
            // Blend effect when very similar
            if similarityValue > 0.7 {
                Circle()
                    .fill(ColorPalette.selfCircleGradient)
                    .frame(width: circleSize, height: circleSize)
                    .opacity((similarityValue - 0.7) * 1.5)
            }
        }
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
        .shadow(color: ColorPalette.otherCircleCore.opacity(0.3), radius: 8)
        .scaleEffect(1 + scaleBonus)
        .position(position)
        .animation(.spring(response: 0.3), value: similarityValue)
    }
    
    // MARK: - Similarity Indicator
    
    private func similarityIndicator(geometry: GeometryProxy, centerY: CGFloat) -> some View {
        let showIndicator = similarityValue > 0.8
        
        return ZStack {
            // Heart or unity symbol when very similar
            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink, Color.red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(showIndicator ? 1.0 : 0.5)
                .opacity(showIndicator ? 1.0 : 0.0)
                .position(x: geometry.size.width / 2, y: centerY - circleSize / 2 - 25)
        }
        .animation(
            showIndicator
                ? .spring(response: 0.4, dampingFraction: 0.6)
                : .easeOut(duration: 0.2),
            value: showIndicator
        )
    }
    
    // MARK: - Labels
    
    private func circleLabels(selfCenter: CGPoint, otherCenter: CGPoint) -> some View {
        ZStack {
            // Self label
            Text("Self")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.selfCircleCore)
                .position(x: selfCenter.x, y: selfCenter.y + circleSize / 2 + 16)
            
            // Other label
            Text("Other")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorPalette.otherCircleCore)
                .position(x: otherCenter.x, y: otherCenter.y + circleSize / 2 + 16)
        }
        .animation(.spring(response: 0.3), value: similarityValue)
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    initialSimilarityValue = similarityValue
                    onDraggingChanged?(true)
                    HapticManager.shared.lightImpact()
                }
                
                // Horizontal drag: right = more similar (circles converge), left = more different
                let dragRange: CGFloat = 300
                let normalizedDelta = value.translation.width / dragRange
                let adjustedValue = initialSimilarityValue + normalizedDelta
                
                // Haptic feedback at thresholds
                if abs(adjustedValue - lastHapticValue) >= hapticThreshold {
                    HapticManager.shared.lightImpact()
                    lastHapticValue = adjustedValue
                }
                
                // Special haptic when very similar
                if adjustedValue >= 0.98 && similarityValue < 0.98 {
                    HapticManager.shared.success()
                }
                
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
                    similarityValue = min(max(0, adjustedValue), 1)
                }
            }
            .onEnded { _ in
                isDragging = false
                onDraggingChanged?(false)
            }
    }
}

// MARK: - Preview

#Preview("Attribution Circles") {
    struct PreviewWrapper: View {
        @State private var similarity: Double = 0.5
        
        var body: some View {
            VStack {
                AttributionCirclesView(
                    similarityValue: $similarity,
                    onDraggingChanged: { _ in }
                )
                .frame(height: 300)
                
                Text("Similarity: \(Int(similarity * 100))%")
                    .font(Typography.headline)
                
                Slider(value: $similarity, in: 0...1)
                    .padding(.horizontal)
            }
            .padding()
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Very Similar") {
    struct PreviewWrapper: View {
        @State private var similarity: Double = 0.95
        
        var body: some View {
            AttributionCirclesView(
                similarityValue: $similarity,
                onDraggingChanged: { _ in }
            )
            .frame(height: 300)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Very Different") {
    struct PreviewWrapper: View {
        @State private var similarity: Double = 0.1
        
        var body: some View {
            AttributionCirclesView(
                similarityValue: $similarity,
                onDraggingChanged: { _ in }
            )
            .frame(height: 300)
            .gradientBackground()
        }
    }
    
    return PreviewWrapper()
}
