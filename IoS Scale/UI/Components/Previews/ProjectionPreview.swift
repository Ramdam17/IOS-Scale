//
//  ProjectionPreview.swift
//  IoS Scale
//
//  Animated preview for Projection modality - Self flows into Other.
//

import SwiftUI

/// Preview showing Self circle flowing into Other (Self projects onto Other)
struct ProjectionPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var projectionAmount: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            // Self moves toward Other as projection increases
            let selfX = centerX - 25 + (projectionAmount * 20)
            let otherX = centerX + 25
            
            ZStack {
                // Arrow indicating direction (Self → Other)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .position(x: centerX, y: centerY - 20)
                
                // Other circle (right) - takes on Self's color
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                PreviewConstants.selfColor.opacity(Double(projectionAmount * 0.5)),
                                PreviewConstants.otherColor.opacity(Double(1 - projectionAmount * 0.5)),
                                PreviewConstants.otherColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .shadow(color: PreviewConstants.otherColor.opacity(0.3), radius: 4)
                    .position(x: otherX, y: centerY)
                
                // Self circle (left) - becomes transparent
                Circle()
                    .fill(PreviewConstants.selfColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .opacity(Double(1 - projectionAmount * 0.6))
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(x: selfX, y: centerY)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                projectionAmount = 0.3
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
            projectionAmount = 0.8
        }
    }
}

#Preview {
    ProjectionPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
