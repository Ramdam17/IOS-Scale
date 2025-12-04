//
//  AttributionViewModel.swift
//  IoS Scale
//
//  ViewModel for Attribution modality - Perceived similarity between Self and Other.
//  Question: "How similar do I perceive myself to be with the other?"
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing the Attribution measurement state and logic
@MainActor
final class AttributionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Attribution/similarity value: 0 = very different, 1 = very similar
    @Published var similarityValue: Double = 0.5
    
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
    
    /// Label describing the current similarity state
    var similarityLabel: String {
        switch similarityValue {
        case 0..<0.15:
            return "Very Different"
        case 0.15..<0.35:
            return "Quite Different"
        case 0.35..<0.50:
            return "Somewhat Different"
        case 0.50..<0.65:
            return "Somewhat Similar"
        case 0.65..<0.85:
            return "Quite Similar"
        default:
            return "Very Similar"
        }
    }
    
    /// Description of the current similarity state
    var similarityDescription: String {
        switch similarityValue {
        case 0..<0.15:
            return "I perceive us as completely different"
        case 0.15..<0.35:
            return "I see more differences than similarities"
        case 0.35..<0.50:
            return "I notice some differences between us"
        case 0.50..<0.65:
            return "I notice some similarities between us"
        case 0.65..<0.85:
            return "I see more similarities than differences"
        default:
            return "I perceive us as very much alike"
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
        let session = SessionModel(modality: .attribution)
        currentSession = session
        modelContext?.insert(session)
    }
    
    // MARK: - Actions
    
    /// Save the current measurement
    func saveMeasurement() {
        guard let session = currentSession else { return }
        
        let measurement = MeasurementModel(
            primaryValue: similarityValue,
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
