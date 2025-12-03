//
//  AdvancedIOSPreview.swift
//  IoS Scale
//
//  Animated preview for Advanced IOS modality - circles moving + size pulsing.
//

import SwiftUI

/// Preview showing two circles moving closer/apart with subtle size pulsing
struct AdvancedIOSPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var offset: CGFloat = 0
    @State private var selfScale: CGFloat = 1.0
    @State private var otherScale: CGFloat = 1.0
    
    private let maxOffset: CGFloat = 12
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Self circle (left) - pulses larger
                Circle()
                    .fill(PreviewConstants.selfColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .scaleEffect(selfScale)
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(x: centerX - 20 - offset, y: centerY)
                
                // Other circle (right) - pulses smaller
                Circle()
                    .fill(PreviewConstants.otherColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .scaleEffect(otherScale)
                    .shadow(color: PreviewConstants.otherColor.opacity(0.3), radius: 4)
                    .position(x: centerX + 20 + offset, y: centerY)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Movement animation
        withAnimation(
            .easeInOut(duration: PreviewConstants.cycleDuration / 2)
            .repeatForever(autoreverses: true)
        ) {
            offset = maxOffset
        }
        
        // Self scale animation (slightly out of phase)
        withAnimation(
            .easeInOut(duration: PreviewConstants.cycleDuration / 2 * 0.8)
            .repeatForever(autoreverses: true)
        ) {
            selfScale = 1.2
        }
        
        // Other scale animation (opposite phase)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(
                .easeInOut(duration: PreviewConstants.cycleDuration / 2 * 0.8)
                .repeatForever(autoreverses: true)
            ) {
                otherScale = 0.85
            }
        }
    }
}

#Preview {
    AdvancedIOSPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
