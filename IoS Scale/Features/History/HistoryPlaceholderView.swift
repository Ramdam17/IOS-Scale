//
//  HistoryPlaceholderView.swift
//  IoS Scale
//
//  Placeholder view for session history (Sprint 4).
//

import SwiftUI
import SwiftData

/// Placeholder view for session history - will be fully implemented in Sprint 4
struct HistoryPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \SessionModel.createdAt, order: .reverse) private var sessions: [SessionModel]
    
    @State private var showExportSheet = false
    
    private var totalMeasurements: Int {
        sessions.reduce(0) { $0 + ($1.measurements ?? []).count }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 60))
                    .foregroundStyle(ColorPalette.selfCircleCore.gradient)
                
                // Title
                Text("Session History")
                    .font(Typography.title2)
                
                // Stats
                if !sessions.isEmpty {
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xl) {
                            VStack {
                                Text("\(sessions.count)")
                                    .font(Typography.title)
                                    .foregroundStyle(ColorPalette.selfCircleCore)
                                Text("Sessions")
                                    .font(Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack {
                                Text("\(totalMeasurements)")
                                    .font(Typography.title)
                                    .foregroundStyle(ColorPalette.otherCircleCore)
                                Text("Measurements")
                                    .font(Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Export button
                        Button {
                            showExportSheet = true
                        } label: {
                            Label("Export All Data", systemImage: "square.and.arrow.up")
                                .font(Typography.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(ColorPalette.primaryButtonGradient)
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.md)
                    }
                } else {
                    // Empty state
                    Text("No sessions yet.\nStart a measurement to see your history.")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                
                Spacer()
                
                // Coming soon note
                Text("Full history view coming in a future update.")
                    .font(Typography.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gradientBackground()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(sessions: nil)
            }
        }
    }
}

#Preview {
    HistoryPlaceholderView()
        .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
