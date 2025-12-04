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
        HStack(spacing: Spacing.md) {
            // Index badge
            Text("\(index)")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(ColorPalette.selfCircleCore.gradient)
                .clipShape(Circle())
            
            // Value bar
            valueBar
            
            // Time
            Text(formattedTime)
                .font(Typography.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - Value Bar
    
    private var valueBar: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(String(format: "%.0f%%", measurement.primaryValue * 100))
                    .font(Typography.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Secondary values if present
                if let secondaryValues = measurement.secondaryValues {
                    secondaryValuesView(secondaryValues)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [ColorPalette.selfCircleCore, ColorPalette.otherCircleCore],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * measurement.primaryValue, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    // MARK: - Secondary Values
    
    @ViewBuilder
    private func secondaryValuesView(_ values: [String: Double]) -> some View {
        HStack(spacing: Spacing.sm) {
            if let selfScale = values[Measurement.SecondaryKey.selfScale.rawValue] {
                Label(String(format: "S:%.1f", selfScale), systemImage: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if let otherScale = values[Measurement.SecondaryKey.otherScale.rawValue] {
                Label(String(format: "O:%.1f", otherScale), systemImage: "person")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
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
