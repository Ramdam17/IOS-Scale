//
//  Measurement.swift
//  IoS Scale
//
//  Represents a single measurement captured during a session.
//

import Foundation
import SwiftData

/// A single measurement data point
struct Measurement: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    
    /// Primary measurement value, always normalized to 0.0 - 1.0 range
    let primaryValue: Double
    
    /// Optional secondary values for modalities that capture additional data
    /// For example: selfScale, otherScale in Advanced IOS
    let secondaryValues: [String: Double]?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        primaryValue: Double,
        secondaryValues: [String: Double]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.primaryValue = min(max(primaryValue, 0.0), 1.0) // Clamp to 0-1
        self.secondaryValues = secondaryValues
    }
}

// MARK: - Secondary Value Keys

extension Measurement {
    /// Keys for secondary values used across modalities
    enum SecondaryKey: String {
        case selfScale = "self_scale"
        case otherScale = "other_scale"
        case selfInSet = "self_in_set"
        case otherInSet = "other_in_set"
    }
    
    /// Convenience accessor for self scale (Advanced IOS)
    var selfScale: Double? {
        secondaryValues?[SecondaryKey.selfScale.rawValue]
    }
    
    /// Convenience accessor for other scale (Advanced IOS)
    var otherScale: Double? {
        secondaryValues?[SecondaryKey.otherScale.rawValue]
    }
}

// MARK: - SwiftData Model

@Model
final class MeasurementModel {
    var id: UUID
    var timestamp: Date
    var primaryValue: Double
    var secondaryValuesData: Data?
    
    @Relationship(inverse: \SessionModel.measurements)
    var session: SessionModel?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        primaryValue: Double,
        secondaryValues: [String: Double]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.primaryValue = min(max(primaryValue, 0.0), 1.0)
        
        if let values = secondaryValues {
            self.secondaryValuesData = try? JSONEncoder().encode(values)
        }
    }
    
    /// Decode secondary values from stored data
    var secondaryValues: [String: Double]? {
        guard let data = secondaryValuesData else { return nil }
        return try? JSONDecoder().decode([String: Double].self, from: data)
    }
    
    /// Convert to value type
    func toMeasurement() -> Measurement {
        Measurement(
            id: id,
            timestamp: timestamp,
            primaryValue: primaryValue,
            secondaryValues: secondaryValues
        )
    }
}
