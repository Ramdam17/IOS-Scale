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
    @Environment(AuthenticationService.self) private var authService
    
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @AppStorage("reset_behavior") private var resetBehavior = ResetBehavior.resetToDefault.rawValue
    @AppStorage("exportFormat") private var exportFormat = ExportFormat.csv.rawValue
    @AppStorage("decimalSeparator") private var decimalSeparator = DecimalSeparator.point.rawValue
    @AppStorage("includeMetadataInExport") private var includeMetadataInExport = true
    
    @State private var showClearDataConfirmation = false
    @State private var showEmptyTrashConfirmation = false
    @State private var showTrashView = false
    @State private var showSignOutConfirmation = false
    
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
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.resetOnboarding()
                }
            } message: {
                Text("You will be signed out and returned to the welcome screen. Your local data will remain on this device.")
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
            .onChange(of: iCloudSyncEnabled) { _, newValue in
                if newValue {
                    Task {
                        await CloudSyncService.shared.refreshStatus()
                    }
                }
            }
            
            // Sync status (if enabled)
            if iCloudSyncEnabled {
                HStack {
                    Label {
                        Text("Status")
                    } icon: {
                        Image(systemName: CloudSyncService.shared.status.icon)
                            .foregroundStyle(CloudSyncService.shared.status.color)
                    }
                    Spacer()
                    Text(CloudSyncService.shared.status.displayText)
                        .foregroundStyle(.secondary)
                }
                
                // Manual refresh button
                Button {
                    Task {
                        await CloudSyncService.shared.refreshStatus()
                    }
                } label: {
                    Label {
                        Text("Refresh Status")
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(CloudSyncService.shared.isSyncing)
            }
            
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
            Text("iCloud sync keeps your sessions in sync across all your devices. Clear All Data will permanently delete all sessions.")
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section {
            // Sign in with Apple section / Sign Out
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
                        showSignOutConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            } else if authService.currentUserID != nil {
                // User is signed in but name not available
                HStack {
                    Label {
                        Text("Signed in with Apple")
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                    }
                    Spacer()
                    Button("Sign Out") {
                        showSignOutConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            } else {
                // User is not signed in with Apple - show sign out option anyway
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label {
                        Text("Sign Out")
                    } icon: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            
        } header: {
            Label("Account", systemImage: "person.circle")
        } footer: {
            Text("Sign out to return to the welcome screen.")
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
