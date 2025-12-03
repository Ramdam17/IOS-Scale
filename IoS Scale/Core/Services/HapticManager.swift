//
//  HapticManager.swift
//  IoS Scale
//
//  Manages haptic feedback throughout the app.
//

import SwiftUI
import UIKit

/// Singleton manager for haptic feedback
final class HapticManager {
    static let shared = HapticManager()
    
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        prepareGenerators()
    }
    
    /// Prepare all generators for faster response
    func prepareGenerators() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact for subtle feedback (value changes)
    func lightImpact() {
        guard isHapticEnabled else { return }
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare()
    }
    
    /// Medium impact for standard interactions
    func mediumImpact() {
        guard isHapticEnabled else { return }
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
    }
    
    /// Heavy impact for significant actions
    func heavyImpact() {
        guard isHapticEnabled else { return }
        heavyImpactGenerator.impactOccurred()
        heavyImpactGenerator.prepare()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker-like interactions
    func selection() {
        guard isHapticEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification haptic
    func success() {
        guard isHapticEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// Warning notification haptic
    func warning() {
        guard isHapticEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// Error notification haptic
    func error() {
        guard isHapticEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    // MARK: - Settings
    
    /// Check if haptic feedback is enabled in settings
    private var isHapticEnabled: Bool {
        AppSettings.load().hapticFeedbackEnabled
    }
}

// MARK: - Value Change Haptics

extension HapticManager {
    /// Trigger haptic for value changes with intensity based on delta
    func valueChanged(delta: Double) {
        guard isHapticEnabled else { return }
        
        let absDelta = abs(delta)
        
        if absDelta > 0.1 {
            mediumImpact()
        } else if absDelta > 0.01 {
            lightImpact()
        }
        // Skip very small changes to avoid constant vibration
    }
    
    /// Trigger haptic when reaching boundary values
    func boundaryReached() {
        guard isHapticEnabled else { return }
        heavyImpact()
    }
}
