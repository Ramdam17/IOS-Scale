//
//  AdvancedIOSViewModel.swift
//  IoS Scale
//
//  ViewModel for Advanced IOS measurement mode.
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing state for Advanced IOS measurements
@MainActor
final class AdvancedIOSViewModel: ObservableObject {
    // MARK: - AppStorage Properties
    
    @AppStorage("reset_behavior") private var resetBehaviorRaw = ResetBehavior.resetToDefault.rawValue
    @AppStorage("last_position_advanced_ios") private var lastPosition: Double = 0.5
    @AppStorage("last_self_scale_advanced_ios") private var lastSelfScale: Double = 1.0
    @AppStorage("last_other_scale_advanced_ios") private var lastOtherScale: Double = 1.0
    
    private var resetBehavior: ResetBehavior {
        ResetBehavior(rawValue: resetBehaviorRaw) ?? .resetToDefault
    }
    
    // MARK: - Published Properties
    
    /// Current overlap value (0 = distant, 1 = merged)
    @Published var overlapValue: Double = 0.5
    
    /// Self circle scale (0.2 to 2.0)
    @Published var selfScale: Double = 1.0
    
    /// Other circle scale (0.2 to 2.0)
    @Published var otherScale: Double = 1.0
    
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
    
    private let modality: ModalityType = .advancedIOS
    private var modelContext: ModelContext?
    private var currentSession: SessionModel?
    
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
    
    /// Save the current measurement and continue the session
    func saveMeasurement() {
        guard let session = currentSession, let context = modelContext else { return }
        
        let secondaryValues: [String: Double] = [
            Measurement.SecondaryKey.selfScale.rawValue: selfScale,
            Measurement.SecondaryKey.otherScale.rawValue: otherScale
        ]
        
        let measurement = MeasurementModel(
            primaryValue: overlapValue,
            secondaryValues: secondaryValues
        )
        
        session.measurements.append(measurement)
        
        do {
            try context.save()
            measurementCount += 1
            HapticManager.shared.success()
            
            // Show confirmation briefly
            showSaveConfirmation = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                showSaveConfirmation = false
            }
            
            // Save current position before applying reset behavior
            saveCurrentPosition()
            
            // Apply reset behavior for next measurement
            applyResetBehavior()
        } catch {
            print("Failed to save measurement: \(error)")
            HapticManager.shared.error()
        }
    }
    
    /// Save measurement and exit immediately
    private func saveMeasurementAndExit() {
        guard let session = currentSession, let context = modelContext else { return }
        
        let secondaryValues: [String: Double] = [
            Measurement.SecondaryKey.selfScale.rawValue: selfScale,
            Measurement.SecondaryKey.otherScale.rawValue: otherScale
        ]
        
        let measurement = MeasurementModel(
            primaryValue: overlapValue,
            secondaryValues: secondaryValues
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
    
    /// Reset scales to default
    func resetScales() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selfScale = LayoutConstants.defaultCircleScale
            otherScale = LayoutConstants.defaultCircleScale
        }
        HapticManager.shared.selection()
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
        
        // Delete empty session
        if session.measurements.isEmpty {
            context.delete(session)
        }
    }
    
    private func applyResetBehavior() {
        switch resetBehavior {
        case .keepPosition:
            // Restore last saved position and scales
            overlapValue = lastPosition
            selfScale = lastSelfScale
            otherScale = lastOtherScale
            
        case .resetToDefault:
            overlapValue = 0.5
            selfScale = 1.0
            otherScale = 1.0
            
        case .randomPosition:
            overlapValue = Double.random(in: 0.2...0.8)
            selfScale = Double.random(in: 0.7...1.3)
            otherScale = Double.random(in: 0.7...1.3)
        }
    }
    
    private func saveCurrentPosition() {
        lastPosition = overlapValue
        lastSelfScale = selfScale
        lastOtherScale = otherScale
    }
}

// MARK: - Label Helpers

extension AdvancedIOSViewModel {
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
    
    /// Formatted scale ratio text
    var scaleRatioText: String {
        let ratio = selfScale / otherScale
        if abs(ratio - 1.0) < 0.1 {
            return "Equal size"
        } else if ratio > 1 {
            return "Self larger"
        } else {
            return "Other larger"
        }
    }
}
