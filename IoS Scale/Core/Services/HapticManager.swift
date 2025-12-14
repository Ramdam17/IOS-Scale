//
//  HapticManager.swift
//  IoS Scale
//
//  Manages haptic feedback throughout the app.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Singleton manager for haptic feedback
final class HapticManager {
    static let shared = HapticManager()
    
    #if canImport(UIKit) && !os(macOS)
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    #endif
    
    /// Check if haptic feedback is enabled in settings
    private var isHapticEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
    }
    
    private init() {
        prepareGenerators()
    }
    
    /// Prepare all generators for faster response
    func prepareGenerators() {
        #if canImport(UIKit) && !os(macOS)
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        #endif
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact for subtle feedback (value changes)
    func lightImpact() {
        guard isHapticEnabled else { return }
        #if canImport(UIKit) && !os(macOS)
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare()
        #endif
    }
    
    /// Medium impact for standard interactions
    func mediumImpact() {
        guard isHapticEnabled else { return }
        #if canImport(UIKit) && !os(macOS)
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
        #endif
    }
    
    /// Heavy impact for significant actions
    func heavyImpact() {
        guard isHapticEnabled else { return }
        #if canImport(UIKit) && !os(macOS)
        heavyImpactGenerator.impactOccurred()
        heavyImpactGenerator.prepare()
        #endif
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker-like interactions
    func selection() {
        guard isHapticEnabled else { return }
        #if canImport(UIKit) && !os(macOS)
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
        #endif
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification haptic
    func success() {
        guard isHapticEnabled else { return }
        #if canImport(UIKit) && !os(macOS)
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
        #endif
    }
    
    /// Warning notification haptic
    func warning() {
        guard isHapticEnabled else { return }
        #if canImport(UIKit) && !os(macOS)
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
        #endif
    }
    
    /// Error notification haptic
    func error() {
        guard isHapticEnabled else { return }
        #if canImport(UIKit) && !os(macOS)
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
        #endif
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
