//
//  ObservationView.swift
//  IoS Scale
//
//  Observation measurement view - Observer vs Participant perspective.
//  Question: "Am I observing from outside or participating from inside?"
//

import SwiftUI
import SwiftData

/// Main view for Observation modality measurement
struct ObservationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ObservationViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Question header
                    VStack(spacing: Spacing.xs) {
                        Text("Am I observing or participating?")
                            .font(Typography.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                        
                        Text("Drag right to participate, left to observe")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.md)
                    
                    // Mode indicator icons
                    HStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "eye")
                                .font(.caption)
                            Text("Observer")
                                .font(Typography.caption2)
                        }
                        .foregroundStyle(.secondary)
                        
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        
                        HStack(spacing: Spacing.xs) {
                            Text("Participant")
                                .font(Typography.caption2)
                            Image(systemName: "figure.walk")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, Spacing.xs)
                    
                    // Interactive circles
                    ObservationCirclesView(
                        participationValue: $viewModel.participationValue,
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
                            // Observation label
                            Text(viewModel.observationLabel)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(observationGradient)
                                .contentTransition(.interpolate)
                                .animation(.spring(response: 0.3), value: viewModel.observationLabel)
                            
                            // Description
                            Text(viewModel.observationDescription)
                                .font(Typography.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .animation(.easeInOut(duration: 0.2), value: viewModel.observationDescription)
                        }
                        
                        // Slider control
                        observationSlider
                            .padding(.horizontal, Spacing.lg)
                        
                        // Measurement counter
                        if viewModel.measurementCount > 0 {
                            Text("\(viewModel.measurementCount) measurement\(viewModel.measurementCount > 1 ? "s" : "") saved")
                                .font(Typography.caption)
                                .foregroundStyle(Color(hex: "81ECEC"))
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
                                .padding(.vertical, Spacing.sm)
                                .background(ColorPalette.primaryButtonGradient)
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                            }
                            
                            // Exit button
                            Button {
                                viewModel.requestExit()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Exit")
                                }
                                .font(Typography.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                            }
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
        .navigationTitle("Observation")
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
                        .background(Color(hex: "81ECEC"))
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
    
    // MARK: - Observation Gradient
    
    private var observationGradient: some ShapeStyle {
        if viewModel.participationValue >= 0.85 {
            return LinearGradient(
                colors: [Color(hex: "81ECEC"), Color(hex: "74B9FF")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if viewModel.participationValue >= 0.5 {
            return LinearGradient(
                colors: [Color(hex: "74B9FF"), Color(hex: "A29BFE")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // MARK: - Observation Slider
    
    private var observationSlider: some View {
        VStack(spacing: Spacing.xs) {
            Slider(value: $viewModel.participationValue, in: 0...1)
                .tint(sliderTintColor)
            
            // Labels
            HStack {
                Text("Observer")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.participationValue * 100))%")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.participationValue >= 0.85 ? Color(hex: "81ECEC") : .primary)
                
                Spacer()
                
                Text("Participant")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.smallCornerRadius))
    }
    
    private var sliderTintColor: Color {
        if viewModel.participationValue >= 0.85 {
            return Color(hex: "81ECEC")
        } else if viewModel.participationValue >= 0.5 {
            return Color(hex: "74B9FF")
        } else {
            return Color.gray
        }
    }
    
    // MARK: - Save Confirmation Overlay
    
    private var saveConfirmationOverlay: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(ColorPalette.success)
            
            Text("Saved!")
                .font(Typography.headline)
            
            Text(viewModel.observationLabel)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Observation View") {
    NavigationStack {
        ObservationView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}

#Preview("Observation View - Dark") {
    NavigationStack {
        ObservationView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
