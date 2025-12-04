//
//  IdentificationViewModel.swift
//  IoS Scale
//
//  ViewModel for Identification modality - Self absorbs qualities of Other.
//  Question: "To what extent do I identify with the other?"
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing the Identification measurement state and logic
@MainActor
final class IdentificationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Identification value: 0 = separate identities, 1 = fully identified with Other
    @Published var identificationValue: Double = 0.0
    
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
    
    /// Label describing the current identification state
    var identificationLabel: String {
        switch identificationValue {
        case 0..<0.15:
            return "Separate"
        case 0.15..<0.35:
            return "Slightly Connected"
        case 0.35..<0.55:
            return "Moderately Identified"
        case 0.55..<0.75:
            return "Strongly Identified"
        case 0.75..<0.95:
            return "Deeply Identified"
        default:
            return "Fully Identified"
        }
    }
    
    /// Description of the current identification state
    var identificationDescription: String {
        switch identificationValue {
        case 0..<0.15:
            return "I see the other as completely separate"
        case 0.15..<0.35:
            return "I notice some connection with the other"
        case 0.35..<0.55:
            return "I share some qualities with the other"
        case 0.55..<0.75:
            return "I strongly identify with the other"
        case 0.75..<0.95:
            return "The other's qualities feel like mine"
        default:
            return "I fully identify with the other"
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
        let session = SessionModel(modality: .identification)
        currentSession = session
        modelContext?.insert(session)
    }
    
    // MARK: - Actions
    
    /// Save the current measurement
    func saveMeasurement() {
        guard let session = currentSession else { return }
        
        let measurement = MeasurementModel(
            primaryValue: identificationValue,
            secondaryValues: nil
        )
        
        session.measurements.append(measurement)
        measurementCount = session.measurements.count
        
        // Save context
        try? modelContext?.save()
        
        // Show confirmation
        showSaveConfirmation = true
        HapticManager.shared.success()
        
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
}
