//
//  HomeView.swift
//  IoS Scale
//
//  Main home screen with modality selection.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: gridColumns,
                    spacing: Spacing.md
                ) {
                    ForEach(ModalityType.allCases) { modality in
                        ModalityCardView(modality: modality)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("IOS Scale")
            .gradientBackground()
        }
    }
    
    private var gridColumns: [GridItem] {
        let minWidth: CGFloat = horizontalSizeClass == .regular ? 350 : 300
        return [GridItem(.adaptive(minimum: minWidth, maximum: 450), spacing: Spacing.md)]
    }
}

// MARK: - Modality Card View

struct ModalityCardView: View {
    let modality: ModalityType
    @State private var isExpanded = false
    
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
                    
                    // Expand chevron
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
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
                    
                    // Placeholder for animated preview
                    RoundedRectangle(cornerRadius: LayoutConstants.smallCornerRadius)
                        .fill(modality.tintColor.opacity(0.1))
                        .frame(height: 100)
                        .overlay {
                            Text("Preview")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    
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
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
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
