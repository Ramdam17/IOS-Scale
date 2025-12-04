//
//  OverlapView.swift
//  IoS Scale
//
//  Overlap measurement view - focuses on the degree of intersection between Self and Other.
//  Question: "How much do we share?"
//

import SwiftUI
import SwiftData

/// Main view for Overlap modality measurement
struct OverlapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = OverlapViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Question header
                    VStack(spacing: Spacing.xs) {
                        Text("How much do we share?")
                            .font(Typography.title3)
                            .fontWeight(.medium)
                        
                        Text("Drag vertically to adjust overlap")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, Spacing.md)
                    
                    // Interactive circles with overlap highlight
                    OverlapCirclesView(
                        overlapValue: $viewModel.overlapValue,
                        onDraggingChanged: { isDragging in
                            viewModel.isDragging = isDragging
                        }
                    )
                    .frame(height: geometry.size.height * 0.45)
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: Spacing.md) {
                        // Status display
                        VStack(spacing: Spacing.xs) {
                            // Overlap percentage
                            Text(viewModel.overlapPercentage)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "FFD700"),
                                            Color(hex: "FFA500")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3), value: viewModel.overlapValue)
                            
                            // Overlap label
                            Text(viewModel.overlapLabel)
                                .font(Typography.body)
                                .foregroundStyle(.secondary)
                                .animation(.easeInOut(duration: 0.2), value: viewModel.overlapLabel)
                        }
                        
                        // Slider
                        IOSSlider(value: $viewModel.overlapValue)
                            .padding(.horizontal, Spacing.lg)
                        
                        // Labels under slider
                        HStack {
                            Text("No Overlap")
                                .font(Typography.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text("Complete")
                                .font(Typography.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, Spacing.lg)
                        
                        // Measurement counter
                        if viewModel.measurementCount > 0 {
                            Text("\(viewModel.measurementCount) measurement\(viewModel.measurementCount > 1 ? "s" : "") saved")
                                .font(Typography.caption)
                                .foregroundStyle(Color(hex: "FFD700"))
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
                            .accessibilityHint("Saves the current overlap as a measurement")
                            
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
                
                // Save confirmation overlay
                if viewModel.showSaveConfirmation {
                    saveConfirmationOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .gradientBackground()
        .navigationTitle("Overlap")
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
                        .background(Color(hex: "FFD700"))
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
            
            Text("\(viewModel.overlapPercentage) overlap")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Overlap View") {
    NavigationStack {
        OverlapView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}

#Preview("Overlap View - Dark") {
    NavigationStack {
        OverlapView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
