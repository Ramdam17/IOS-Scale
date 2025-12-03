//
//  ExportSheet.swift
//  IoS Scale
//
//  Sheet view for exporting session data.
//

import SwiftUI
import SwiftData

/// Sheet for configuring and initiating data export
struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    /// Sessions to export (nil = all sessions)
    let sessions: [SessionModel]?
    
    @State private var selectedFormat: ExportFormat = .csv
    @State private var includeMetadata: Bool = true
    @State private var isExporting: Bool = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet: Bool = false
    @State private var errorMessage: String?
    
    // Fetch all sessions if none provided
    @Query(sort: \SessionModel.createdAt, order: .reverse) private var allSessions: [SessionModel]
    
    private var sessionsToExport: [SessionModel] {
        sessions ?? allSessions
    }
    
    private var measurementCount: Int {
        sessionsToExport.reduce(0) { $0 + $1.measurements.count }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Summary section
                Section {
                    HStack {
                        Label("Sessions", systemImage: "folder")
                        Spacer()
                        Text("\(sessionsToExport.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Measurements", systemImage: "chart.dots.scatter")
                        Spacer()
                        Text("\(measurementCount)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Export Summary")
                }
                
                // Format selection
                Section {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Format description
                    Text(formatDescription)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Export Format")
                }
                
                // Options
                Section {
                    Toggle("Include Metadata", isOn: $includeMetadata)
                    
                    if includeMetadata {
                        Text("Includes session labels, creation dates, and scale values")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Options")
                }
                
                // Preview
                Section {
                    previewContent
                } header: {
                    Text("Preview")
                }
                
                // Error message
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        exportData()
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Text("Export")
                        }
                    }
                    .disabled(isExporting || sessionsToExport.isEmpty)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    // MARK: - Format Description
    
    private var formatDescription: String {
        switch selectedFormat {
        case .csv:
            return "Comma-separated values. Opens in Excel, Numbers, and most spreadsheet apps."
        case .tsv:
            return "Tab-separated values. Good for importing into statistical software."
        case .json:
            return "Structured data format. Best for programmatic access and data processing."
        }
    }
    
    // MARK: - Preview Content
    
    @ViewBuilder
    private var previewContent: some View {
        if sessionsToExport.isEmpty {
            Text("No data to export")
                .foregroundStyle(.secondary)
        } else {
            let filename = ExportService.shared.generateFilename(
                for: sessionsToExport,
                format: selectedFormat
            )
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: fileIcon)
                        .font(.title2)
                        .foregroundStyle(selectedFormat == .json ? .orange : .green)
                    
                    VStack(alignment: .leading) {
                        Text(filename)
                            .font(Typography.subheadline)
                            .lineLimit(1)
                        
                        Text(selectedFormat.mimeType)
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var fileIcon: String {
        switch selectedFormat {
        case .csv, .tsv:
            return "tablecells"
        case .json:
            return "curlybraces"
        }
    }
    
    // MARK: - Export Action
    
    private func exportData() {
        isExporting = true
        errorMessage = nil
        
        Task {
            do {
                guard let data = ExportService.shared.exportSessions(
                    sessionsToExport,
                    format: selectedFormat,
                    includeMetadata: includeMetadata
                ) else {
                    throw ExportError.generationFailed
                }
                
                let filename = ExportService.shared.generateFilename(
                    for: sessionsToExport,
                    format: selectedFormat
                )
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: tempURL)
                
                await MainActor.run {
                    exportedFileURL = tempURL
                    isExporting = false
                    showShareSheet = true
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Export failed: \(error.localizedDescription)"
                    isExporting = false
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case generationFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Failed to generate export file"
        case .saveFailed:
            return "Failed to save export file"
        }
    }
}

// MARK: - Share Sheet (UIKit wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ExportSheet(sessions: nil)
        .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
