//
//  IOSScaleApp.swift
//  IoS Scale
//
//  Created by Remy Ramadour on 2025-11-23.
//

import SwiftUI
import SwiftData

@main
struct IOSScaleApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SessionModel.self,
            MeasurementModel.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Lock app when going to background (if enabled)
            Task { @MainActor in
                AuthenticationService.shared.lockApp()
            }
            
        case .active:
            // Sync when becoming active (if enabled)
            Task { @MainActor in
                if CloudSyncService.shared.iCloudSyncEnabled {
                    await CloudSyncService.shared.sync()
                }
            }
            
        case .inactive:
            break
            
        @unknown default:
            break
        }
    }
}

// MARK: - App Root View

/// Root view that handles authentication state
struct AppRootView: View {
    @State private var authService = AuthenticationService.shared
    @State private var syncService = CloudSyncService.shared
    
    var body: some View {
        Group {
            if authService.state == .locked {
                LockScreenView()
            } else {
                ContentView()
            }
        }
        .environment(authService)
        .environment(syncService)
        .task {
            await authService.checkAuthenticationOnLaunch()
        }
    }
}
