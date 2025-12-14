//
//  SetMembershipViewModel.swift
//  IoS Scale
//
//  ViewModel for Set Membership measurement mode.
//  Measures whether Self and Other belong to a shared group/category.
//

import SwiftUI
import SwiftData
import Combine

/// ViewModel managing state for Set Membership measurements
@MainActor
final class SetMembershipViewModel: ObservableObject {
    // MARK: - AppStorage Properties
    
    @AppStorage("reset_behavior") private var resetBehaviorRaw = ResetBehavior.resetToDefault.rawValue
    @AppStorage("last_self_in_set") private var lastSelfInSet: Bool = true
    @AppStorage("last_other_in_set") private var lastOtherInSet: Bool = false
    
    private var resetBehavior: ResetBehavior {
        ResetBehavior(rawValue: resetBehaviorRaw) ?? .resetToDefault
    }
    
    // MARK: - Published Properties
    
    /// Whether Self is inside the set
    @Published var selfInSet: Bool = true
    
    /// Whether Other is inside the set
    @Published var otherInSet: Bool = false
    
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
    
    // MARK: - Computed Properties
    
    /// Primary value representing membership state (0-3)
    /// - 0: Neither in set
    /// - 1: Self only in set
    /// - 2: Other only in set
    /// - 3: Both in set
    var primaryValue: Double {
        switch (selfInSet, otherInSet) {
        case (false, false):
            return 0.0  // Neither in set
        case (true, false):
            return 1.0  // Self only
        case (false, true):
            return 2.0  // Other only
        case (true, true):
            return 3.0  // Both in set
        }
    }
    
    /// Secondary values for detailed membership state
    var secondaryValues: [String: Double] {
        [
            "selfInSet": selfInSet ? 1.0 : 0.0,
            "otherInSet": otherInSet ? 1.0 : 0.0
        ]
    }
    
    // MARK: - Private Properties
    
    private let modality: ModalityType = .setMembership
    private var modelContext: ModelContext?
    private var currentSession: SessionModel?
    
    /// Initial membership states when measurement started (for Reset button)
    private var initialSelfInSet: Bool = true
    private var initialOtherInSet: Bool = false
    
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
            primaryValue: primaryValue,
            secondaryValues: secondaryValues
        )
        
        session.measurements?.append(measurement)
        
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
            primaryValue: primaryValue,
            secondaryValues: secondaryValues
        )
        
        session.measurements?.append(measurement)
        
        do {
            try context.save()
            measurementCount = (session.measurements ?? []).count
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
        if (session.measurements ?? []).isEmpty {
            context.delete(session)
        }
    }
    
    private func applyResetBehavior() {
        switch resetBehavior {
        case .keepPosition:
            // Restore last saved state
            selfInSet = lastSelfInSet
            otherInSet = lastOtherInSet
            
        case .resetToDefault:
            selfInSet = true
            otherInSet = false
            
        case .randomPosition:
            selfInSet = Bool.random()
            otherInSet = Bool.random()
        }
        
        // Store initial values for Reset button
        initialSelfInSet = selfInSet
        initialOtherInSet = otherInSet
    }
    
    /// Reset to initial state of current measurement
    func resetToInitial() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selfInSet = initialSelfInSet
            otherInSet = initialOtherInSet
        }
        HapticManager.shared.selection()
    }
    
    private func saveCurrentPosition() {
        lastSelfInSet = selfInSet
        lastOtherInSet = otherInSet
    }
}

// MARK: - Label Helpers

extension SetMembershipViewModel {
    /// Descriptive label for current membership state
    var membershipLabel: String {
        switch (selfInSet, otherInSet) {
        case (true, true):
            return "Same Set"
        case (true, false):
            return "Only Self in Set"
        case (false, true):
            return "Only Other in Set"
        case (false, false):
            return "Neither in Set"
        }
    }
    
    /// Short description of the membership state
    var membershipDescription: String {
        switch (selfInSet, otherInSet) {
        case (true, true):
            return "We belong together"
        case (true, false):
            return "I'm part of this, not them"
        case (false, true):
            return "They're part of this, not me"
        case (false, false):
            return "Neither of us belongs"
        }
    }
    
    /// Visual indicator of shared membership
    var sharedMembershipText: String {
        if selfInSet && otherInSet {
            return "Shared Membership"
        } else if selfInSet || otherInSet {
            return "Partial Membership"
        } else {
            return "No Membership"
        }
    }
}
