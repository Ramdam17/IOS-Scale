//
//  ProjectionView.swift
//  IoS Scale
//
//  Projection measurement view - Self projects qualities onto Other.
//  Question: "To what extent do I project myself onto the other?"
//

import SwiftUI
import SwiftData

/// Main view for Projection modality measurement
struct ProjectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ProjectionViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Question header
                    VStack(spacing: Spacing.xs) {
                        Text("To what extent do I project myself onto the other?")
                            .font(Typography.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                        
                        Text("Drag right to increase projection")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.md)
                    
                    // Direction indicator
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text("Self → Other")
                            .font(Typography.caption2)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.xs)
                    
                    // Interactive circles
                    ProjectionCirclesView(
                        projectionValue: $viewModel.projectionValue,
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
                            // Projection label
                            Text(viewModel.projectionLabel)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(projectionGradient)
                                .contentTransition(.interpolate)
                                .animation(.spring(response: 0.3), value: viewModel.projectionLabel)
                            
                            // Description
                            Text(viewModel.projectionDescription)
                                .font(Typography.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .animation(.easeInOut(duration: 0.2), value: viewModel.projectionDescription)
                        }
                        
                        // Slider control
                        projectionSlider
                            .padding(.horizontal, Spacing.lg)
                        
                        // Measurement counter
                        if viewModel.measurementCount > 0 {
                            Text("\(viewModel.measurementCount) measurement\(viewModel.measurementCount > 1 ? "s" : "") saved")
                                .font(Typography.caption)
                                .foregroundStyle(Color(hex: "00CED1"))
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
        .navigationTitle("Projection")
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
                        .background(Color(hex: "00CED1"))
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
    
    // MARK: - Projection Gradient
    
    private var projectionGradient: some ShapeStyle {
        if viewModel.projectionValue >= 0.95 {
            return LinearGradient(
                colors: [Color(hex: "00CED1"), Color(hex: "40E0D0")], // Cyan/Turquoise
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if viewModel.projectionValue >= 0.5 {
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
    
    // MARK: - Projection Slider
    
    private var projectionSlider: some View {
        VStack(spacing: Spacing.xs) {
            Slider(value: $viewModel.projectionValue, in: 0...1)
                .tint(sliderTintColor)
            
            // Labels
            HStack {
                Text("Separate")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.projectionValue * 100))%")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.projectionValue >= 0.95 ? Color(hex: "00CED1") : .primary)
                
                Spacer()
                
                Text("Projected")
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
        if viewModel.projectionValue >= 0.95 {
            return Color(hex: "00CED1")
        } else if viewModel.projectionValue >= 0.5 {
            return Color.cyan
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
            
            Text(viewModel.projectionLabel)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Projection View") {
    NavigationStack {
        ProjectionView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}

#Preview("Projection View - Dark") {
    NavigationStack {
        ProjectionView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
