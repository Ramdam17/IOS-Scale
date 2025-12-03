//
//  BasicIOSPreview.swift
//  IoS Scale
//
//  Animated preview for Basic IOS modality - two circles moving closer/apart.
//

import SwiftUI

/// Preview showing two circles gently moving closer and apart in a loop
struct BasicIOSPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var offset: CGFloat = 0
    
    private let maxOffset: CGFloat = 15
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Self circle (left)
                Circle()
                    .fill(PreviewConstants.selfColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(x: centerX - 20 - offset, y: centerY)
                
                // Other circle (right)
                Circle()
                    .fill(PreviewConstants.otherColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
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
        withAnimation(
            .easeInOut(duration: PreviewConstants.cycleDuration / 2)
            .repeatForever(autoreverses: true)
        ) {
            offset = maxOffset
        }
    }
}

#Preview {
    BasicIOSPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
