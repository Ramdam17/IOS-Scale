//
//  AuthenticationService.swift
//  IoS Scale
//
//  Authentication service with Sign in with Apple and biometric authentication.
//

import Foundation
import LocalAuthentication
import AuthenticationServices
import SwiftUI

/// Authentication state for the app
enum AuthenticationState: Equatable {
    case unknown
    case onboarding
    case authenticated
    case unauthenticated
    case locked
}

/// Biometric type available on device
enum BiometricType {
    case none
    case faceID
    case touchID
    case opticID
}

/// Authentication service managing Sign in with Apple and biometric auth
@MainActor @Observable
final class AuthenticationService: NSObject {
    
    // MARK: - Singleton
    
    static let shared = AuthenticationService()
    
    // MARK: - Observable Properties
    
    private(set) var state: AuthenticationState = .unknown
    private(set) var currentUserID: String?
    private(set) var currentUserEmail: String?
    private(set) var currentUserName: String?
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?
    
    // MARK: - Settings
    
    @ObservationIgnored
    @AppStorage("biometricAuthEnabled") var biometricAuthEnabled = false
    @ObservationIgnored
    @AppStorage("lockOnBackground") var lockOnBackground = false
    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservationIgnored
    @AppStorage("appleUserID") private var storedAppleUserID: String?
    @ObservationIgnored
    @AppStorage("appleUserEmail") private var storedAppleUserEmail: String?
    @ObservationIgnored
    @AppStorage("appleUserName") private var storedAppleUserName: String?
    
    // MARK: - Private Properties
    
    @ObservationIgnored
    private let context = LAContext()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        loadStoredCredentials()
    }
    
    // MARK: - Biometric Authentication
    
    /// Returns the type of biometric authentication available
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    /// Human-readable name for the biometric type
    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric"
        }
    }
    
    /// SF Symbol name for the biometric type
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock"
        }
    }
    
    /// Check if biometric authentication is available
    var isBiometricAvailable: Bool {
        biometricType != .none
    }
    
    /// Authenticate using biometrics (FaceID/TouchID)
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Biometric authentication not available"
            return false
        }
        
        isAuthenticating = true
        errorMessage = nil
        
        do {
            let reason = "Unlock IOS Scale to access your data"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            isAuthenticating = false
            
            if success {
                state = .authenticated
                return true
            } else {
                return false
            }
        } catch let authError as LAError {
            isAuthenticating = false
            handleBiometricError(authError)
            return false
        } catch {
            isAuthenticating = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Authenticate using device passcode as fallback
    func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if device passcode is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Passcode not available"
            return false
        }
        
        isAuthenticating = true
        errorMessage = nil
        
        do {
            let reason = "Enter your passcode to unlock IOS Scale"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            isAuthenticating = false
            
            if success {
                state = .authenticated
                return true
            } else {
                return false
            }
        } catch {
            isAuthenticating = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Handle biometric authentication errors
    private func handleBiometricError(_ error: LAError) {
        switch error.code {
        case .authenticationFailed:
            errorMessage = "Authentication failed. Please try again."
        case .userCancel:
            errorMessage = nil // User cancelled, no error message needed
        case .userFallback:
            errorMessage = nil // User wants passcode
        case .biometryNotAvailable:
            errorMessage = "\(biometricName) is not available on this device."
        case .biometryNotEnrolled:
            errorMessage = "\(biometricName) is not set up. Please enable it in Settings."
        case .biometryLockout:
            errorMessage = "\(biometricName) is locked. Please use your passcode."
        case .passcodeNotSet:
            errorMessage = "Please set up a passcode in device Settings."
        default:
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign in with Apple
    
    /// Start Sign in with Apple flow
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
        
        isAuthenticating = true
        errorMessage = nil
    }
    
    /// Check if user is already signed in with Apple
    func checkAppleSignInStatus() async {
        guard let userID = storedAppleUserID else {
            state = .unauthenticated
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        
        do {
            let credentialState = try await provider.credentialState(forUserID: userID)
            
            switch credentialState {
            case .authorized:
                // User is still authorized
                currentUserID = userID
                currentUserEmail = storedAppleUserEmail
                currentUserName = storedAppleUserName
                state = .authenticated
                
            case .revoked, .notFound:
                // Credentials are invalid, sign out
                signOut()
                
            case .transferred:
                // Account transferred to different team
                signOut()
                
            @unknown default:
                signOut()
            }
        } catch {
            errorMessage = error.localizedDescription
            state = .unauthenticated
        }
    }
    
    /// Sign out the current user
    func signOut() {
        storedAppleUserID = nil
        storedAppleUserEmail = nil
        storedAppleUserName = nil
        currentUserID = nil
        currentUserEmail = nil
        currentUserName = nil
        state = .unauthenticated
    }
    
    /// Load stored credentials on init
    private func loadStoredCredentials() {
        if let userID = storedAppleUserID {
            currentUserID = userID
            currentUserEmail = storedAppleUserEmail
            currentUserName = storedAppleUserName
        }
    }
    
    // MARK: - App Lifecycle
    
    /// Lock the app (call when going to background if enabled)
    func lockApp() {
        // Only lock if already authenticated (not during onboarding)
        if biometricAuthEnabled && lockOnBackground && state == .authenticated {
            state = .locked
        }
    }
    
    /// Unlock the app using appropriate method
    func unlockApp() async -> Bool {
        if biometricAuthEnabled {
            return await authenticateWithBiometrics()
        }
        return true
    }
    
    /// Check if authentication is required on launch
    func checkAuthenticationOnLaunch() async {
        // First launch - show onboarding
        if !hasCompletedOnboarding {
            state = .onboarding
            return
        }
        
        // If biometric auth is enabled, require authentication
        if biometricAuthEnabled {
            state = .locked
        } else if storedAppleUserID != nil {
            // Check Apple ID status if user was signed in
            await checkAppleSignInStatus()
        } else {
            // User completed onboarding but somehow signed out - show onboarding again
            state = .onboarding
        }
    }
    
    /// Handle Sign in with Apple credential (called from onboarding)
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) {
        // Store user information
        storedAppleUserID = credential.user
        currentUserID = credential.user
        
        // Email and name are only provided on first sign-in
        if let email = credential.email {
            storedAppleUserEmail = email
            currentUserEmail = email
        }
        
        if let fullName = credential.fullName {
            let name = PersonNameComponentsFormatter().string(from: fullName)
            if !name.isEmpty {
                storedAppleUserName = name
                currentUserName = name
            }
        }
        
        // Mark onboarding as complete
        hasCompletedOnboarding = true
        state = .authenticated
        HapticManager.shared.success()
    }
    
    /// Reset onboarding (for testing or sign out)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        signOut()
        state = .onboarding
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            isAuthenticating = false
            
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Store user information
                storedAppleUserID = credential.user
                currentUserID = credential.user
                
                // Email and name are only provided on first sign-in
                if let email = credential.email {
                    storedAppleUserEmail = email
                    currentUserEmail = email
                }
                
                if let fullName = credential.fullName {
                    let name = PersonNameComponentsFormatter().string(from: fullName)
                    if !name.isEmpty {
                        storedAppleUserName = name
                        currentUserName = name
                    }
                }
                
                state = .authenticated
                HapticManager.shared.success()
            }
        }
    }
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            isAuthenticating = false
            
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // User cancelled, no error message
                    errorMessage = nil
                case .failed:
                    errorMessage = "Sign in with Apple failed. Please try again."
                case .invalidResponse:
                    errorMessage = "Invalid response from Apple. Please try again."
                case .notHandled:
                    errorMessage = "Sign in with Apple could not be handled."
                case .unknown:
                    errorMessage = "An unknown error occurred."
                case .notInteractive:
                    errorMessage = "Sign in requires user interaction."
                @unknown default:
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Sign in with Apple Button

/// SwiftUI wrapper for Sign in with Apple button
struct SignInWithAppleButton: View {
    @Environment(AuthenticationService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        SignInWithAppleButtonViewRepresentable(
            type: .signIn,
            style: colorScheme == .dark ? .white : .black
        ) {
            authService.signInWithApple()
        }
        .frame(height: 50)
        .cornerRadius(12)
    }
}

/// UIViewRepresentable for ASAuthorizationAppleIDButton
struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}
