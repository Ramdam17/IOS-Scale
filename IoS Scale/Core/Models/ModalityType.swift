//
//  ModalityType.swift
//  IoS Scale
//
//  Defines all measurement modality types available in the app.
//

import Foundation
import SwiftUI

/// Represents the 9 different measurement modalities
enum ModalityType: String, Codable, CaseIterable, Identifiable {
    // Classic modalities
    case basicIOS = "basic_ios"
    case advancedIOS = "advanced_ios"
    
    // Research modalities
    case overlap = "overlap"
    case setMembership = "set_membership"
    case proximity = "proximity"
    case identification = "identification"
    case projection = "projection"
    case attribution = "attribution"
    case observation = "observation"
    
    var id: String { rawValue }
    
    /// Display name for the modality
    var displayName: String {
        switch self {
        case .basicIOS: return "Basic IOS"
        case .advancedIOS: return "Advanced IOS"
        case .overlap: return "Overlap"
        case .setMembership: return "Set Membership"
        case .proximity: return "Proximity"
        case .identification: return "Identification"
        case .projection: return "Projection"
        case .attribution: return "Attribution"
        case .observation: return "Observation"
        }
    }
    
    /// Short description of the modality
    var description: String {
        switch self {
        case .basicIOS:
            return "Classic distance-based measurement using two circles"
        case .advancedIOS:
            return "Extended scale with adjustable circle sizes"
        case .overlap:
            return "Measures the degree of overlap between Self and Other"
        case .setMembership:
            return "Whether Self and Other belong to a shared group"
        case .proximity:
            return "Pure distance measurement without overlap"
        case .identification:
            return "Self absorbs qualities of Other"
        case .projection:
            return "Self projects onto Other"
        case .attribution:
            return "Perceived similarity across dimensions"
        case .observation:
            return "Being an observer vs participant"
        }
    }
    
    /// SF Symbol icon for the modality
    var iconName: String {
        switch self {
        case .basicIOS: return "circle.circle"
        case .advancedIOS: return "circle.lefthalf.filled"
        case .overlap: return "circle.fill.square.fill"
        case .setMembership: return "rectangle.3.group"
        case .proximity: return "arrow.left.and.right"
        case .identification: return "person.fill.turn.right"
        case .projection: return "person.fill.turn.left"
        case .attribution: return "list.bullet.clipboard"
        case .observation: return "eye"
        }
    }
    
    /// Tint color for the modality card
    var tintColor: Color {
        switch self {
        case .basicIOS: return Color(hex: "74B9FF")
        case .advancedIOS: return Color(hex: "FD79A8")
        case .overlap: return Color(hex: "A29BFE")
        case .setMembership: return Color(hex: "636E72")
        case .proximity: return Color(hex: "00CEC9")
        case .identification: return Color(hex: "FDCB6E")
        case .projection: return Color(hex: "E17055")
        case .attribution: return Color(hex: "FAB1A0")
        case .observation: return Color(hex: "81ECEC")
        }
    }
    
    /// Whether the modality is currently available
    var isAvailable: Bool {
        switch self {
        case .basicIOS, .advancedIOS, .overlap, .setMembership, .proximity, .identification, .projection, .attribution:
            return true
        default:
            return false // Coming in future updates
        }
    }
}
