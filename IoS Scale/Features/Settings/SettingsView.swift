//
//  SettingsView.swift
//  IoS Scale
//
//  Settings and preferences screen.
//

import SwiftUI

/// Main settings view with appearance, behavior, data, and about sections
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authService: AuthenticationService
    
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @AppStorage("reset_behavior") private var resetBehavior = ResetBehavior.resetToDefault.rawValue
    @AppStorage("exportFormat") private var exportFormat = ExportFormat.csv.rawValue
    @AppStorage("decimalSeparator") private var decimalSeparator = DecimalSeparator.point.rawValue
    @AppStorage("includeMetadataInExport") private var includeMetadataInExport = true
    @AppStorage("biometricAuthEnabled") private var biometricAuthEnabled = false
    @AppStorage("lockOnBackground") private var lockOnBackground = false
    
    @State private var showClearDataConfirmation = false
    @State private var showEmptyTrashConfirmation = false
    @State private var showTrashView = false
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                appearanceSection
                
                // Behavior Section
                behaviorSection
                
                // Export Section
                exportSection
                
                // Data Section
                dataSection
                
                // Security Section
                securitySection
                
                // About Section
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .gradientBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTrashView) {
                TrashView()
            }
            .alert("Clear All Data?", isPresented: $showClearDataConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all sessions and measurements. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            // Theme picker
            Picker("Theme", selection: $themeManager.themeMode) {
                ForEach(ThemeMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
            
        } header: {
            Label("Appearance", systemImage: "paintbrush")
        } footer: {
            Text("Choose how the app looks. System follows your device settings.")
        }
    }
    
    // MARK: - Behavior Section
    
    private var behaviorSection: some View {
        Section {
            // Haptic feedback toggle
            Toggle(isOn: $hapticFeedbackEnabled) {
                Label {
                    Text("Haptic Feedback")
                } icon: {
                    Image(systemName: "hand.tap")
                }
            }
            .onChange(of: hapticFeedbackEnabled) { _, newValue in
                if newValue {
                    HapticManager.shared.lightImpact()
                }
            }
            
            // Reset behavior picker
            Picker(selection: $resetBehavior) {
                ForEach(ResetBehavior.allCases) { behavior in
                    Text(behavior.displayName).tag(behavior.rawValue)
                }
            } label: {
                Label {
                    Text("Reset Behavior")
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            .pickerStyle(.menu)
            
        } header: {
            Label("Behavior", systemImage: "gearshape")
        } footer: {
            Text("Haptic feedback provides tactile responses. Reset behavior controls circle positions between measurements.")
        }
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        Section {
            // Export format picker
            Picker("Default Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.displayName).tag(format.rawValue)
                }
            }
            .pickerStyle(.menu)
            
            // Decimal separator
            Picker("Decimal Separator", selection: $decimalSeparator) {
                ForEach(DecimalSeparator.allCases) { separator in
                    Text(separator.displayName).tag(separator.rawValue)
                }
            }
            .pickerStyle(.menu)
            
            // Include metadata toggle
            Toggle(isOn: $includeMetadataInExport) {
                Label {
                    Text("Include Metadata")
                } icon: {
                    Image(systemName: "info.circle")
                }
            }
            
        } header: {
            Label("Export", systemImage: "square.and.arrow.up")
        } footer: {
            Text("These settings apply when exporting session data.")
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            // iCloud sync toggle
            Toggle(isOn: $iCloudSyncEnabled) {
                Label {
                    Text("iCloud Sync")
                } icon: {
                    Image(systemName: "icloud")
                }
            }
            .disabled(true) // Coming soon
            
            // Trash
            Button {
                showTrashView = true
            } label: {
                Label {
                    Text("Trash")
                } icon: {
                    Image(systemName: "trash")
                }
            }
            
            // Clear all data
            Button(role: .destructive) {
                showClearDataConfirmation = true
            } label: {
                Label {
                    Text("Clear All Data")
                } icon: {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
            
        } header: {
            Label("Data", systemImage: "externaldrive")
        } footer: {
            Text("iCloud sync coming soon. Clear All Data will permanently delete all sessions.")
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section {
            // Biometric auth toggle
            if authService.isBiometricAvailable {
                Toggle(isOn: $biometricAuthEnabled) {
                    Label {
                        Text("\(authService.biometricName) Lock")
                    } icon: {
                        Image(systemName: authService.biometricIcon)
                    }
                }
                .onChange(of: biometricAuthEnabled) { _, newValue in
                    if newValue {
                        // Verify biometric works before enabling
                        Task {
                            let success = await authService.authenticateWithBiometrics()
                            if !success {
                                biometricAuthEnabled = false
                            } else {
                                HapticManager.shared.success()
                            }
                        }
                    }
                }
                
                // Lock on background toggle (only if biometric enabled)
                if biometricAuthEnabled {
                    Toggle(isOn: $lockOnBackground) {
                        Label {
                            Text("Lock When Leaving App")
                        } icon: {
                            Image(systemName: "lock.rotation")
                        }
                    }
                }
            } else {
                // No biometric available message
                HStack {
                    Label {
                        Text("Biometric Authentication")
                    } icon: {
                        Image(systemName: "lock")
                    }
                    Spacer()
                    Text("Not Available")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Sign in with Apple section
            if let userName = authService.currentUserName {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Signed in as")
                            Text(userName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                    }
                    Spacer()
                    Button("Sign Out") {
                        authService.signOut()
                    }
                    .foregroundStyle(.red)
                }
            } else {
                Button {
                    authService.signInWithApple()
                } label: {
                    Label {
                        Text("Sign in with Apple")
                    } icon: {
                        Image(systemName: "apple.logo")
                    }
                }
            }
            
        } header: {
            Label("Security", systemImage: "lock.shield")
        } footer: {
            if authService.isBiometricAvailable {
                Text("Require \(authService.biometricName) to access the app. Sign in with Apple to sync your data across devices.")
            } else {
                Text("Sign in with Apple to sync your data across devices.")
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            // App version
            HStack {
                Label {
                    Text("Version")
                } icon: {
                    Image(systemName: "info.circle")
                }
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            
            // Scientific references
            Link(destination: URL(string: "https://doi.org/10.1037/0022-3514.63.4.596")!) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scientific Reference")
                        Text("Aron et al. (1992)")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "book")
                }
            }
            
            // GitHub
            Link(destination: URL(string: "https://github.com/Ramdam17/IOS-Scale")!) {
                Label {
                    Text("Source Code")
                } icon: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
            }
            
        } header: {
            Label("About", systemImage: "questionmark.circle")
        } footer: {
            Text("IOS Scale is based on the Inclusion of Other in the Self Scale by Aron, Aron & Smollan (1992).")
        }
    }
    
    // MARK: - Helpers
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func clearAllData() {
        // This would need access to modelContext - for now just show feedback
        HapticManager.shared.warning()
        // TODO: Implement actual data clearing with SwiftData
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
