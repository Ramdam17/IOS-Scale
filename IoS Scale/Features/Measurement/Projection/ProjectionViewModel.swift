//
//  ProjectionViewModel.swift
//  IoS Scale
//
//  ViewModel for Projection modality - Self projects qualities onto Other.
//  Question: "To what extent do I project myself onto the other?"
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing the Projection measurement state and logic
@MainActor
final class ProjectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Projection value: 0 = separate, 1 = fully projected onto Other
    @Published var projectionValue: Double = 0.0
    
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
    
    /// Label describing the current projection state
    var projectionLabel: String {
        switch projectionValue {
        case 0..<0.15:
            return "Separate"
        case 0.15..<0.35:
            return "Slight Projection"
        case 0.35..<0.55:
            return "Moderate Projection"
        case 0.55..<0.75:
            return "Strong Projection"
        case 0.75..<0.95:
            return "Deep Projection"
        default:
            return "Full Projection"
        }
    }
    
    /// Description of the current projection state
    var projectionDescription: String {
        switch projectionValue {
        case 0..<0.15:
            return "I see the other as completely separate"
        case 0.15..<0.35:
            return "I slightly project myself onto the other"
        case 0.35..<0.55:
            return "I project some of my qualities onto the other"
        case 0.55..<0.75:
            return "I strongly project myself onto the other"
        case 0.75..<0.95:
            return "Much of what I see in the other is me"
        default:
            return "I fully project myself onto the other"
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
        let session = SessionModel(modality: .projection)
        currentSession = session
        modelContext?.insert(session)
    }
    
    // MARK: - Actions
    
    /// Save the current measurement
    func saveMeasurement() {
        guard let session = currentSession else { return }
        
        let measurement = MeasurementModel(
            primaryValue: projectionValue,
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
