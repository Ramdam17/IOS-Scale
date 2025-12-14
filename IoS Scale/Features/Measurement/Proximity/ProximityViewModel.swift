//
//  ProximityViewModel.swift
//  IoS Scale
//
//  ViewModel for Proximity modality - measures pure distance without overlap.
//  Question: "How close do I feel to the other?"
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing the Proximity measurement state and logic
@MainActor
final class ProximityViewModel: ObservableObject {
    
    // MARK: - AppStorage Properties
    
    @AppStorage("reset_behavior") private var resetBehaviorRaw = ResetBehavior.resetToDefault.rawValue
    @AppStorage("last_position_proximity") private var lastPosition: Double = 0.0
    
    private var resetBehavior: ResetBehavior {
        ResetBehavior(rawValue: resetBehaviorRaw) ?? .resetToDefault
    }
    
    // MARK: - Published Properties
    
    /// Proximity value: 0 = far apart, 1 = touching
    @Published var proximityValue: Double = 0.0
    
    /// Normalized position of the Self circle (0 = left edge, 1 = right edge)
    @Published var selfPositionNormalized: Double = 0.25
    
    /// Normalized position of the Other circle (0 = left edge, 1 = right edge)
    @Published var otherPositionNormalized: Double = 0.75
    
    /// Whether the user is currently dragging
    @Published var isDragging: Bool = false
    
    /// Number of measurements saved in current session
    @Published private(set) var measurementCount: Int = 0
    
    /// Whether to show exit confirmation sheet
    @Published var showExitSheet: Bool = false
    
    /// Whether to show save confirmation
    @Published var showSaveConfirmation: Bool = false
    
    /// Whether view should dismiss
    @Published var shouldDismiss: Bool = false
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private var currentSession: SessionModel?
    
    /// Initial proximity value when measurement started (for Reset button)
    private var initialProximityValue: Double = 0.0
    
    // MARK: - Computed Properties
    
    /// Label describing the current proximity state
    var proximityLabel: String {
        switch proximityValue {
        case 0..<0.15:
            return "Very Distant"
        case 0.15..<0.35:
            return "Distant"
        case 0.35..<0.55:
            return "Moderate"
        case 0.55..<0.75:
            return "Close"
        case 0.75..<0.95:
            return "Very Close"
        default:
            return "Touching"
        }
    }
    
    /// Description of the current proximity state
    var proximityDescription: String {
        switch proximityValue {
        case 0..<0.15:
            return "Far apart, minimal connection"
        case 0.15..<0.35:
            return "Some distance between us"
        case 0.35..<0.55:
            return "Neither close nor far"
        case 0.55..<0.75:
            return "Feeling connected"
        case 0.75..<0.95:
            return "Strong sense of closeness"
        default:
            return "As close as possible"
        }
    }
    
    // MARK: - Configuration
    
    /// Configure the view model with a model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        createSession()
    }
    
    // MARK: - Session Management
    
    private func createSession() {
        let session = SessionModel(modality: .proximity)
        currentSession = session
        modelContext?.insert(session)
    }
    
    // MARK: - Actions
    
    /// Save the current measurement
    func saveMeasurement() {
        guard let session = currentSession else { return }
        
        // Include circle positions as secondary values for scientific analysis
        let secondaryValues: [String: Double] = [
            Measurement.SecondaryKey.selfPosition.rawValue: selfPositionNormalized,
            Measurement.SecondaryKey.otherPosition.rawValue: otherPositionNormalized
        ]
        
        let measurement = MeasurementModel(
            primaryValue: proximityValue,
            secondaryValues: secondaryValues
        )
        
        session.measurements?.append(measurement)
        measurementCount = (session.measurements ?? []).count
        
        // Save context
        try? modelContext?.save()
        
        // Show confirmation
        showSaveConfirmation = true
        HapticManager.shared.success()
        
        // Save current position before applying reset behavior
        saveCurrentPosition()
        
        // Apply reset behavior for next measurement
        applyResetBehavior()
        
        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showSaveConfirmation = false
        }
    }
    
    /// Request to exit the session
    func requestExit() {
        showExitSheet = true
    }
    
    /// Handle exit action from sheet
    func handleExitAction(_ action: ExitSessionAction) {
        switch action {
        case .saveAndExit:
            if measurementCount == 0 {
                // Save current state before exiting
                saveMeasurement()
            }
            try? modelContext?.save()
            shouldDismiss = true
            
        case .exitWithoutSaving:
            // Delete session if no measurements
            if let session = currentSession, (session.measurements ?? []).isEmpty {
                modelContext?.delete(session)
            }
            shouldDismiss = true
            
        case .cancel:
            break
        }
    }
    
    // MARK: - Reset Behavior
    
    private func applyResetBehavior() {
        switch resetBehavior {
        case .keepPosition:
            // Restore last saved position
            proximityValue = lastPosition
            
        case .resetToDefault:
            proximityValue = 0.0
            
        case .randomPosition:
            proximityValue = Double.random(in: 0.0...0.8)
        }
        
        // Store initial value for Reset button
        initialProximityValue = proximityValue
    }
    
    /// Reset to initial state of current measurement
    func resetToInitial() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            proximityValue = initialProximityValue
        }
        HapticManager.shared.selection()
    }
    
    private func saveCurrentPosition() {
        lastPosition = proximityValue
    }
}
