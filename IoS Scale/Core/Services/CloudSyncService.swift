//
//  CloudSyncService.swift
//  IoS Scale
//
//  iCloud sync status service.
//  Note: SwiftData handles all sync automatically with cloudKitDatabase: .automatic
//  This service only provides status display and iCloud availability checking.
//

import Foundation
import CloudKit
import SwiftUI

/// Sync status for UI display
enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error(String)
    case offline
    case disabled
    
    var displayText: String {
        switch self {
        case .idle:
            return "Up to date"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Synced"
        case .error(let message):
            return message
        case .offline:
            return "Offline"
        case .disabled:
            return "Sync disabled"
        }
    }
    
    var icon: String {
        switch self {
        case .idle, .success:
            return "checkmark.icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .error:
            return "exclamationmark.icloud"
        case .offline:
            return "icloud.slash"
        case .disabled:
            return "xmark.icloud"
        }
    }
    
    var color: Color {
        switch self {
        case .idle, .success:
            return .green
        case .syncing:
            return .blue
        case .error:
            return .red
        case .offline:
            return .orange
        case .disabled:
            return .secondary
        }
    }
}

/// CloudKit sync status service
/// SwiftData handles actual sync automatically - this service only provides status display
@MainActor @Observable
final class CloudSyncService {
    
    // MARK: - Singleton
    
    static let shared = CloudSyncService()
    
    // MARK: - Observable Properties
    
    private(set) var status: SyncStatus = .idle
    private(set) var lastSyncDate: Date?
    private(set) var isSyncing = false
    
    // MARK: - Settings
    
    @ObservationIgnored
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled = true  // Default to enabled
    @ObservationIgnored
    @AppStorage("lastSyncTimestamp") private var lastSyncTimestamp: Double = 0
    
    // MARK: - CloudKit Properties
    
    private let containerIdentifier = "iCloud.com.remyramadour.iosscale"
    
    @ObservationIgnored
    private var _container: CKContainer?
    private var container: CKContainer {
        if _container == nil {
            _container = CKContainer(identifier: containerIdentifier)
        }
        return _container!
    }
    
    // MARK: - Initialization
    
    private init() {
        loadLastSyncDate()
        setupNotifications()
        
        // Check initial status
        Task {
            await refreshStatus()
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if iCloud is available and update status
    @discardableResult
    func checkiCloudStatus() async -> Bool {
        // Don't check if sync is disabled
        guard iCloudSyncEnabled else {
            self.status = .disabled
            return false
        }
        
        do {
            let accountStatus = try await container.accountStatus()
            switch accountStatus {
            case .available:
                self.status = .idle
                return true
            case .noAccount:
                self.status = .error("No iCloud account")
                return false
            case .restricted:
                self.status = .error("iCloud restricted")
                return false
            case .couldNotDetermine:
                self.status = .error("Could not determine iCloud status")
                return false
            case .temporarilyUnavailable:
                self.status = .offline
                return false
            @unknown default:
                self.status = .error("Unknown iCloud status")
                return false
            }
        } catch {
            self.status = .error(error.localizedDescription)
            return false
        }
    }
    
    /// Refresh sync status (for pull-to-refresh or manual check)
    func refreshStatus() async {
        guard iCloudSyncEnabled else {
            status = .disabled
            return
        }
        
        isSyncing = true
        status = .syncing
        
        let isAvailable = await checkiCloudStatus()
        
        if isAvailable {
            // SwiftData handles sync automatically
            // We just update the timestamp for display purposes
            lastSyncDate = Date()
            lastSyncTimestamp = Date().timeIntervalSince1970
            status = .success
            
            // Reset to idle after a moment
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if status == .success {
                status = .idle
            }
        }
        
        isSyncing = false
    }
    
    /// Toggle iCloud sync on/off
    func toggleSync(_ enabled: Bool) async {
        iCloudSyncEnabled = enabled
        
        if enabled {
            await refreshStatus()
        } else {
            status = .disabled
        }
    }
    
    // MARK: - Private Methods
    
    /// Load last sync date from storage
    private func loadLastSyncDate() {
        if lastSyncTimestamp > 0 {
            lastSyncDate = Date(timeIntervalSince1970: lastSyncTimestamp)
        }
    }
    
    /// Setup notifications for account changes
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.iCloudSyncEnabled else { return }
                await self.checkiCloudStatus()
            }
        }
    }
}

// MARK: - Sync Status View

/// A view displaying the current sync status
struct SyncStatusView: View {
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: syncService.status.icon)
                .foregroundStyle(syncService.status.color)
                .symbolEffect(.pulse, isActive: syncService.isSyncing)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(syncService.status.displayText)
                    .font(.caption)
                
                if let lastSync = syncService.lastSyncDate {
                    Text("Last: \(lastSync, style: .relative)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Sync Button

/// A button to trigger manual status refresh
struct SyncButton: View {
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        Button {
            Task {
                await syncService.refreshStatus()
            }
        } label: {
            Label("Refresh Status", systemImage: "arrow.triangle.2.circlepath")
        }
        .disabled(syncService.isSyncing || !syncService.iCloudSyncEnabled)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SyncStatusView()
        SyncButton()
    }
    .padding()
    .environment(CloudSyncService.shared)
}
