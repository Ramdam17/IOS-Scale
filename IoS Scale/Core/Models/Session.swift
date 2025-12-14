//
//  Session.swift
//  IoS Scale
//
//  Represents a measurement session containing multiple measurements.
//

import Foundation
import SwiftData

/// A session containing multiple measurements of a specific modality
struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    let modality: ModalityType
    let createdAt: Date
    var measurements: [Measurement]
    
    /// Optional user-provided notes for the session
    var notes: String?
    
    init(
        id: UUID = UUID(),
        modality: ModalityType,
        createdAt: Date = Date(),
        measurements: [Measurement] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.modality = modality
        self.createdAt = createdAt
        self.measurements = measurements
        self.notes = notes
    }
    
    /// Add a new measurement to the session
    mutating func addMeasurement(_ measurement: Measurement) {
        measurements.append(measurement)
    }
}

// MARK: - Computed Properties

extension Session {
    /// Number of measurements in the session
    var measurementCount: Int {
        measurements.count
    }
    
    /// Average primary value across all measurements
    var averageValue: Double? {
        guard !measurements.isEmpty else { return nil }
        let sum = measurements.reduce(0.0) { $0 + $1.primaryValue }
        return sum / Double(measurements.count)
    }
    
    /// Minimum primary value in the session
    var minValue: Double? {
        measurements.map(\.primaryValue).min()
    }
    
    /// Maximum primary value in the session
    var maxValue: Double? {
        measurements.map(\.primaryValue).max()
    }
    
    /// Latest measurement timestamp
    var lastMeasurementAt: Date? {
        measurements.map(\.timestamp).max()
    }
}

// MARK: - SwiftData Model

@Model
final class SessionModel {
    // CloudKit requires default values for all non-optional attributes
    var id: UUID = UUID()
    var modalityRawValue: String = ModalityType.basicIOS.rawValue
    var createdAt: Date = Date()
    var notes: String?
    
    /// Soft delete: when not nil, session is in trash
    var deletedAt: Date?
    
    // CloudKit requires relationships to be optional
    @Relationship(deleteRule: .cascade)
    var measurements: [MeasurementModel]? = []
    
    init(
        id: UUID = UUID(),
        modality: ModalityType = .basicIOS,
        createdAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.modalityRawValue = modality.rawValue
        self.createdAt = createdAt
        self.notes = notes
        self.deletedAt = nil
        self.measurements = []
    }
    
    /// Get the modality type
    var modality: ModalityType {
        ModalityType(rawValue: modalityRawValue) ?? .basicIOS
    }
    
    /// Whether the session is in trash
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    /// Move to trash (soft delete)
    func moveToTrash() {
        deletedAt = Date()
    }
    
    /// Restore from trash
    func restore() {
        deletedAt = nil
    }
    
    /// Convert to value type
    func toSession() -> Session {
        Session(
            id: id,
            modality: modality,
            createdAt: createdAt,
            measurements: (measurements ?? []).map { $0.toMeasurement() },
            notes: notes
        )
    }
}
