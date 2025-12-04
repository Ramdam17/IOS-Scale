//
//  MeasurementRowView.swift
//  IoS Scale
//
//  Row component for displaying individual measurement in session detail.
//

import SwiftUI
import SwiftData

/// Displays a single measurement with its details
struct MeasurementRowView: View {
    let measurement: MeasurementModel
    let index: Int
    let modality: ModalityType
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: measurement.timestamp)
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Index badge
            Text("\(index)")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(ColorPalette.selfCircleCore.gradient)
                .clipShape(Circle())
            
            // Mini visualization
            MeasurementVisualizationView(
                measurement: measurement,
                modality: modality,
                size: 44
            )
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Value info
            valueInfo
            
            Spacer()
            
            // Time
            Text(formattedTime)
                .font(Typography.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - Value Info
    
    @ViewBuilder
    private var valueInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Primary label based on modality
            primaryValueLabel
            
            // Secondary values if present
            if let secondaryValues = measurement.secondaryValues {
                secondaryValuesView(secondaryValues)
            }
        }
    }
    
    /// Primary value label adapted to modality
    @ViewBuilder
    private var primaryValueLabel: some View {
        switch modality {
        case .setMembership:
            setMembershipLabel
        default:
            Text(String(format: "%.0f%%", measurement.primaryValue * 100))
                .font(Typography.body)
                .fontWeight(.medium)
        }
    }
    
    /// Label for Set Membership showing readable state
    private var setMembershipLabel: some View {
        let selfIn = (measurement.secondaryValues?["selfInSet"] ?? 0) > 0.5
        let otherIn = (measurement.secondaryValues?["otherInSet"] ?? 0) > 0.5
        
        let text: String
        let color: Color
        
        switch (selfIn, otherIn) {
        case (true, true):
            text = "Same Set"
            color = Color(hex: "FFD700")
        case (true, false):
            text = "Self only"
            color = ColorPalette.selfCircleCore
        case (false, true):
            text = "Other only"
            color = ColorPalette.otherCircleCore
        case (false, false):
            text = "Neither"
            color = Color.gray
        }
        
        return Text(text)
            .font(Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(color)
    }
    
    // MARK: - Secondary Values
    
    @ViewBuilder
    private func secondaryValuesView(_ values: [String: Double]) -> some View {
        switch modality {
        case .advancedIOS:
            // Show scale values for Advanced IOS
            HStack(spacing: Spacing.xs) {
                if let selfScale = values[Measurement.SecondaryKey.selfScale.rawValue] {
                    Label(String(format: "%.1f×", selfScale), systemImage: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if let otherScale = values[Measurement.SecondaryKey.otherScale.rawValue] {
                    Label(String(format: "%.1f×", otherScale), systemImage: "person")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        case .setMembership:
            // Set Membership shows checkmarks for who's in
            HStack(spacing: 2) {
                let selfIn = (values["selfInSet"] ?? 0) > 0.5
                let otherIn = (values["otherInSet"] ?? 0) > 0.5
                
                Image(systemName: selfIn ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                    .foregroundStyle(selfIn ? ColorPalette.selfCircleCore : Color.gray.opacity(0.4))
                
                Image(systemName: otherIn ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                    .foregroundStyle(otherIn ? ColorPalette.otherCircleCore : Color.gray.opacity(0.4))
            }
        default:
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        MeasurementRowView(
            measurement: MeasurementModel(primaryValue: 0.75),
            index: 1,
            modality: .basicIOS
        )
        
        MeasurementRowView(
            measurement: MeasurementModel(
                primaryValue: 0.5,
                secondaryValues: ["self_scale": 1.2, "other_scale": 0.8]
            ),
            index: 2,
            modality: .advancedIOS
        )
        
        MeasurementRowView(
            measurement: MeasurementModel(primaryValue: 0.25),
            index: 3,
            modality: .basicIOS
        )
    }
    .padding()
    .gradientBackground()
}
