//
//  SetMembershipView.swift
//  IoS Scale
//
//  Set Membership measurement view - measures whether Self and Other belong to a shared group.
//  Question: "Do we belong to the same set?"
//

import SwiftUI
import SwiftData

/// Main view for Set Membership modality measurement
struct SetMembershipView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = SetMembershipViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let circlesHeight = isLandscape ? geometry.size.height * 0.55 : geometry.size.height * 0.45
            
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isLandscape ? Spacing.xs : 0) {
                        // Question header
                        VStack(spacing: Spacing.xs) {
                            Text("Do we belong to the same set?")
                                .font(Typography.title3)
                                .fontWeight(.medium)
                            
                            Text("Drag circles into or out of the set")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, Spacing.md)
                        
                        // Interactive circles with set
                        SetMembershipCirclesView(
                            selfInSet: $viewModel.selfInSet,
                            otherInSet: $viewModel.otherInSet,
                            onDraggingChanged: { isDragging in
                                viewModel.isDragging = isDragging
                            }
                        )
                        .frame(height: circlesHeight)
                        
                        // Bottom controls
                        VStack(spacing: isLandscape ? Spacing.sm : Spacing.md) {
                            // Status display
                            VStack(spacing: Spacing.xs) {
                                // Membership state
                                Text(viewModel.membershipLabel)
                                    .font(.system(size: isLandscape ? 22 : 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(membershipGradient)
                                    .contentTransition(.interpolate)
                                    .animation(.spring(response: 0.3), value: viewModel.membershipLabel)
                                
                                // Description
                                Text(viewModel.membershipDescription)
                                    .font(Typography.body)
                                    .foregroundStyle(.secondary)
                                    .animation(.easeInOut(duration: 0.2), value: viewModel.membershipDescription)
                            }
                            
                            // Visual membership indicator
                            membershipIndicator
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
        .navigationTitle("Set Membership")
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
    
    // MARK: - Membership Gradient
    
    private var membershipGradient: some ShapeStyle {
        if viewModel.selfInSet && viewModel.otherInSet {
            return LinearGradient(
                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if !viewModel.selfInSet && !viewModel.otherInSet {
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    // MARK: - Membership Indicator
    
    private var membershipIndicator: some View {
        HStack(spacing: Spacing.md) {
            // Self indicator - TAPPABLE
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    viewModel.selfInSet.toggle()
                }
                HapticManager.shared.mediumImpact()
            } label: {
                VStack(spacing: Spacing.xxs) {
                    Circle()
                        .fill(ColorPalette.selfCircleGradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: viewModel.selfInSet ? "checkmark" : "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: viewModel.selfInSet ? ColorPalette.selfCircleCore.opacity(0.5) : Color.clear, radius: 6)
                    Text("Self")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle Self")
            .accessibilityValue(viewModel.selfInSet ? "In set" : "Out of set")
            .accessibilityHint("Tap to move Self circle")
            
            // Connection indicator
            Rectangle()
                .fill(
                    viewModel.selfInSet && viewModel.otherInSet
                        ? LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 3)
                .frame(maxWidth: 80)
            
            // Other indicator - TAPPABLE
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    viewModel.otherInSet.toggle()
                }
                HapticManager.shared.mediumImpact()
            } label: {
                VStack(spacing: Spacing.xxs) {
                    Circle()
                        .fill(ColorPalette.otherCircleGradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: viewModel.otherInSet ? "checkmark" : "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: viewModel.otherInSet ? ColorPalette.otherCircleCore.opacity(0.5) : Color.clear, radius: 6)
                    Text("Other")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle Other")
            .accessibilityValue(viewModel.otherInSet ? "In set" : "Out of set")
            .accessibilityHint("Tap to move Other circle")
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.smallCornerRadius))
    }
    
    // MARK: - Save Confirmation Overlay
    
    private var saveConfirmationOverlay: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(ColorPalette.success)
            
            Text("Saved!")
                .font(Typography.headline)
            
            Text(viewModel.membershipLabel)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius))
    }
}

// MARK: - Preview

#Preview("Set Membership View") {
    NavigationStack {
        SetMembershipView()
    }
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}

#Preview("Set Membership View - Dark") {
    NavigationStack {
        SetMembershipView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [SessionModel.self, MeasurementModel.self], inMemory: true)
}
