//
//  AttributionPreview.swift
//  IoS Scale
//
//  Animated preview for Attribution modality - circles on a similarity axis.
//

import SwiftUI

/// Preview showing circles moving on a Similar ↔ Different axis
struct AttributionPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var similarityOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let axisWidth: CGFloat = 80
            
            ZStack {
                // Similarity axis
                HStack(spacing: 4) {
                    Text("≈")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.6))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: axisWidth, height: 3)
                    
                    Text("≠")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .position(x: centerX, y: centerY + 18)
                
                // Self circle - moves on axis
                Circle()
                    .fill(PreviewConstants.selfColor.gradient)
                    .frame(width: PreviewConstants.circleSize * 0.9, height: PreviewConstants.circleSize * 0.9)
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(x: centerX - 8 - similarityOffset, y: centerY - 5)
                
                // Other circle - moves opposite direction
                Circle()
                    .fill(PreviewConstants.otherColor.gradient)
                    .frame(width: PreviewConstants.circleSize * 0.9, height: PreviewConstants.circleSize * 0.9)
                    .shadow(color: PreviewConstants.otherColor.opacity(0.3), radius: 4)
                    .position(x: centerX + 8 + similarityOffset, y: centerY - 5)
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
            similarityOffset = 20
        }
    }
}

#Preview {
    AttributionPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
