//
//  MeasurementVisualizationView.swift
//  IoS Scale
//
//  Modality-specific visualization for measurement history.
//  Each modality gets its own visual representation.
//

import SwiftUI

/// Factory view that returns the appropriate visualization for each modality
struct MeasurementVisualizationView: View {
    let measurement: MeasurementModel
    let modality: ModalityType
    
    /// Size of the visualization
    var size: CGFloat = 60
    
    var body: some View {
        Group {
            switch modality {
            case .basicIOS:
                BasicIOSVisualization(primaryValue: measurement.primaryValue, size: size)
            case .advancedIOS:
                AdvancedIOSVisualization(measurement: measurement, size: size)
            case .overlap:
                OverlapVisualization(primaryValue: measurement.primaryValue, size: size)
            case .setMembership:
                SetMembershipVisualization(measurement: measurement, size: size)
            case .proximity:
                ProximityVisualization(primaryValue: measurement.primaryValue, size: size)
            case .identification:
                IdentificationVisualization(primaryValue: measurement.primaryValue, size: size)
            case .projection:
                ProjectionVisualization(primaryValue: measurement.primaryValue, size: size)
            case .attribution:
                AttributionVisualization(primaryValue: measurement.primaryValue, size: size)
            case .observation:
                ObservationVisualization(primaryValue: measurement.primaryValue, size: size)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Basic IOS Visualization

/// Two overlapping circles showing the IOS scale position
struct BasicIOSVisualization: View {
    let primaryValue: Double
    let size: CGFloat
    
    private var circleSize: CGFloat { size * 0.45 }
    private var separation: CGFloat {
        // Map 0-1 to full separation to overlap
        let maxSeparation = size * 0.5
        return maxSeparation * (1 - primaryValue)
    }
    
    var body: some View {
        ZStack {
            // Self circle (left)
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: -separation / 2)
            
            // Other circle (right)
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: separation / 2)
        }
    }
}

// MARK: - Advanced IOS Visualization

/// Two circles with variable sizes showing overlap and scale
struct AdvancedIOSVisualization: View {
    let measurement: MeasurementModel
    let size: CGFloat
    
    private var selfScale: Double {
        measurement.secondaryValues?["selfScale"] ?? measurement.secondaryValues?["self_scale"] ?? 1.0
    }
    
    private var otherScale: Double {
        measurement.secondaryValues?["otherScale"] ?? measurement.secondaryValues?["other_scale"] ?? 1.0
    }
    
    private var baseCircleSize: CGFloat { size * 0.35 }
    private var separation: CGFloat {
        let maxSeparation = size * 0.4
        return maxSeparation * (1 - measurement.primaryValue)
    }
    
    var body: some View {
        ZStack {
            // Self circle with scale
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: baseCircleSize * selfScale, height: baseCircleSize * selfScale)
                .offset(x: -separation / 2)
            
            // Other circle with scale
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: baseCircleSize * otherScale, height: baseCircleSize * otherScale)
                .offset(x: separation / 2)
        }
    }
}

// MARK: - Overlap Visualization

/// Venn diagram showing intersection zone
struct OverlapVisualization: View {
    let primaryValue: Double
    let size: CGFloat
    
    private var circleSize: CGFloat { size * 0.5 }
    private var overlapAmount: CGFloat {
        CGFloat(primaryValue) * circleSize * 0.7
    }
    
    var body: some View {
        ZStack {
            // Self circle
            Circle()
                .fill(ColorPalette.selfCircleCore.opacity(0.6))
                .frame(width: circleSize, height: circleSize)
                .offset(x: -circleSize / 4 + overlapAmount / 2)
            
            // Other circle
            Circle()
                .fill(ColorPalette.otherCircleCore.opacity(0.6))
                .frame(width: circleSize, height: circleSize)
                .offset(x: circleSize / 4 - overlapAmount / 2)
            
            // Intersection highlight
            if primaryValue > 0.1 {
                Ellipse()
                    .fill(Color(hex: "FFD700").opacity(0.7))
                    .frame(width: overlapAmount * 0.6, height: circleSize * 0.6)
            }
        }
    }
}

// MARK: - Set Membership Visualization

/// Rectangle with circles inside/outside showing membership state
struct SetMembershipVisualization: View {
    let measurement: MeasurementModel
    let size: CGFloat
    
    private var selfInSet: Bool {
        if let value = measurement.secondaryValues?["selfInSet"] {
            return value > 0.5
        }
        // Fallback: interpret primaryValue
        return measurement.primaryValue >= 0.5
    }
    
    private var otherInSet: Bool {
        if let value = measurement.secondaryValues?["otherInSet"] {
            return value > 0.5
        }
        // Fallback: both in if 1.0, neither if 0.0
        return measurement.primaryValue >= 1.0
    }
    
    private var rectWidth: CGFloat { size * 0.6 }
    private var rectHeight: CGFloat { size * 0.5 }
    private var circleSize: CGFloat { size * 0.25 }
    
    var body: some View {
        ZStack {
            // The set rectangle
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 2)
                .frame(width: rectWidth, height: rectHeight)
            
            // Self circle
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: selfInSet ? -rectWidth / 6 : -size * 0.35, y: 0)
            
            // Other circle
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: otherInSet ? rectWidth / 6 : size * 0.35, y: 0)
        }
    }
    
    private var borderColor: Color {
        if selfInSet && otherInSet {
            return Color(hex: "FFD700")
        } else if !selfInSet && !otherInSet {
            return Color.gray.opacity(0.5)
        } else {
            return Color.purple.opacity(0.7)
        }
    }
}

// MARK: - Proximity Visualization

/// Two circles with a connecting line showing distance
struct ProximityVisualization: View {
    let primaryValue: Double
    let size: CGFloat
    
    private var circleSize: CGFloat { size * 0.3 }
    private var distance: CGFloat {
        let minDistance = circleSize
        let maxDistance = size * 0.8
        return maxDistance - (maxDistance - minDistance) * CGFloat(primaryValue)
    }
    
    var body: some View {
        ZStack {
            // Connecting line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [ColorPalette.selfCircleCore, ColorPalette.otherCircleCore],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: distance - circleSize, height: 2 + CGFloat(primaryValue) * 2)
            
            // Self circle
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: -distance / 2 + circleSize / 2)
            
            // Other circle
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: distance / 2 - circleSize / 2)
        }
    }
}

// MARK: - Identification Visualization

/// Arrow from Other to Self showing absorption
struct IdentificationVisualization: View {
    let primaryValue: Double
    let size: CGFloat
    
    private var circleSize: CGFloat { size * 0.35 }
    
    var body: some View {
        ZStack {
            // Arrow from Other to Self
            Image(systemName: "arrow.left")
                .font(.system(size: size * 0.2))
                .foregroundStyle(Color.gray.opacity(0.5 + primaryValue * 0.5))
            
            // Self circle (receives)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            ColorPalette.selfCircleCore,
                            ColorPalette.selfCircleCore.opacity(1 - primaryValue * 0.5),
                            ColorPalette.otherCircleCore.opacity(primaryValue * 0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: circleSize, height: circleSize)
                .offset(x: -size * 0.25)
            
            // Other circle (gives) - fades
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .opacity(1 - primaryValue * 0.6)
                .offset(x: size * 0.25)
        }
    }
}

// MARK: - Projection Visualization

/// Arrow from Self to Other showing projection
struct ProjectionVisualization: View {
    let primaryValue: Double
    let size: CGFloat
    
    private var circleSize: CGFloat { size * 0.35 }
    
    var body: some View {
        ZStack {
            // Arrow from Self to Other
            Image(systemName: "arrow.right")
                .font(.system(size: size * 0.2))
                .foregroundStyle(Color.gray.opacity(0.5 + primaryValue * 0.5))
            
            // Self circle (gives) - fades
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .opacity(1 - primaryValue * 0.6)
                .offset(x: -size * 0.25)
            
            // Other circle (receives)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            ColorPalette.selfCircleCore.opacity(primaryValue * 0.5),
                            ColorPalette.otherCircleCore.opacity(1 - primaryValue * 0.5),
                            ColorPalette.otherCircleCore
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: circleSize, height: circleSize)
                .offset(x: size * 0.25)
        }
    }
}

// MARK: - Attribution Visualization

/// Circles on a similarity axis
struct AttributionVisualization: View {
    let primaryValue: Double
    let size: CGFloat
    
    private var circleSize: CGFloat { size * 0.25 }
    private var axisWidth: CGFloat { size * 0.8 }
    
    // When similar (1.0), circles are close together
    // When different (0.0), circles are far apart
    private var separation: CGFloat {
        axisWidth * (1 - primaryValue)
    }
    
    var body: some View {
        ZStack {
            // Axis line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: axisWidth, height: 2)
            
            // Self circle
            Circle()
                .fill(ColorPalette.selfCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: -separation / 2)
            
            // Other circle
            Circle()
                .fill(ColorPalette.otherCircleGradient)
                .frame(width: circleSize, height: circleSize)
                .offset(x: separation / 2)
        }
    }
}

// MARK: - Observation Visualization

/// Eye icon transitioning to circle based on immersion
struct ObservationVisualization: View {
    let primaryValue: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Eye (observer) - visible when low immersion
            Image(systemName: "eye")
                .font(.system(size: size * 0.4))
                .foregroundStyle(Color.gray)
                .opacity(1 - primaryValue)
            
            // Circles (participant) - visible when high immersion
            HStack(spacing: size * 0.05) {
                Circle()
                    .fill(ColorPalette.selfCircleGradient)
                    .frame(width: size * 0.3, height: size * 0.3)
                
                Circle()
                    .fill(ColorPalette.otherCircleGradient)
                    .frame(width: size * 0.3, height: size * 0.3)
            }
            .opacity(primaryValue)
            .scaleEffect(0.8 + primaryValue * 0.2)
        }
    }
}

// MARK: - Previews

#Preview("All Visualizations") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(ModalityType.allCases) { modality in
                HStack {
                    Text(modality.displayName)
                        .font(.caption)
                        .frame(width: 100, alignment: .leading)
                    
                    // Low value
                    MeasurementVisualizationView(
                        measurement: MeasurementModel(
                            primaryValue: 0.2,
                            secondaryValues: ["selfInSet": 1.0, "otherInSet": 0.0, "selfScale": 0.8, "otherScale": 1.2]
                        ),
                        modality: modality
                    )
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Mid value
                    MeasurementVisualizationView(
                        measurement: MeasurementModel(
                            primaryValue: 0.5,
                            secondaryValues: ["selfInSet": 1.0, "otherInSet": 0.0, "selfScale": 1.0, "otherScale": 1.0]
                        ),
                        modality: modality
                    )
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // High value
                    MeasurementVisualizationView(
                        measurement: MeasurementModel(
                            primaryValue: 1.0,
                            secondaryValues: ["selfInSet": 1.0, "otherInSet": 1.0, "selfScale": 1.5, "otherScale": 0.7]
                        ),
                        modality: modality
                    )
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
    }
}

#Preview("Set Membership States") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            VStack {
                SetMembershipVisualization(
                    measurement: MeasurementModel(primaryValue: 1.0, secondaryValues: ["selfInSet": 1.0, "otherInSet": 1.0]),
                    size: 80
                )
                Text("Both In")
                    .font(.caption)
            }
            
            VStack {
                SetMembershipVisualization(
                    measurement: MeasurementModel(primaryValue: 0.5, secondaryValues: ["selfInSet": 1.0, "otherInSet": 0.0]),
                    size: 80
                )
                Text("Self Only")
                    .font(.caption)
            }
        }
        
        HStack(spacing: 20) {
            VStack {
                SetMembershipVisualization(
                    measurement: MeasurementModel(primaryValue: 0.5, secondaryValues: ["selfInSet": 0.0, "otherInSet": 1.0]),
                    size: 80
                )
                Text("Other Only")
                    .font(.caption)
            }
            
            VStack {
                SetMembershipVisualization(
                    measurement: MeasurementModel(primaryValue: 0.0, secondaryValues: ["selfInSet": 0.0, "otherInSet": 0.0]),
                    size: 80
                )
                Text("Neither")
                    .font(.caption)
            }
        }
    }
    .padding()
}
