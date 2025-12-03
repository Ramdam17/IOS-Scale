//
//  SetMembershipPreview.swift
//  IoS Scale
//
//  Animated preview for Set Membership modality - circles moving in/out of a rectangle.
//

import SwiftUI

/// Preview showing circles moving in and out of a "set" rectangle
struct SetMembershipPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var selfInSet: Bool = true
    @State private var otherInSet: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let setWidth: CGFloat = 70
            let setHeight: CGFloat = 40
            
            ZStack {
                // The "set" rectangle
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 2)
                    .frame(width: setWidth, height: setHeight)
                    .position(x: centerX, y: centerY)
                
                // Self circle
                Circle()
                    .fill(PreviewConstants.selfColor.gradient)
                    .frame(width: PreviewConstants.circleSize * 0.9, height: PreviewConstants.circleSize * 0.9)
                    .shadow(color: PreviewConstants.selfColor.opacity(0.3), radius: 4)
                    .position(
                        x: selfInSet ? centerX - 12 : centerX - 55,
                        y: centerY
                    )
                
                // Other circle
                Circle()
                    .fill(PreviewConstants.otherColor.gradient)
                    .frame(width: PreviewConstants.circleSize * 0.9, height: PreviewConstants.circleSize * 0.9)
                    .shadow(color: PreviewConstants.otherColor.opacity(0.3), radius: 4)
                    .position(
                        x: otherInSet ? centerX + 12 : centerX + 55,
                        y: centerY
                    )
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Staggered animation - circles take turns moving in/out
        Timer.scheduledTimer(withTimeInterval: PreviewConstants.cycleDuration / 2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                selfInSet.toggle()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + PreviewConstants.cycleDuration / 4) {
            Timer.scheduledTimer(withTimeInterval: PreviewConstants.cycleDuration / 2, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    otherInSet.toggle()
                }
            }
        }
    }
}

#Preview {
    SetMembershipPreview()
        .frame(height: PreviewConstants.previewHeight)
        .padding()
        .background(Color.gray.opacity(0.1))
}
