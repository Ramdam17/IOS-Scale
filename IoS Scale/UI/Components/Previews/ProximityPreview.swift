//
//  ProximityPreview.swift
//  IoS Scale
//
//  Animated preview for Proximity modality - circles with animated connecting line.
//

import SwiftUI

/// Preview showing two circles with a connecting line that varies in thickness
struct ProximityPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var distance: CGFloat = 40
    
    private let minDistance: CGFloat = 25
    private let maxDistance: CGFloat = 55
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let halfDistance = distance / 2
            
            // Calculate line thickness based on proximity
            let proximity = 1 - (distance - minDistance) / (maxDistance - minDistance)
            let lineWidth = 1 + proximity * 3
            
            ZStack {
                // Connecting line
                Path { path in
                    path.move(to: CGPoint(x: centerX - halfDistance + PreviewConstants.circleSize / 2, y: centerY))
                    path.addLine(to: CGPoint(x: centerX + halfDistance - PreviewConstants.circleSize / 2, y: centerY))
                }
                .stroke(
                    LinearGradient(
                        colors: [PreviewConstants.selfColor, PreviewConstants.otherColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .opacity(0.6)
                
                // Self circle (left)
                Circle()
                    .fill(PreviewConstants.selfColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(x: centerX - halfDistance, y: centerY)
                
                // Other circle (right)
                Circle()
                    .fill(PreviewConstants.otherColor.gradient)
                    .frame(width: PreviewConstants.circleSize, height: PreviewConstants.circleSize)
                    .shadow(color: PreviewConstants.otherColor.opacity(0.3), radius: 4)
                    .position(x: centerX + halfDistance, y: centerY)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                distance = (minDistance + maxDistance) / 2
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
            distance = minDistance
        }
    }
}

#Preview {
    ProximityPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
