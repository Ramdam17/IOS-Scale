//
//  ExportService.swift
//  IoS Scale
//
//  Service for exporting session data to various formats.
//

import Foundation
import SwiftData

// ExportFormat is defined in AppSettings.swift

/// Extension to add separator property for delimited export
extension ExportFormat {
    var separator: String {
        switch self {
        case .csv: return ","
        case .tsv: return "\t"
        case .json: return ""
        }
    }
}

/// Service for exporting session data
@MainActor
final class ExportService {
    
    // MARK: - Singleton
    
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - Export Methods
    
    /// Export a single session to the specified format
    func exportSession(_ session: SessionModel, format: ExportFormat, includeMetadata: Bool = true) -> Data? {
        switch format {
        case .csv, .tsv:
            return exportToDelimited(sessions: [session], format: format, includeMetadata: includeMetadata)
        case .json:
            return exportToJSON(sessions: [session], includeMetadata: includeMetadata)
        }
    }
    
    /// Export multiple sessions to the specified format
    func exportSessions(_ sessions: [SessionModel], format: ExportFormat, includeMetadata: Bool = true) -> Data? {
        switch format {
        case .csv, .tsv:
            return exportToDelimited(sessions: sessions, format: format, includeMetadata: includeMetadata)
        case .json:
            return exportToJSON(sessions: sessions, includeMetadata: includeMetadata)
        }
    }
    
    /// Generate a filename for the export
    func generateFilename(for sessions: [SessionModel], format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        if sessions.count == 1, let session = sessions.first {
            let modalityName = session.modality.rawValue.replacingOccurrences(of: " ", with: "_")
            return "IOS_Scale_\(modalityName)_\(timestamp).\(format.fileExtension)"
        } else {
            return "IOS_Scale_Export_\(timestamp).\(format.fileExtension)"
        }
    }
    
    // MARK: - Private Methods
    
    /// Export to CSV or TSV format
    private func exportToDelimited(sessions: [SessionModel], format: ExportFormat, includeMetadata: Bool) -> Data? {
        let separator = format.separator
        var lines: [String] = []
        
        // Header row
        var headers = ["session_id", "modality", "measurement_id", "timestamp", "primary_value"]
        if includeMetadata {
            headers.append(contentsOf: ["self_scale", "other_scale", "session_created", "session_notes"])
        }
        lines.append(headers.joined(separator: separator))
        
        // Data rows
        let dateFormatter = ISO8601DateFormatter()
        
        for session in sessions {
            for measurement in session.measurements {
                var row: [String] = [
                    session.id.uuidString,
                    session.modality.rawValue,
                    measurement.id.uuidString,
                    dateFormatter.string(from: measurement.timestamp),
                    formatNumber(measurement.primaryValue)
                ]
                
                if includeMetadata {
                    let selfScale = measurement.secondaryValues?[Measurement.SecondaryKey.selfScale.rawValue]
                    let otherScale = measurement.secondaryValues?[Measurement.SecondaryKey.otherScale.rawValue]
                    
                    row.append(contentsOf: [
                        selfScale.map { formatNumber($0) } ?? "",
                        otherScale.map { formatNumber($0) } ?? "",
                        dateFormatter.string(from: session.createdAt),
                        escapeForDelimited(session.notes ?? "", separator: separator)
                    ])
                }
                
                lines.append(row.joined(separator: separator))
            }
        }
        
        let content = lines.joined(separator: "\n")
        return content.data(using: .utf8)
    }
    
    /// Export to JSON format
    private func exportToJSON(sessions: [SessionModel], includeMetadata: Bool) -> Data? {
        let exportData = ExportData(sessions: sessions, includeMetadata: includeMetadata)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(exportData)
        } catch {
            print("Failed to encode JSON: \(error)")
            return nil
        }
    }
    
    /// Format a number with consistent decimal places
    private func formatNumber(_ value: Double) -> String {
        String(format: "%.4f", value)
    }
    
    /// Escape string for delimited format (handle quotes and separators)
    private func escapeForDelimited(_ value: String, separator: String) -> String {
        if value.contains(separator) || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}

// MARK: - Export Data Structure

/// Codable structure for JSON export
struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let sessions: [ExportSession]
    
    init(sessions: [SessionModel], includeMetadata: Bool) {
        self.exportDate = Date()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        self.sessions = sessions.map { ExportSession(from: $0, includeMetadata: includeMetadata) }
    }
}

struct ExportSession: Codable {
    let id: String
    let modality: String
    let createdAt: Date
    let notes: String?
    let measurements: [ExportMeasurement]
    
    init(from session: SessionModel, includeMetadata: Bool) {
        self.id = session.id.uuidString
        self.modality = session.modality.rawValue
        self.createdAt = session.createdAt
        self.notes = includeMetadata ? session.notes : nil
        self.measurements = session.measurements.map { ExportMeasurement(from: $0, includeMetadata: includeMetadata) }
    }
}

struct ExportMeasurement: Codable {
    let id: String
    let timestamp: Date
    let primaryValue: Double
    let selfScale: Double?
    let otherScale: Double?
    
    init(from measurement: MeasurementModel, includeMetadata: Bool) {
        self.id = measurement.id.uuidString
        self.timestamp = measurement.timestamp
        self.primaryValue = measurement.primaryValue
        
        if includeMetadata {
            self.selfScale = measurement.secondaryValues?[Measurement.SecondaryKey.selfScale.rawValue]
            self.otherScale = measurement.secondaryValues?[Measurement.SecondaryKey.otherScale.rawValue]
        } else {
            self.selfScale = nil
            self.otherScale = nil
        }
    }
}
