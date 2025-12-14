//
//  BasicIOSViewModel.swift
//  IoS Scale
//
//  ViewModel for Basic IOS measurement mode.
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing state for Basic IOS measurements
@MainActor
final class BasicIOSViewModel: ObservableObject {
    // MARK: - AppStorage Properties
    
    @AppStorage("reset_behavior") private var resetBehaviorRaw = ResetBehavior.resetToDefault.rawValue
    @AppStorage("last_position_basic_ios") private var lastPosition: Double = 0.5
    
    private var resetBehavior: ResetBehavior {
        ResetBehavior(rawValue: resetBehaviorRaw) ?? .resetToDefault
    }
    
    // MARK: - Published Properties
    
    /// Current overlap value (0 = distant, 1 = merged)
    @Published var overlapValue: Double = 0.5
    
    /// Whether user is currently dragging
    @Published var isDragging: Bool = false
    
    /// Show exit confirmation sheet
    @Published var showExitSheet: Bool = false
    
    /// Should dismiss the view
    @Published var shouldDismiss: Bool = false
    
    /// Number of measurements saved in current session
    @Published private(set) var measurementCount: Int = 0
    
    /// Show save confirmation feedback
    @Published var showSaveConfirmation: Bool = false
    
    // MARK: - Private Properties
    
    private let modality: ModalityType = .basicIOS
    private var modelContext: ModelContext?
    private var currentSession: SessionModel?
    
    /// Initial overlap value when measurement started (for Reset button)
    private var initialOverlapValue: Double = 0.5
    
    // MARK: - Initialization
    
    init() {
        applyResetBehavior()
    }
    
    // MARK: - Public Methods
    
    /// Configure with SwiftData model context
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        createSession()
    }
    
    /// Request to exit the session
    func requestExit() {
        showExitSheet = true
    }
    
    /// Handle exit action from sheet
    func handleExitAction(_ action: ExitSessionAction) {
        showExitSheet = false
        
        switch action {
        case .saveAndExit:
            saveMeasurementAndExit()
            
        case .exitWithoutSaving:
            discardSessionIfEmpty()
            shouldDismiss = true
            
        case .cancel:
            break
        }
    }
    
    /// Save current measurement and exit
    private func saveMeasurementAndExit() {
        guard let session = currentSession, let context = modelContext else {
            shouldDismiss = true
            return
        }
        
        let measurement = MeasurementModel(
            primaryValue: overlapValue
        )
        
        session.measurements.append(measurement)
        
        do {
            try context.save()
            HapticManager.shared.success()
        } catch {
            print("Failed to save measurement: \(error)")
            HapticManager.shared.error()
        }
        
        shouldDismiss = true
    }
    
    /// Save the current measurement state
    func saveMeasurement() {
        guard let session = currentSession, let context = modelContext else { return }
        
        let measurement = MeasurementModel(
            primaryValue: overlapValue
        )
        
        session.measurements.append(measurement)
        
        do {
            try context.save()
            measurementCount = session.measurements.count
            showSaveConfirmation = true
            HapticManager.shared.success()
            
            // Save current position before applying reset behavior
            saveCurrentPosition()
            
            // Apply reset behavior for next measurement
            applyResetBehavior()
            
            // Hide confirmation after delay
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showSaveConfirmation = false
            }
        } catch {
            print("Failed to save measurement: \(error)")
            HapticManager.shared.error()
        }
    }
    
    // MARK: - Private Methods
    
    private func createSession() {
        guard let context = modelContext else { return }
        
        let session = SessionModel(modality: modality)
        context.insert(session)
        currentSession = session
    }
    
    private func discardSessionIfEmpty() {
        guard let session = currentSession, let context = modelContext else { return }
        
        // Only delete if no measurements were saved
        if session.measurements.isEmpty {
            context.delete(session)
        }
    }
    
    private func applyResetBehavior() {
        switch resetBehavior {
        case .keepPosition:
            // Restore last saved position
            overlapValue = lastPosition
            
        case .resetToDefault:
            overlapValue = 0.5
            
        case .randomPosition:
            overlapValue = Double.random(in: 0.2...0.8)
        }
        
        // Store initial value for Reset button
        initialOverlapValue = overlapValue
    }
    
    /// Reset to initial state of current measurement
    func resetToInitial() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            overlapValue = initialOverlapValue
        }
        HapticManager.shared.selection()
    }
    
    private func saveCurrentPosition() {
        lastPosition = overlapValue
    }
}

// MARK: - Label Helpers

extension BasicIOSViewModel {
    /// Descriptive label for current overlap state
    var overlapLabel: String {
        switch overlapValue {
        case 0..<0.2:
            return "Distant"
        case 0.2..<0.5:
            return "Separate"
        case 0.5..<0.75:
            return "Close"
        case 0.75..<0.95:
            return "Connected"
        default:
            return "Merged"
        }
    }
}
