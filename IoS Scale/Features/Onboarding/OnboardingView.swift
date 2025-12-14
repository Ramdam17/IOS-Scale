//
//  OnboardingView.swift
//  IoS Scale
//
//  Onboarding flow for first-time users with app presentation and Sign in with Apple.
//

import SwiftUI
import AuthenticationServices

/// Main onboarding view with swipable pages
struct OnboardingView: View {
    @Environment(AuthenticationService.self) private var authService
    @State private var currentPage = 0
    @State private var showSignInError = false
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    HowItWorksPage()
                        .tag(1)
                    
                    ExportPage()
                        .tag(2)
                    
                    CustomizePage()
                        .tag(3)
                    
                    GetStartedPage(showError: $showSignInError)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom controls
                bottomControls
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
            }
        }
        .alert("Sign In Failed", isPresented: $showSignInError) {
            Button("Try Again", role: .cancel) {}
        } message: {
            Text(authService.errorMessage ?? "Please try again.")
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.3),
                Color.blue.opacity(0.2),
                Color.pink.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: Spacing.lg) {
            // Page indicators
            HStack(spacing: Spacing.sm) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            
            // Navigation buttons
            if currentPage < totalPages - 1 {
                HStack {
                    // Skip button
                    Button("Skip") {
                        withAnimation {
                            currentPage = totalPages - 1
                        }
                    }
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Next button
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
            }
        }
    }
}

// MARK: - Welcome Page

private struct WelcomePage: View {
    @State private var animateCircles = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer(minLength: Spacing.lg)
                
                // Animated circles
                ZStack {
                    // Self circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .offset(x: animateCircles ? -30 : -60)
                    
                    // Other circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .offset(x: animateCircles ? 30 : 60)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        animateCircles = true
                    }
                }
                
                VStack(spacing: Spacing.md) {
                    Text("IOS Scale")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Measure intersubjective experiences")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer(minLength: Spacing.lg)
            }
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            .padding(.horizontal, Spacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - How It Works Page

private struct HowItWorksPage: View {
    @State private var overlapValue: CGFloat = 0.3
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer(minLength: Spacing.lg)
                
                // Mini preview
                OnboardingCirclesPreview(overlap: $overlapValue)
                    .frame(height: 200)
                
                VStack(spacing: Spacing.md) {
                    Text("How It Works")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Drag the circles to express how close you feel to another person. The overlap represents your sense of connection.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Interactive slider
                VStack(spacing: Spacing.sm) {
                    Text("Try it!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Slider(value: $overlapValue, in: 0...1)
                        .tint(.accentColor)
                        .frame(maxWidth: 400)
                }
                
                Spacer(minLength: Spacing.lg)
            }
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            .padding(.horizontal, Spacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Export Page

private struct ExportPage: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer(minLength: Spacing.lg)
                
                // Export icons
                HStack(spacing: Spacing.xl) {
                    ExportIconView(icon: "doc.text", label: "CSV")
                    ExportIconView(icon: "doc.plaintext", label: "TSV")
                    ExportIconView(icon: "curlybraces", label: "JSON")
                }
                
                VStack(spacing: Spacing.md) {
                    Text("Save & Export")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your data belongs to you. Export your measurements in multiple formats for research or personal records.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Features list
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    FeatureRow(icon: "square.and.arrow.up", text: "Share via AirDrop, Mail, or Messages")
                    FeatureRow(icon: "icloud", text: "Sync across all your devices")
                    FeatureRow(icon: "lock.shield", text: "Your data stays private")
                }
                .padding(.top, Spacing.md)
                
                Spacer(minLength: Spacing.lg)
            }
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            .padding(.horizontal, Spacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Customize Page

private struct CustomizePage: View {
    @State private var selectedTheme = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer(minLength: Spacing.lg)
                
                // Theme preview
                HStack(spacing: Spacing.lg) {
                    ThemePreviewCard(isDark: false, isSelected: selectedTheme == 0)
                        .onTapGesture { selectedTheme = 0 }
                    
                    ThemePreviewCard(isDark: true, isSelected: selectedTheme == 1)
                        .onTapGesture { selectedTheme = 1 }
                }
                .frame(height: 160)
                
                VStack(spacing: Spacing.md) {
                    Text("Make It Yours")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Choose your theme, customize measurement behavior, and set up security preferences in Settings.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Settings preview
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    FeatureRow(icon: "paintbrush", text: "Light, Dark, or System theme")
                    FeatureRow(icon: "arrow.counterclockwise", text: "Reset behavior between measurements")
                    FeatureRow(icon: "square.and.arrow.up", text: "Export data in CSV, TSV, or JSON")
                }
                .padding(.top, Spacing.md)
                
                Spacer(minLength: Spacing.lg)
            }
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            .padding(.horizontal, Spacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Get Started Page

private struct GetStartedPage: View {
    @Environment(AuthenticationService.self) private var authService
    @Binding var showError: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer(minLength: Spacing.lg)
                
                // Apple logo
                Image(systemName: "apple.logo")
                    .font(.system(size: 60))
                    .foregroundStyle(.primary)
                
                VStack(spacing: Spacing.md) {
                    Text("Get Started")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Sign in with Apple to sync your data across devices and keep your measurements secure.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Sign in with Apple button
                SignInWithAppleButtonRepresentable(
                    type: .signIn,
                    style: .black
                ) { result in
                    handleSignInResult(result)
                }
                .frame(height: 50)
                .frame(maxWidth: 320)
                .cornerRadius(25)
                .padding(.top, Spacing.lg)
                
                // Privacy note
                Text("We only use your Apple ID to sync data. Your measurements are never shared.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
                
                Spacer(minLength: Spacing.lg)
            }
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            .padding(.horizontal, Spacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task { @MainActor in
                    authService.handleAppleSignIn(credential: credential)
                }
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
            showError = true
        }
    }
}

// MARK: - Helper Views

private struct OnboardingCirclesPreview: View {
    @Binding var overlap: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let circleSize: CGFloat = 100
            let centerY = geometry.size.height / 2
            let centerX = geometry.size.width / 2
            let maxDistance = circleSize * 1.5
            let currentDistance = maxDistance * (1 - overlap)
            
            ZStack {
                // Self circle (left)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
                    .position(x: centerX - currentDistance / 2, y: centerY)
                
                // Other circle (right)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
                    .position(x: centerX + currentDistance / 2, y: centerY)
                
                // Labels
                Text("Self")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .position(x: centerX - currentDistance / 2, y: centerY + circleSize / 2 + 20)
                
                Text("Other")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .position(x: centerX + currentDistance / 2, y: centerY + circleSize / 2 + 20)
            }
        }
    }
}

private struct ExportIconView: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ThemePreviewCard: View {
    let isDark: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark ? Color.black : Color.white)
                .overlay(
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isDark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(height: 20)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 20, height: 20)
                            Circle()
                                .fill(.purple)
                                .frame(width: 20, height: 20)
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
            
            Text(isDark ? "Dark" : "Light")
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}

// MARK: - Sign In With Apple Button

/// UIViewRepresentable for ASAuthorizationAppleIDButton with completion handler
private struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate {
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onCompletion = onCompletion
        }
        
        @objc func buttonTapped() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email, .fullName]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AuthenticationService.shared)
}
