//
//  IdentificationView.swift
//  IoS Scale
//
//  Identification measurement view - Self absorbs qualities of Other.
//  Question: "To what extent do I identify with the other?"
//

import SwiftUI
import SwiftData

/// Main view for Identification modality measurement
struct IdentificationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = IdentificationViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Question header
                    VStack(spacing: Spacing.xs) {
                        Text("To what extent do I identify with the other?")
                            .font(Typography.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                        
                        Text("Drag left to increase identification")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.md)
                    
                    // Direction indicator
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.left")
                            .font(.caption)
                        Text("Other → Self")
                            .font(Typography.caption2)
                        Image(systemName: "person.fill.checkmark")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.xs)
                    
                    // Interactive circles
                    IdentificationCirclesView(
                        identificationValue: $viewModel.identificationValue,
                        onDraggingChanged: { isDragging in
                            viewModel.isDragging = isDragging
                        }
                    )
                    .frame(height: geometry.size.height * 0.38)
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: Spacing.md) {
                        // Status display
                        VStack(spacing: Spacing.xs) {
                            // Identification label
                            Text(viewModel.identificationLabel)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(identificationGradient)
                                .contentTransition(.interpolate)
                                .animation(.spring(response: 0.3), value: viewModel.identificationLabel)
                            
                            // Description
                            Text(viewModel.identificationDescription)
                                .font(Typography.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .animation(.easeInOut(duration: 0.2), value: viewModel.identificationDescription)
                        }
                        
                        // Slider control
                        identificationSlider
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
        .navigationTitle("Identification")
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
    
    // MARK: - Identification Gradient
    
    private var identificationGradient: some ShapeStyle {
        if viewModel.identificationValue >= 0.95 {
            return LinearGradient(
                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if viewModel.identificationValue >= 0.5 {
            return LinearGradient(
                colors: [ColorPalette.selfCircleCore, ColorPalette.otherCircleCore],
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
    
    // MARK: - Identification Slider
    
    private var identificationSlider: some View {
        VStack(spacing: Spacing.xs) {
            Slider(value: $viewModel.identificationValue, in: 0...1)
                .tint(sliderTintColor)
            
            // Labels
            HStack {
                Text("Separate")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.identificationValue * 100))%")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.identificationValue >= 0.95 ? Color(hex: "FFD700") : .primary)
                
                Spacer()
                
                Text("Identified")
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
        if viewModel.identificationValue >= 0.95 {
            return Color(hex: "FFD700")
        } else if viewModel.identificationValue >= 0.5 {
            return Color.purple
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
            
            Text(viewModel.identificationLabel)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Identification View") {
    NavigationStack {
        IdentificationView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}

#Preview("Identification View - Dark") {
    NavigationStack {
        IdentificationView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
