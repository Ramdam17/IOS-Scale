//
//  LockScreenView.swift
//  IoS Scale
//
//  Lock screen displayed when biometric authentication is required.
//

import SwiftUI

/// Lock screen view for biometric authentication
struct LockScreenView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingPasscodeOption = false
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.xxl) {
                Spacer()
                
                // App icon and title
                appHeader
                
                Spacer()
                
                // Unlock button
                unlockSection
                
                // Error message
                if let error = authService.errorMessage {
                    errorView(error)
                }
                
                Spacer()
                
                // Passcode fallback
                if authService.isBiometricAvailable {
                    passcodeButton
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .onAppear {
            authenticateOnAppear()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.purple.opacity(0.3), Color.blue.opacity(0.2), Color.black]
                : [Color.purple.opacity(0.2), Color.blue.opacity(0.1), Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - App Header
    
    private var appHeader: some View {
        VStack(spacing: Spacing.lg) {
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "circle.circle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(.white)
            }
            
            // App name
            Text("IOS Scale")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Locked")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Unlock Section
    
    private var unlockSection: some View {
        VStack(spacing: Spacing.lg) {
            // Biometric icon
            Button {
                Task {
                    await authService.authenticateWithBiometrics()
                }
            } label: {
                VStack(spacing: Spacing.md) {
                    Image(systemName: authService.biometricIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Tap to unlock with \(authService.biometricName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(authService.isAuthenticating)
            
            if authService.isAuthenticating {
                ProgressView()
                    .tint(.blue)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - Passcode Button
    
    private var passcodeButton: some View {
        Button {
            Task {
                await authService.authenticateWithPasscode()
            }
        } label: {
            Text("Use Passcode")
                .font(.footnote)
                .foregroundStyle(.blue)
        }
        .disabled(authService.isAuthenticating)
    }
    
    // MARK: - Actions
    
    private func authenticateOnAppear() {
        // Auto-trigger biometric auth when view appears
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            await authService.authenticateWithBiometrics()
        }
    }
}

// MARK: - Preview

#Preview {
    LockScreenView()
        .environmentObject(AuthenticationService.shared)
}
