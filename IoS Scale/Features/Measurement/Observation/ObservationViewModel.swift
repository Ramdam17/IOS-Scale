//
//  ObservationViewModel.swift
//  IoS Scale
//
//  ViewModel for Observation modality - Observer vs Participant perspective.
//  Question: "Am I observing from outside or participating from inside?"
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing the Observation measurement state and logic
@MainActor
final class ObservationViewModel: ObservableObject {
    
    // MARK: - AppStorage Properties
    
    @AppStorage("reset_behavior") private var resetBehaviorRaw = ResetBehavior.resetToDefault.rawValue
    @AppStorage("last_position_observation") private var lastPosition: Double = 0.0
    
    private var resetBehavior: ResetBehavior {
        ResetBehavior(rawValue: resetBehaviorRaw) ?? .resetToDefault
    }
    
    // MARK: - Published Properties
    
    /// Observation value: 0 = pure observer (outside), 1 = full participant (immersed)
    @Published var participationValue: Double = 0.0
    
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
    
    // MARK: - Computed Properties
    
    /// Label describing the current observation state
    var observationLabel: String {
        switch participationValue {
        case 0..<0.15:
            return "Pure Observer"
        case 0.15..<0.35:
            return "Distant Observer"
        case 0.35..<0.50:
            return "Engaged Observer"
        case 0.50..<0.65:
            return "Partial Participant"
        case 0.65..<0.85:
            return "Active Participant"
        default:
            return "Fully Immersed"
        }
    }
    
    /// Description of the current observation state
    var observationDescription: String {
        switch participationValue {
        case 0..<0.15:
            return "I watch from a complete distance"
        case 0.15..<0.35:
            return "I observe with some detachment"
        case 0.35..<0.50:
            return "I observe while feeling some connection"
        case 0.50..<0.65:
            return "I participate while still observing"
        case 0.65..<0.85:
            return "I am actively engaged in the experience"
        default:
            return "I am fully immersed in the moment"
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
        let session = SessionModel(modality: .observation)
        currentSession = session
        modelContext?.insert(session)
    }
    
    // MARK: - Actions
    
    /// Save the current measurement
    func saveMeasurement() {
        guard let session = currentSession else { return }
        
        let measurement = MeasurementModel(
            primaryValue: participationValue,
            secondaryValues: nil
        )
        
        session.measurements.append(measurement)
        measurementCount = session.measurements.count
        
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
                saveMeasurement()
            }
            try? modelContext?.save()
            shouldDismiss = true
            
        case .exitWithoutSaving:
            if let session = currentSession, session.measurements.isEmpty {
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
            participationValue = lastPosition
            
        case .resetToDefault:
            participationValue = 0.0
            
        case .randomPosition:
            participationValue = Double.random(in: 0.0...0.8)
        }
    }
    
    private func saveCurrentPosition() {
        lastPosition = participationValue
    }
}
