//
//  ModalityPreviewView.swift
//  IoS Scale
//
//  Animated preview component for modality cards.
//

import SwiftUI

/// Factory view that returns the appropriate animated preview for each modality
struct ModalityPreviewView: View {
    let modality: ModalityType
    
    /// Whether animations should be reduced (accessibility)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Group {
            switch modality {
            case .basicIOS:
                BasicIOSPreview()
            case .advancedIOS:
                AdvancedIOSPreview()
            case .overlap:
                OverlapPreview()
            case .setMembership:
                SetMembershipPreview()
            case .proximity:
                ProximityPreview()
            case .identification:
                IdentificationPreview()
            case .projection:
                ProjectionPreview()
            case .attribution:
                AttributionPreview()
            case .observation:
                ObservationPreview()
            }
        }
    }
}

// MARK: - Preview Constants

enum PreviewConstants {
    /// Size of preview circles
    static let circleSize: CGFloat = 24
    
    /// Animation duration for one cycle
    static let cycleDuration: Double = 3.0
    
    /// Preview container height
    static let previewHeight: CGFloat = 60
    
    /// Self circle color
    static let selfColor = ColorPalette.selfCircleCore
    
    /// Other circle color
    static let otherColor = ColorPalette.otherCircleCore
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ForEach(ModalityType.allCases, id: \.self) { modality in
            VStack(spacing: 4) {
                ModalityPreviewView(modality: modality)
                    .frame(height: PreviewConstants.previewHeight)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(modality.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
}
