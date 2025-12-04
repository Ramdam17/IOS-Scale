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
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var syncService = CloudSyncService.shared
    
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
            Group {
                if authService.state == .locked {
                    LockScreenView()
                        .environmentObject(authService)
                } else {
                    ContentView()
                }
            }
            .environmentObject(themeManager)
            .environmentObject(authService)
            .environmentObject(syncService)
            .preferredColorScheme(themeManager.colorScheme)
            .task {
                await authService.checkAuthenticationOnLaunch()
            }
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
            authService.lockApp()
            
        case .active:
            // Sync when becoming active (if enabled)
            if syncService.iCloudSyncEnabled {
                Task {
                    await syncService.sync()
                }
            }
            
        case .inactive:
            break
            
        @unknown default:
            break
        }
    }
}
