//
//  SessionDetailView.swift
//  IoS Scale
//
//  Detailed view showing all measurements in a session with visualization.
//

import SwiftUI
import SwiftData

/// Displays detailed information about a single session including all measurements
struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: SessionModel
    
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false
    @State private var isEditingNotes = false
    @State private var editedNotes: String = ""
    
    private var sortedMeasurements: [MeasurementModel] {
        (session.measurements ?? []).sorted { $0.timestamp < $1.timestamp }
    }
    
    private var averageValue: Double {
        guard !(session.measurements ?? []).isEmpty else { return 0 }
        let sum = (session.measurements ?? []).reduce(0.0) { $0 + $1.primaryValue }
        return sum / Double((session.measurements ?? []).count)
    }
    
    private var minValue: Double {
        (session.measurements ?? []).map(\.primaryValue).min() ?? 0
    }
    
    private var maxValue: Double {
        (session.measurements ?? []).map(\.primaryValue).max() ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Session header
                sessionHeader
                
                // Chart visualization
                if (session.measurements ?? []).count > 1 {
                    chartSection
                }
                
                // Stats cards
                statsSection
                
                // Notes section
                notesSection
                
                // Measurements list
                measurementsSection
            }
            .padding(Spacing.md)
        }
        .gradientBackground()
        .navigationTitle(session.modality.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export Session", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Session", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(sessions: [session])
        }
        .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("This will permanently delete this session and all its measurements.")
        }
    }
    
    // MARK: - Session Header
    
    private var sessionHeader: some View {
        VStack(spacing: Spacing.md) {
            // Modality icon
            ZStack {
                Circle()
                    .fill(session.modality.tintColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: session.modality.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(session.modality.tintColor)
            }
            
            // Date and time
            VStack(spacing: Spacing.xs) {
                Text(formattedDate)
                    .font(Typography.headline)
                
                Text(formattedTime)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .glassBackground()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: session.createdAt)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.createdAt)
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Measurement Progression")
                .font(Typography.subheadline)
                .foregroundStyle(.secondary)
            
            // Visual grid of measurements
            measurementVisualizationGrid
        }
        .padding(Spacing.md)
        .glassBackground()
    }
    
    /// Grid of mini visualizations for each measurement
    private var measurementVisualizationGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 70, maximum: 80), spacing: Spacing.sm)
            ],
            spacing: Spacing.sm
        ) {
            ForEach(Array(sortedMeasurements.enumerated()), id: \.element.id) { index, measurement in
                VStack(spacing: 4) {
                    MeasurementVisualizationView(
                        measurement: measurement,
                        modality: session.modality,
                        size: 60
                    )
                    .background(Color.primary.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("#\(index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: Spacing.md) {
            // Universal stats row
            HStack(spacing: Spacing.md) {
                StatCard(
                    title: "Count",
                    value: "\((session.measurements ?? []).count)",
                    icon: "number"
                )
                
                StatCard(
                    title: "Average",
                    value: String(format: "%.0f%%", averageValue * 100),
                    icon: "chart.line.flattrend.xyaxis"
                )
                
                StatCard(
                    title: "Range",
                    value: String(format: "%.0f-%.0f%%", minValue * 100, maxValue * 100),
                    icon: "arrow.up.arrow.down"
                )
            }
            
            // Modality-specific stats
            modalitySpecificStats
        }
    }
    
    /// Stats specific to each modality type
    @ViewBuilder
    private var modalitySpecificStats: some View {
        switch session.modality {
        case .setMembership:
            setMembershipStats
        case .advancedIOS:
            advancedIOSStats
        default:
            EmptyView()
        }
    }
    
    // MARK: - Set Membership Stats
    
    private var setMembershipStats: some View {
        let bothIn = (session.measurements ?? []).filter { measurement in
            guard let values = measurement.secondaryValues else { return false }
            let selfIn = (values["selfInSet"] ?? 0) > 0.5
            let otherIn = (values["otherInSet"] ?? 0) > 0.5
            return selfIn && otherIn
        }.count
        
        let selfOnly = (session.measurements ?? []).filter { measurement in
            guard let values = measurement.secondaryValues else { return false }
            let selfIn = (values["selfInSet"] ?? 0) > 0.5
            let otherIn = (values["otherInSet"] ?? 0) > 0.5
            return selfIn && !otherIn
        }.count
        
        let otherOnly = (session.measurements ?? []).filter { measurement in
            guard let values = measurement.secondaryValues else { return false }
            let selfIn = (values["selfInSet"] ?? 0) > 0.5
            let otherIn = (values["otherInSet"] ?? 0) > 0.5
            return !selfIn && otherIn
        }.count
        
        let neither = (session.measurements ?? []).filter { measurement in
            guard let values = measurement.secondaryValues else { return measurement.primaryValue < 0.1 }
            let selfIn = (values["selfInSet"] ?? 0) > 0.5
            let otherIn = (values["otherInSet"] ?? 0) > 0.5
            return !selfIn && !otherIn
        }.count
        
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Set Membership Distribution")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.sm) {
                membershipStatBadge(
                    count: bothIn,
                    label: "Both",
                    color: Color(hex: "FFD700"),
                    icon: "checkmark.circle.fill"
                )
                
                membershipStatBadge(
                    count: selfOnly,
                    label: "Self only",
                    color: ColorPalette.selfCircleCore,
                    icon: "person.fill"
                )
                
                membershipStatBadge(
                    count: otherOnly,
                    label: "Other only",
                    color: ColorPalette.otherCircleCore,
                    icon: "person"
                )
                
                membershipStatBadge(
                    count: neither,
                    label: "Neither",
                    color: Color.gray,
                    icon: "xmark.circle"
                )
            }
        }
        .padding(Spacing.sm)
        .glassBackground()
    }
    
    private func membershipStatBadge(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption2)
                Text("\(count)")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Advanced IOS Stats
    
    private var advancedIOSStats: some View {
        let avgSelfScale = (session.measurements ?? []).compactMap { $0.secondaryValues?["selfScale"] ?? $0.secondaryValues?["self_scale"] }.reduce(0, +) / Double(max(1, (session.measurements ?? []).count))
        
        let avgOtherScale = (session.measurements ?? []).compactMap { $0.secondaryValues?["otherScale"] ?? $0.secondaryValues?["other_scale"] }.reduce(0, +) / Double(max(1, (session.measurements ?? []).count))
        
        return HStack(spacing: Spacing.md) {
            StatCard(
                title: "Avg Self Size",
                value: String(format: "%.1fx", avgSelfScale),
                icon: "person.fill"
            )
            
            StatCard(
                title: "Avg Other Size",
                value: String(format: "%.1fx", avgOtherScale),
                icon: "person"
            )
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Notes")
                    .font(Typography.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    editedNotes = session.notes ?? ""
                    isEditingNotes = true
                } label: {
                    Text(session.notes?.isEmpty ?? true ? "Add" : "Edit")
                        .font(Typography.caption)
                }
            }
            
            if isEditingNotes {
                TextField("Add notes...", text: $editedNotes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Typography.body)
                    .padding(Spacing.sm)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(3...6)
                
                HStack {
                    Button("Cancel") {
                        isEditingNotes = false
                    }
                    .font(Typography.caption)
                    
                    Spacer()
                    
                    Button("Save") {
                        session.notes = editedNotes.isEmpty ? nil : editedNotes
                        isEditingNotes = false
                        HapticManager.shared.success()
                    }
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                }
            } else if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(Typography.body)
                    .foregroundStyle(.primary)
            } else {
                Text("No notes added")
                    .font(Typography.body)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding(Spacing.md)
        .glassBackground()
    }
    
    // MARK: - Measurements Section
    
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Measurements")
                .font(Typography.subheadline)
                .foregroundStyle(.secondary)
            
            ForEach(Array(sortedMeasurements.enumerated()), id: \.element.id) { index, measurement in
                MeasurementRowView(
                    measurement: measurement,
                    index: index + 1,
                    modality: session.modality
                )
            }
        }
        .padding(Spacing.md)
        .glassBackground()
    }
    
    // MARK: - Actions
    
    private func deleteSession() {
        session.moveToTrash()
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Stat Card Component

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(Typography.headline)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .glassBackground()
    }
}

// MARK: - Measurement Chart

private struct MeasurementChart: View {
    let measurements: [MeasurementModel]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let count = measurements.count
            let spacing = count > 1 ? width / CGFloat(count - 1) : width / 2
            
            ZStack {
                // Grid lines
                VStack {
                    ForEach(0..<5) { i in
                        Divider()
                            .background(Color.primary.opacity(0.1))
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                
                // Line path
                Path { path in
                    for (index, measurement) in measurements.enumerated() {
                        let x = count > 1 ? CGFloat(index) * spacing : width / 2
                        let y = height - (CGFloat(measurement.primaryValue) * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [ColorPalette.selfCircleCore, ColorPalette.otherCircleCore],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                
                // Data points
                ForEach(Array(measurements.enumerated()), id: \.element.id) { index, measurement in
                    let x = count > 1 ? CGFloat(index) * spacing : width / 2
                    let y = height - (CGFloat(measurement.primaryValue) * height)
                    
                    Circle()
                        .fill(ColorPalette.selfCircleCore)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: {
            let session = SessionModel(modality: .basicIOS)
            session.measurements = [
                MeasurementModel(primaryValue: 0.2),
                MeasurementModel(primaryValue: 0.4),
                MeasurementModel(primaryValue: 0.35),
                MeasurementModel(primaryValue: 0.6),
                MeasurementModel(primaryValue: 0.8)
            ]
            session.notes = "Initial test session"
            return session
        }())
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
