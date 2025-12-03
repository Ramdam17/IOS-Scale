//
//  ExitSessionSheet.swift
//  IoS Scale
//
//  Modal sheet for exiting a measurement session with save options.
//

import SwiftUI

/// Actions available when exiting a session
enum ExitSessionAction: Identifiable {
    case saveAndExit
    case exitWithoutSaving
    case cancel
    
    var id: String {
        switch self {
        case .saveAndExit: return "save"
        case .exitWithoutSaving: return "exit"
        case .cancel: return "cancel"
        }
    }
}

/// Modal sheet presented when user wants to exit a measurement session
struct ExitSessionSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// Callback with the chosen action
    let onAction: (ExitSessionAction) -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            VStack(spacing: Spacing.xs) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 40))
                    .foregroundStyle(ColorPalette.primaryButtonGradient)
                
                Text("Exit Session?")
                    .font(Typography.title2)
                
                Text("Choose what to do with your current measurement.")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.lg)
            
            Spacer()
            
            // Actions
            VStack(spacing: Spacing.sm) {
                // Save & Exit
                Button {
                    HapticManager.shared.success()
                    onAction(.saveAndExit)
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save & Exit")
                    }
                    .font(Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(ColorPalette.primaryButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                }
                
                // Exit without saving
                Button {
                    HapticManager.shared.warning()
                    onAction(.exitWithoutSaving)
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Exit Without Saving")
                    }
                    .font(Typography.headline)
                    .foregroundStyle(destructiveColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(destructiveColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                }
                
                // Cancel
                Button {
                    HapticManager.shared.selection()
                    onAction(.cancel)
                } label: {
                    Text("Cancel")
                        .font(Typography.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
            }
            .padding(.bottom, Spacing.lg)
        }
        .padding(.horizontal, Spacing.lg)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(LayoutConstants.cardCornerRadius)
    }
    
    private var destructiveColor: Color {
        colorScheme == .dark ? ColorPalette.destructiveDark : ColorPalette.destructive
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ExitSessionSheet { action in
                print("Action: \(action)")
            }
        }
}

#Preview("Dark Mode") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ExitSessionSheet { action in
                print("Action: \(action)")
            }
        }
        .preferredColorScheme(.dark)
}
