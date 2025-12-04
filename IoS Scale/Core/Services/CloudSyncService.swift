//
//  CloudSyncService.swift
//  IoS Scale
//
//  iCloud sync service using CloudKit for cross-device synchronization.
//

import Foundation
import CloudKit
import SwiftUI
import Combine

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

/// CloudKit sync service for sessions and measurements
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
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled = false
    @ObservationIgnored
    @AppStorage("lastSyncTimestamp") private var lastSyncTimestamp: Double = 0
    
    // MARK: - CloudKit Properties
    
    private let containerIdentifier = "iCloud.com.iosscale.app"
    
    @ObservationIgnored
    private var _container: CKContainer?
    private var container: CKContainer {
        if _container == nil {
            _container = CKContainer(identifier: containerIdentifier)
        }
        return _container!
    }
    
    private var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }
    
    // MARK: - Record Types
    
    private enum RecordType {
        static let session = "Session"
        static let measurement = "Measurement"
    }
    
    // MARK: - Record Keys
    
    private enum SessionKeys {
        static let id = "id"
        static let modality = "modality"
        static let createdAt = "createdAt"
        static let isDeleted = "isDeleted"
        static let deletedAt = "deletedAt"
    }
    
    private enum MeasurementKeys {
        static let id = "id"
        static let sessionID = "sessionID"
        static let timestamp = "timestamp"
        static let primaryValue = "primaryValue"
        static let secondaryValues = "secondaryValues"
    }
    
    // MARK: - Initialization
    
    private init() {
        loadLastSyncDate()
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// Check if iCloud is available
    func checkiCloudStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
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
    
    /// Perform full sync (upload + download)
    func sync() async {
        guard iCloudSyncEnabled else {
            status = .disabled
            return
        }
        
        guard await checkiCloudStatus() else {
            return
        }
        
        isSyncing = true
        status = .syncing
        
        do {
            // Download changes from iCloud
            try await downloadChanges()
            
            // Upload local changes
            try await uploadChanges()
            
            // Update sync timestamp
            lastSyncDate = Date()
            lastSyncTimestamp = Date().timeIntervalSince1970
            
            status = .success
            
            // Reset to idle after a moment
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if status == .success {
                status = .idle
            }
        } catch {
            status = .error(error.localizedDescription)
        }
        
        isSyncing = false
    }
    
    /// Upload a single session to iCloud
    func uploadSession(_ session: SessionModel) async throws {
        guard iCloudSyncEnabled else { return }
        guard await checkiCloudStatus() else { return }
        
        let record = createSessionRecord(from: session)
        try await privateDatabase.save(record)
        
        // Upload measurements
        for measurement in session.measurements {
            let measurementRecord = createMeasurementRecord(from: measurement, sessionID: session.id)
            try await privateDatabase.save(measurementRecord)
        }
    }
    
    /// Delete a session from iCloud
    func deleteSession(_ sessionID: UUID) async throws {
        guard iCloudSyncEnabled else { return }
        guard await checkiCloudStatus() else { return }
        
        let recordID = CKRecord.ID(recordName: sessionID.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    // MARK: - Private Methods
    
    /// Download changes from iCloud
    private func downloadChanges() async throws {
        // Query all sessions
        let query = CKQuery(recordType: RecordType.session, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let results = try await privateDatabase.records(matching: query)
        
        for result in results.matchResults {
            switch result.1 {
            case .success(let record):
                // Process session record
                await processSessionRecord(record)
            case .failure(let error):
                print("Error fetching record: \(error)")
            }
        }
    }
    
    /// Upload local changes to iCloud
    private func uploadChanges() async throws {
        // This would query SwiftData for sessions modified since last sync
        // and upload them to CloudKit
        // Implementation depends on SwiftData integration
    }
    
    /// Process a downloaded session record
    private func processSessionRecord(_ record: CKRecord) async {
        // Convert CKRecord to SessionModel and save locally
        // Implementation depends on SwiftData integration
    }
    
    /// Create a CloudKit record from a session
    private func createSessionRecord(from session: SessionModel) -> CKRecord {
        let recordID = CKRecord.ID(recordName: session.id.uuidString)
        let record = CKRecord(recordType: RecordType.session, recordID: recordID)
        
        record[SessionKeys.id] = session.id.uuidString
        record[SessionKeys.modality] = session.modality.rawValue
        record[SessionKeys.createdAt] = session.createdAt
        record[SessionKeys.isDeleted] = session.isDeleted
        record[SessionKeys.deletedAt] = session.deletedAt
        
        return record
    }
    
    /// Create a CloudKit record from a measurement
    private func createMeasurementRecord(from measurement: MeasurementModel, sessionID: UUID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: measurement.id.uuidString)
        let record = CKRecord(recordType: RecordType.measurement, recordID: recordID)
        
        record[MeasurementKeys.id] = measurement.id.uuidString
        record[MeasurementKeys.sessionID] = sessionID.uuidString
        record[MeasurementKeys.timestamp] = measurement.timestamp
        record[MeasurementKeys.primaryValue] = measurement.primaryValue
        
        if let secondaryValues = measurement.secondaryValues {
            if let data = try? JSONEncoder().encode(secondaryValues) {
                record[MeasurementKeys.secondaryValues] = data
            }
        }
        
        return record
    }
    
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
                await self?.checkiCloudStatus()
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

/// A button to trigger manual sync
struct SyncButton: View {
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        Button {
            Task {
                await syncService.sync()
            }
        } label: {
            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
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
