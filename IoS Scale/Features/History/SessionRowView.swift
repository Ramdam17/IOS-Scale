//
//  SessionRowView.swift
//  IoS Scale
//
//  Row component for displaying session summary in the history list.
//

import SwiftUI
import SwiftData

/// Displays a session summary as a card in the history list
struct SessionRowView: View {
    let session: SessionModel
    
    private var averageValue: Double? {
        let measurements = session.measurements ?? []
        guard !measurements.isEmpty else { return nil }
        let sum = measurements.reduce(0.0) { $0 + $1.primaryValue }
        return sum / Double(measurements.count)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.createdAt)
    }
    
    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Modality icon
            modalityIcon
            
            // Session info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(session.modality.displayName)
                        .font(Typography.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                HStack {
                    // Measurement count
                    Label("\((session.measurements ?? []).count)", systemImage: "number")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.quaternary)
                    
                    // Average value
                    if let avg = averageValue {
                        Text("Avg: \(String(format: "%.0f%%", avg * 100))")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Relative date
                    Text(relativeDate)
                        .font(Typography.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Notes preview if available
                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            // Mini bar chart preview
            miniChart
        }
        .padding(Spacing.md)
        .glassBackground()
    }
    
    // MARK: - Modality Icon
    
    private var modalityIcon: some View {
        ZStack {
            Circle()
                .fill(session.modality.tintColor.opacity(0.2))
                .frame(width: 44, height: 44)
            
            Image(systemName: session.modality.iconName)
                .font(.system(size: 18))
                .foregroundStyle(session.modality.tintColor)
        }
    }
    
    // MARK: - Mini Chart
    
    private var miniChart: some View {
        HStack(alignment: .bottom, spacing: 2) {
            let measurements = (session.measurements ?? []).suffix(5)
            ForEach(Array(measurements.enumerated()), id: \.offset) { _, measurement in
                RoundedRectangle(cornerRadius: 1)
                    .fill(ColorPalette.selfCircleCore.gradient)
                    .frame(width: 4, height: max(4, CGFloat(measurement.primaryValue) * 30))
            }
        }
        .frame(width: 30, height: 30, alignment: .bottom)
    }
}

#Preview {
    VStack {
        SessionRowView(session: {
            let session = SessionModel(modality: .basicIOS)
            session.measurements = [
                MeasurementModel(primaryValue: 0.3),
                MeasurementModel(primaryValue: 0.5),
                MeasurementModel(primaryValue: 0.7)
            ]
            session.notes = "Test session with some notes"
            return session
        }())
        
        SessionRowView(session: {
            let session = SessionModel(modality: .advancedIOS)
            session.measurements = [
                MeasurementModel(primaryValue: 0.8, secondaryValues: ["self_scale": 1.2, "other_scale": 0.8])
            ]
            return session
        }())
    }
    .padding()
    .gradientBackground()
}
