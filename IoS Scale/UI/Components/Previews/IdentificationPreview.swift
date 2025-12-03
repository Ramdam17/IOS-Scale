//
//  IdentificationPreview.swift
//  IoS Scale
//
//  Animated preview for Identification modality - Other flows into Self.
//

import SwiftUI

/// Preview showing Other circle flowing into Self (Self absorbs Other)
struct IdentificationPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var identificationAmount: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            // Other moves toward Self as identification increases
            let otherX = centerX + 25 - (identificationAmount * 20)
            let selfX = centerX - 25
            
            ZStack {
                // Arrow indicating direction (Other → Self)
                Image(systemName: "arrow.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .position(x: centerX, y: centerY - 20)
                
                // Self circle (left) - takes on Other's color
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                PreviewConstants.selfColor,
                                PreviewConstants.selfColor.opacity(Double(1 - identificationAmount * 0.5)),
                                PreviewConstants.otherColor.opacity(Double(identificationAmount * 0.5))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(x: selfX, y: centerY)
                
                // Other circle (right) - becomes transparent
                Circle()
                    .fill(PreviewConstants.otherColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .opacity(Double(1 - identificationAmount * 0.6))
                    .shadow(color: PreviewConstants.otherColor.opacity(0.3), radius: 4)
                    .position(x: otherX, y: centerY)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                identificationAmount = 0.3
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
            identificationAmount = 0.8
        }
    }
}

#Preview {
    IdentificationPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
