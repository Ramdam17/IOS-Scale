//
//  AppRouter.swift
//  IoS Scale
//
//  Centralized navigation coordinator for the app.
//

import Combine
import SwiftUI

/// Navigation destinations for the app
enum AppDestination: Hashable {
    case home
    case basicIOS
    case advancedIOS
    case history
    case settings
    case modality(ModalityType)
}

/// Centralized navigation coordinator
@MainActor
final class AppRouter: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppRouter()
    
    // MARK: - Published Properties
    
    /// Current navigation path
    @Published var path = NavigationPath()
    
    /// Sheet presentation states
    @Published var presentedSheet: AppSheet?
    
    /// Full screen cover presentation
    @Published var presentedFullScreen: AppDestination?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Navigation Methods
    
    /// Navigate to a destination
    func navigate(to destination: AppDestination) {
        path.append(destination)
    }
    
    /// Go back one level
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// Go back to root
    func goToRoot() {
        path.removeLast(path.count)
    }
    
    /// Present a sheet
    func presentSheet(_ sheet: AppSheet) {
        presentedSheet = sheet
    }
    
    /// Dismiss current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
    
    /// Present full screen
    func presentFullScreen(_ destination: AppDestination) {
        presentedFullScreen = destination
    }
    
    /// Dismiss full screen
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
}

// MARK: - App Sheets

enum AppSheet: Identifiable {
    case history
    case settings
    case export
    case exitSession(onAction: (ExitSessionAction) -> Void)
    
    var id: String {
        switch self {
        case .history: return "history"
        case .settings: return "settings"
        case .export: return "export"
        case .exitSession: return "exitSession"
        }
    }
}

// MARK: - Navigation Extensions

extension View {
    /// Apply app-wide navigation destination handling
    func withAppNavigation() -> some View {
        self.navigationDestination(for: AppDestination.self) { destination in
            destinationView(for: destination)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .home:
            HomeView()
        case .basicIOS:
            BasicIOSView()
        case .advancedIOS:
            AdvancedIOSView()
        case .history:
            HistoryView()
        case .settings:
            SettingsPlaceholderView()
        case .modality(let modality):
            modalityView(for: modality)
        }
    }
    
    @ViewBuilder
    private func modalityView(for modality: ModalityType) -> some View {
        switch modality {
        case .basicIOS:
            BasicIOSView()
        case .advancedIOS:
            AdvancedIOSView()
        default:
            ComingSoonView(modality: modality)
        }
    }
}

// MARK: - Placeholder Views

struct SettingsPlaceholderView: View {
    var body: some View {
        Text("Settings - Coming Soon")
            .navigationTitle("Settings")
    }
}

struct ComingSoonView: View {
    let modality: ModalityType
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: modality.iconName)
                .font(.system(size: 60))
                .foregroundStyle(modality.tintColor.gradient)
            
            Text(modality.displayName)
                .font(Typography.title2)
            
            Text("Coming Soon")
                .font(Typography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gradientBackground()
        .navigationTitle(modality.displayName)
    }
}
