//
//  AttributionView.swift
//  IoS Scale
//
//  Attribution measurement view - Perceived similarity between Self and Other.
//  Question: "How similar do I perceive myself to be with the other?"
//

import SwiftUI
import SwiftData

/// Main view for Attribution modality measurement
struct AttributionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @StateObject private var viewModel = AttributionViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isPad = horizontalSizeClass == .regular
            let circlesHeight = isLandscape ? geometry.size.height * 0.50 : geometry.size.height * 0.40
            
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isLandscape ? Spacing.xs : 0) {
                        // iPad top spacing for vertical centering
                        if isPad {
                            Spacer(minLength: geometry.size.height * 0.05)
                        }
                        
                        // Question header
                        VStack(spacing: Spacing.xs) {
                            Text("How similar do I perceive myself to the other?")
                                .font(Typography.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                            
                            Text("Drag circles or use the slider")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, Spacing.md)
                        .padding(.horizontal, Spacing.md)
                        
                        // Similarity indicator icons
                        HStack(spacing: Spacing.lg) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "person.slash")
                                    .font(.caption)
                                Text("Different")
                                    .font(Typography.caption2)
                            }
                            .foregroundStyle(.secondary)
                            
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            
                            HStack(spacing: Spacing.xs) {
                                Text("Similar")
                                    .font(Typography.caption2)
                                Image(systemName: "person.2")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.top, Spacing.xs)
                        
                        // Interactive circles
                        AttributionCirclesView(
                            similarityValue: $viewModel.similarityValue,
                            onDraggingChanged: { isDragging in
                                viewModel.isDragging = isDragging
                            }
                        )
                        .frame(height: circlesHeight)
                        
                        // Bottom controls
                        VStack(spacing: isLandscape ? Spacing.sm : Spacing.md) {
                            // Status display
                            VStack(spacing: Spacing.xs) {
                                // Similarity label
                                Text(viewModel.similarityLabel)
                                    .font(.system(size: isLandscape ? 22 : 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(similarityGradient)
                                    .contentTransition(.interpolate)
                                    .animation(.spring(response: 0.3), value: viewModel.similarityLabel)
                                
                                // Description
                                Text(viewModel.similarityDescription)
                                    .font(Typography.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .animation(.easeInOut(duration: 0.2), value: viewModel.similarityDescription)
                            }
                            
                            // Slider control
                            similaritySlider
                                .padding(.horizontal, Spacing.lg)
                            
                            // Measurement counter
                            if viewModel.measurementCount > 0 {
                                Text("\(viewModel.measurementCount) measurement\(viewModel.measurementCount > 1 ? "s" : "") saved")
                                    .font(Typography.caption)
                                    .foregroundStyle(Color(hex: "FAB1A0"))
                            }
                            
                            // Action buttons
                            VStack(spacing: Spacing.sm) {
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
                                
                                // Reset and Exit row
                                HStack(spacing: Spacing.sm) {
                                    // Reset button
                                    Button {
                                        viewModel.resetToInitial()
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.counterclockwise")
                                            Text("Reset")
                                        }
                                        .font(Typography.headline)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm)
                                        .background(.ultraThinMaterial)
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
        .navigationTitle("Attribution")
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
                        .background(Color(hex: "FAB1A0"))
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
    
    // MARK: - Similarity Gradient
    
    private var similarityGradient: some ShapeStyle {
        if viewModel.similarityValue >= 0.85 {
            return LinearGradient(
                colors: [Color.green, Color(hex: "00B894")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if viewModel.similarityValue >= 0.5 {
            return LinearGradient(
                colors: [Color.yellow, Color.orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.red.opacity(0.8), Color.orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // MARK: - Similarity Slider
    
    private var similaritySlider: some View {
        VStack(spacing: Spacing.xs) {
            Slider(value: $viewModel.similarityValue, in: 0...1)
                .tint(sliderTintColor)
            
            // Labels
            HStack {
                Text("Different")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.similarityValue * 100))%")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.similarityValue >= 0.85 ? Color.green : .primary)
                
                Spacer()
                
                Text("Similar")
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
        if viewModel.similarityValue >= 0.85 {
            return Color.green
        } else if viewModel.similarityValue >= 0.5 {
            return Color.yellow
        } else {
            return Color.red.opacity(0.7)
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
            
            Text(viewModel.similarityLabel)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Attribution View") {
    NavigationStack {
        AttributionView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}

#Preview("Attribution View - Dark") {
    NavigationStack {
        AttributionView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
