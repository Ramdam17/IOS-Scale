//
//  ProximityView.swift
//  IoS Scale
//
//  Proximity measurement view - measures pure distance without overlap.
//  Question: "How close do I feel to the other?"
//

import SwiftUI
import SwiftData

/// Main view for Proximity modality measurement
struct ProximityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ProximityViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let circlesHeight = isLandscape ? geometry.size.height * 0.50 : geometry.size.height * 0.40
            
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isLandscape ? Spacing.xs : 0) {
                        // Question header
                        VStack(spacing: Spacing.xs) {
                            Text("How close do I feel to the other?")
                                .font(Typography.title3)
                                .fontWeight(.medium)
                            
                            Text("Drag circles closer or further apart")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, Spacing.md)
                        
                        // Interactive circles with connecting line
                        ProximityCirclesView(
                            proximityValue: $viewModel.proximityValue,
                            onDraggingChanged: { isDragging in
                                viewModel.isDragging = isDragging
                            }
                        )
                        .frame(height: circlesHeight)
                        
                        // Bottom controls
                        VStack(spacing: isLandscape ? Spacing.sm : Spacing.md) {
                            // Status display
                            VStack(spacing: Spacing.xs) {
                                // Proximity label
                                Text(viewModel.proximityLabel)
                                    .font(.system(size: isLandscape ? 22 : 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(proximityGradient)
                                    .contentTransition(.interpolate)
                                    .animation(.spring(response: 0.3), value: viewModel.proximityLabel)
                                
                                // Description
                                Text(viewModel.proximityDescription)
                                    .font(Typography.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .animation(.easeInOut(duration: 0.2), value: viewModel.proximityDescription)
                            }
                            
                            // Visual proximity slider (read-only visual feedback)
                            proximityIndicator
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
        .navigationTitle("Proximity")
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
    
    // MARK: - Proximity Gradient
    
    private var proximityGradient: some ShapeStyle {
        if viewModel.proximityValue >= 0.95 {
            return LinearGradient(
                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if viewModel.proximityValue >= 0.5 {
            return LinearGradient(
                colors: [Color.purple, Color.blue],
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
    
    // MARK: - Proximity Indicator
    
    private var proximityIndicator: some View {
        VStack(spacing: Spacing.xs) {
            // Interactive slider
            Slider(value: $viewModel.proximityValue, in: 0...1)
                .tint(sliderTintColor)
                .onChange(of: viewModel.proximityValue) { oldValue, newValue in
                    // Haptic feedback at key thresholds
                    let thresholds: [Double] = [0.25, 0.5, 0.75, 0.95]
                    for threshold in thresholds {
                        if (oldValue < threshold && newValue >= threshold) ||
                           (oldValue > threshold && newValue <= threshold) {
                            HapticManager.shared.lightImpact()
                            break
                        }
                    }
                    // Special haptic when touching
                    if newValue >= 0.98 && oldValue < 0.98 {
                        HapticManager.shared.success()
                    }
                }
            
            // Labels
            HStack {
                Text("Far")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.proximityValue * 100))%")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.proximityValue >= 0.95 ? Color(hex: "FFD700") : .primary)
                
                Spacer()
                
                Text("Close")
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
        if viewModel.proximityValue >= 0.95 {
            return Color(hex: "FFD700")
        } else if viewModel.proximityValue >= 0.5 {
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
            
            Text(viewModel.proximityLabel)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Proximity View") {
    NavigationStack {
        ProximityView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}

#Preview("Proximity View - Dark") {
    NavigationStack {
        ProximityView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
