//
//  BasicIOSView.swift
//  IoS Scale
//
//  Main view for Basic IOS measurement mode.
//

import SwiftUI
import SwiftData

/// Basic IOS measurement view with two circles and overlap slider
struct BasicIOSView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = BasicIOSViewModel()
    
    // Placeholder scales (not adjustable in Basic mode)
    @State private var selfScale: Double = 1.0
    @State private var otherScale: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isPad = horizontalSizeClass == .regular
            let circlesHeight = isLandscape ? geometry.size.height * 0.50 : geometry.size.height * 0.50
            
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isLandscape ? Spacing.xs : 0) {
                        // iPad top spacing for vertical centering
                        if isPad {
                            Spacer(minLength: geometry.size.height * 0.05)
                        }
                        
                        // Circles area
                        InteractiveCirclesView(
                            overlapValue: $viewModel.overlapValue,
                            selfScale: $selfScale,
                            otherScale: $otherScale,
                            scalingEnabled: false,
                            onDraggingChanged: { isDragging in
                                viewModel.isDragging = isDragging
                            }
                        )
                        .frame(height: circlesHeight)
                        
                        // Bottom controls
                        VStack(spacing: isLandscape ? Spacing.sm : Spacing.md) {
                        // Status label
                        Text(viewModel.overlapLabel)
                            .font(Typography.title3)
                            .foregroundStyle(.secondary)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.overlapLabel)
                        
                        // Slider
                        IOSSlider(value: $viewModel.overlapValue)
                            .padding(.horizontal, Spacing.lg)
                        
                        // Labels under slider
                        HStack {
                            Text("Distant")
                                .font(Typography.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text("Merged")
                                .font(Typography.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, Spacing.lg)
                        
                        // Measurement counter
                        if viewModel.measurementCount > 0 {
                            Text("\(viewModel.measurementCount) measurement\(viewModel.measurementCount > 1 ? "s" : "") saved")
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.selfCircleCore)
                        }
                        
                        // Action buttons
                        HStack(spacing: Spacing.sm) {
                            // Save button
                            Button {
                                viewModel.saveMeasurement()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save")
                                }
                                .font(Typography.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(ColorPalette.primaryButtonGradient)
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                            }
                            .accessibilityLabel("Save measurement")
                            .accessibilityHint("Saves the current position as a measurement")
                            
                            // Exit button
                            Button {
                                viewModel.requestExit()
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Exit")
                                }
                                .font(Typography.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                            }
                            .accessibilityLabel("Exit session")
                            .accessibilityHint("Shows options to save and exit or discard session")
                        }
                        .padding(.horizontal, Spacing.lg)
                        }
                        .padding(.bottom, Spacing.xl)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                
                // Save confirmation overlay
                if viewModel.showSaveConfirmation {
                    saveConfirmationOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .gradientBackground()
        .navigationTitle("Basic IOS")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.measurementCount > 0 {
                    Text("\(viewModel.measurementCount)")
                        .font(Typography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(ColorPalette.selfCircleCore)
                        .clipShape(Capsule())
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.requestExit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showExitSheet) {
            ExitSessionSheet { action in
                viewModel.handleExitAction(action)
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
        .interactiveDismissDisabled(true)
        .animation(.spring(response: 0.3), value: viewModel.showSaveConfirmation)
    }
    
    // MARK: - Save Confirmation Overlay
    
    private var saveConfirmationOverlay: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(ColorPalette.success)
            
            Text("Saved!")
                .font(Typography.headline)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BasicIOSView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
