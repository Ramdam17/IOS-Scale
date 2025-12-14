//
//  AdvancedIOSView.swift
//  IoS Scale
//
//  Main view for Advanced IOS measurement mode with scalable circles.
//

import SwiftUI
import SwiftData

/// Advanced IOS measurement view with adjustable circle sizes
struct AdvancedIOSView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = AdvancedIOSViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isPad = horizontalSizeClass == .regular
            let circlesHeight = isLandscape ? geometry.size.height * 0.50 : geometry.size.height * 0.45
            
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isLandscape ? Spacing.xs : 0) {
                        // iPad top spacing for vertical centering
                        if isPad {
                            Spacer(minLength: geometry.size.height * 0.05)
                        }
                        
                        // Question header
                        VStack(spacing: Spacing.xs) {
                            Text("How do you perceive your relationship?")
                                .font(Typography.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                            
                            Text("Adjust overlap and circle sizes")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, Spacing.md)
                        .padding(.horizontal, Spacing.md)
                        
                        // Circles area
                        InteractiveCirclesView(
                            overlapValue: $viewModel.overlapValue,
                            selfScale: $viewModel.selfScale,
                            otherScale: $viewModel.otherScale,
                            scalingEnabled: true,
                            onDraggingChanged: { isDragging in
                                viewModel.isDragging = isDragging
                            }
                        )
                        .frame(height: circlesHeight)
                        
                        // Bottom controls
                        VStack(spacing: isLandscape ? Spacing.xs : Spacing.sm) {
                            // Status labels
                            VStack(spacing: Spacing.xxs) {
                                Text(viewModel.overlapLabel)
                                    .font(Typography.title3)
                                    .foregroundStyle(.secondary)
                                
                                Text(viewModel.scaleRatioText)
                                    .font(Typography.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .animation(.easeInOut(duration: 0.2), value: viewModel.overlapLabel)
                            
                            // Overlap slider
                            VStack(spacing: Spacing.xs) {
                                IOSSlider(value: $viewModel.overlapValue)
                                
                                HStack {
                                    Text("Distant")
                                        .font(Typography.caption)
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                    Text("Merged")
                                        .font(Typography.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                            
                            // Scale sliders
                            VStack(spacing: Spacing.xs) {
                                // Self scale
                                HStack(spacing: Spacing.sm) {
                                    Text("Self")
                                        .font(Typography.caption)
                                        .foregroundStyle(ColorPalette.selfCircleCore)
                                        .frame(width: 50, alignment: .leading)
                                    
                                    IOSSlider(
                                        value: $viewModel.selfScale,
                                        range: LayoutConstants.minCircleScale...LayoutConstants.maxCircleScale
                                    )
                                    
                                    Text("\(viewModel.selfScale, specifier: "%.1f")×")
                                        .font(Typography.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                                
                                // Other scale
                                HStack(spacing: Spacing.sm) {
                                    Text("Other")
                                        .font(Typography.caption)
                                        .foregroundStyle(ColorPalette.otherCircleCore)
                                        .frame(width: 50, alignment: .leading)
                                    
                                    IOSSlider(
                                        value: $viewModel.otherScale,
                                        range: LayoutConstants.minCircleScale...LayoutConstants.maxCircleScale
                                    )
                                    
                                    Text("\(viewModel.otherScale, specifier: "%.1f")×")
                                        .font(Typography.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                            }
                            .padding(.horizontal, Spacing.lg)
                        
                        // Measurement counter
                        if viewModel.measurementCount > 0 {
                            Text("\(viewModel.measurementCount) measurement\(viewModel.measurementCount > 1 ? "s" : "") saved")
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.selfCircleCore)
                        }
                        
                        // Save button (primary)
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
                        .padding(.horizontal, Spacing.lg)
                        
                        // Action buttons row
                        HStack(spacing: Spacing.sm) {
                            // Reset button
                            Button {
                                viewModel.resetToInitial()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .font(Typography.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.smallCornerRadius))
                            }
                            
                            // Exit button
                            Button {
                                viewModel.requestExit()
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Exit")
                                }
                                .font(Typography.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.smallCornerRadius))
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.bottom, Spacing.xl)
                } // End VStack
                .frame(minHeight: geometry.size.height)
                } // End ScrollView
                
                // Save confirmation overlay
                if viewModel.showSaveConfirmation {
                    saveConfirmationOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .gradientBackground()
        .navigationTitle("Advanced IOS")
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
        AdvancedIOSView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
