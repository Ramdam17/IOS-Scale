//
//  ObservationPreview.swift
//  IoS Scale
//
//  Animated preview for Observation modality - eye transitioning to circle.
//

import SwiftUI

/// Preview showing transition between observer (eye) and participant (immersed)
struct ObservationPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var immersionLevel: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // The Self-Other pair (scales/blurs based on immersion)
                Group {
                    // Self circle
                    Circle()
                        .fill(PreviewConstants.selfColor.gradient)
                        .frame(width: PreviewConstants.circleSize * 0.8, height: PreviewConstants.circleSize * 0.8)
                        .position(x: centerX - 12, y: centerY + 8)
                    
                    // Other circle
                    Circle()
                        .fill(PreviewConstants.otherColor.gradient)
                        .frame(width: PreviewConstants.circleSize * 0.8, height: PreviewConstants.circleSize * 0.8)
                        .position(x: centerX + 12, y: centerY + 8)
                }
                .scaleEffect(0.6 + immersionLevel * 0.4)
                .blur(radius: (1 - immersionLevel) * 2)
                .opacity(0.5 + immersionLevel * 0.5)
                
                // Eye icon (observer viewpoint) - fades out when immersed
                Image(systemName: "eye")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .position(x: centerX, y: centerY - 18)
                    .opacity(1 - immersionLevel)
                    .scaleEffect(1 - immersionLevel * 0.3)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                immersionLevel = 0.5
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
            immersionLevel = 1.0
        }
    }
}

#Preview {
    ObservationPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
