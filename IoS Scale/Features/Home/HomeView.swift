//
//  HomeView.swift
//  IoS Scale
//
//  Main home screen with modality selection.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(CloudSyncService.self) private var syncService
    @State private var cardsAppeared = false
    @State private var showingHistory = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVGrid(
                        columns: gridColumns,
                        spacing: Spacing.md
                    ) {
                        ForEach(Array(ModalityType.allCases.enumerated()), id: \.element) { index, modality in
                            ModalityCardView(modality: modality)
                                .opacity(cardsAppeared ? 1 : 0)
                                .offset(y: cardsAppeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.05),
                                    value: cardsAppeared
                                )
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.lg)
                    .padding(.bottom, Spacing.xxl) // Space for floating button
                }
                .navigationTitle("IOS Scale")
                .toolbar {
                    // Sync status indicator
                    ToolbarItem(placement: .topBarLeading) {
                        if syncService.iCloudSyncEnabled {
                            Button {
                                Task {
                                    await syncService.sync()
                                }
                            } label: {
                                Image(systemName: syncService.status.icon)
                                    .foregroundStyle(syncService.status.color)
                                    .symbolEffect(.pulse, isActive: syncService.isSyncing)
                            }
                            .disabled(syncService.isSyncing)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingSettings = true
                            HapticManager.shared.lightImpact()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .gradientBackground()
                
                // Floating stats button
                floatingStatsButton
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            // Trigger staggered card animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cardsAppeared = true
            }
        }
    }
    
    // MARK: - Grid Columns
    
    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            // iPad: 2-column layout
            return [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ]
        } else {
            // iPhone: single column
            return [GridItem(.flexible())]
        }
    }
    
    // MARK: - Floating Stats Button
    
    private var floatingStatsButton: some View {
        Button {
            showingHistory = true
            HapticManager.shared.lightImpact()
        } label: {
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(ColorPalette.primaryButtonGradient)
                .clipShape(Circle())
                .shadow(color: ColorPalette.selfCircleCore.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.trailing, Spacing.lg)
        .padding(.bottom, Spacing.lg)
        .opacity(cardsAppeared ? 1 : 0)
        .scaleEffect(cardsAppeared ? 1 : 0.5)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: cardsAppeared)
    }
}

// MARK: - Modality Card View

struct ModalityCardView: View {
    let modality: ModalityType
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isExpanded = false
    
    /// Cards are expanded by default on iPad
    private var defaultExpanded: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        LiquidGlassCard(tintColor: modality.tintColor, isExpanded: isExpanded) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header
                HStack(spacing: Spacing.sm) {
                    // Icon
                    Image(systemName: modality.iconName)
                        .font(.title2)
                        .foregroundStyle(modality.tintColor)
                        .frame(width: LayoutConstants.cardIconSize, height: LayoutConstants.cardIconSize)
                        .background(modality.tintColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.smallCornerRadius))
                    
                    // Title and status
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(modality.displayName)
                            .font(Typography.headline)
                        
                        if !modality.isAvailable {
                            Text("Coming Soon")
                                .font(Typography.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand chevron (only show on iPhone where cards are collapsed by default)
                    if !defaultExpanded {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                
                // Description (always visible)
                Text(modality.description)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
                
                // Expanded content
                if isExpanded {
                    Divider()
                        .padding(.vertical, Spacing.xs)
                    
                    // Animated preview
                    ModalityPreviewView(modality: modality)
                        .frame(height: PreviewConstants.previewHeight)
                        .background(modality.tintColor.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.smallCornerRadius))
                    
                    // Start button
                    if modality.isAvailable {
                        NavigationLink {
                            destinationView(for: modality)
                        } label: {
                            Text("Start Session")
                                .font(Typography.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(ColorPalette.primaryButtonGradient)
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                        }
                    }
                }
            }
        }
        .opacity(modality.isAvailable ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(modality.displayName)\(modality.isAvailable ? "" : ", coming soon")")
        .accessibilityHint(modality.isAvailable ? "Double tap to \(isExpanded ? "collapse" : "expand"), then tap Start Session to begin" : "This modality is not yet available")
        .accessibilityAddTraits(modality.isAvailable ? .isButton : [])
        .onTapGesture {
            // Only allow collapsing on iPad, always toggle on iPhone
            if !defaultExpanded || isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
        }
        .onAppear {
            // Set initial expanded state based on device
            if defaultExpanded {
                isExpanded = true
            }
        }
    }
    
    /// Returns the appropriate measurement view for the modality
    @ViewBuilder
    private func destinationView(for modality: ModalityType) -> some View {
        switch modality {
        case .basicIOS:
            BasicIOSView()
        case .advancedIOS:
            AdvancedIOSView()
        case .overlap:
            OverlapView()
        default:
            // Placeholder for future modalities
            Text("Coming Soon: \(modality.displayName)")
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(ThemeManager())
}
