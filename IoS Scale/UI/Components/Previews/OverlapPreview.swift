//
//  OverlapPreview.swift
//  IoS Scale
//
//  Animated preview for Overlap modality - circles with animated intersection zone.
//

import SwiftUI

/// Preview showing two overlapping circles with highlighted intersection
struct OverlapPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var overlapAmount: CGFloat = 0.2
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let separation = 30 - (overlapAmount * 20)
            
            ZStack {
                // Overlap zone (rendered first, behind circles)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                PreviewConstants.selfColor.opacity(0.5),
                                PreviewConstants.otherColor.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: PreviewConstants.circleSize * overlapAmount * 0.8, height: PreviewConstants.circleSize * 0.7)
                    .blur(radius: 2)
                    .position(x: centerX, y: centerY)
                
                // Self circle (left)
                Circle()
                    .fill(PreviewConstants.selfColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(x: centerX - separation, y: centerY)
                
                // Other circle (right)
                Circle()
                    .fill(PreviewConstants.otherColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .shadow(color: PreviewConstants.otherColor.opacity(0.3), radius: 4)
                    .position(x: centerX + separation, y: centerY)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                overlapAmount = 0.5
                return
            }
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: PreviewConstants.cycleDuration / 2)
            .repeatForever(autoreverses: true)
        ) {
            overlapAmount = 1.0
        }
    }
}

#Preview {
    OverlapPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
